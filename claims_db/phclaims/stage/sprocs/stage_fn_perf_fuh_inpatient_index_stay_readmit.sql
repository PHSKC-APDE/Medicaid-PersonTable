
/*
This function gets non-acute inpatient stays as denominator exclusions for the 
FUH (Follow-up After Hospitalization for Mental Illness).

From DSRIP Guide:
(1)
Exclude discharges (acute discharges with principal diagnosis of mental 
illness) followed by readmission or direct transfer to a non-acute inpatient 
care setting within the 30-day follow-up period, regardless of principal 
diagnosis for the readmission.

To identify readmissions and direct transfers to a non-acute inpatient care 
setting:
-Identify all acute and non-acute inpatient stays (Inpatient Stay Value Set).
-Confirm the stay was for non-acute care based on the presence of a non-acute 
code (Non-acute Inpatient Stay Value Set) on the claim.
-Identify the admission date for the stay.

(2)
Exclude discharges followed by readmission or direct transfer to an acute 
inpatient care setting within the 30-day follow-up period if the principal 
diagnosis was for non-mental health (any principal diagnosis code other than 
those included in the Mental Health Diagnosis Value Set). To identify 
readmissions and direct transfers to an acute inpatient care setting:
-Identify all acute and non-acute inpatient stays (Inpatient Stay Value Set).
-Exclude non-acute inpatient stays (Non-acute Inpatient Stay Value Set).
-Identify the admission date for the stay.

LOGIC:
(
Inpatient Stay
INTERSECT
Nonacute Inpatient Stay
)
UNION
((
Inpatient Stay
EXCEPT
Nonacute Inpatient Stay
)
EXCEPT
Mental Health Diagnosis
)

Author: Philip Sylling
Created: 2019-04-25
Modified: 2019-08-09 | Point to new [final] analytic tables

Returns:
 [id_mcaid]
,[age]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
,[flag], = 1
*/

USE [PHClaims];
GO

IF OBJECT_ID('[stage].[fn_perf_fuh_inpatient_index_stay_readmit]', 'IF') IS NOT NULL
DROP FUNCTION [stage].[fn_perf_fuh_inpatient_index_stay_readmit];
GO
CREATE FUNCTION [stage].[fn_perf_fuh_inpatient_index_stay_readmit]
(@measurement_start_date DATE
,@measurement_end_date DATE
,@dx_value_set_name VARCHAR(100))
RETURNS TABLE 
AS
RETURN
/*
SELECT [value_set_name]
      ,[code_system]
      ,COUNT([code])
FROM [archive].[hedis_code_system]
WHERE [value_set_name] IN
('Mental Illness'
,'Inpatient Stay'
,'Nonacute Inpatient Stay')
GROUP BY [value_set_name], [code_system]
ORDER BY [value_set_name], [code_system];
*/

WITH [readmit] AS
((
SELECT 
 ln.[id_mcaid]
,ln.[claim_header_id]
,ln.[first_service_date]
,ln.[last_service_date]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Inpatient Stay')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code]
WHERE ln.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date

INTERSECT

(
SELECT 
 ln.[id_mcaid]
,ln.[claim_header_id]
,ln.[first_service_date]
,ln.[last_service_date]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Nonacute Inpatient Stay')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code]
WHERE ln.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date

UNION

SELECT 
 hd.[id_mcaid]
,hd.[claim_header_id]
,hd.[first_service_date]
,hd.[last_service_date]
,1 AS [flag]

FROM [final].[mcaid_claim_header] AS hd
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Nonacute Inpatient Stay')
AND hed.[code_system] = 'UBTOB' 
AND hd.[type_of_bill_code] = hed.[code]
WHERE hd.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
))

UNION

((
SELECT 
 ln.[id_mcaid]
,ln.[claim_header_id]
,ln.[first_service_date]
,ln.[last_service_date]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Inpatient Stay')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code]
WHERE ln.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date

EXCEPT

(
SELECT 
 ln.[id_mcaid]
,ln.[claim_header_id]
,ln.[first_service_date]
,ln.[last_service_date]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Nonacute Inpatient Stay')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code]
WHERE ln.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date

UNION

SELECT 
 hd.[id_mcaid]
,hd.[claim_header_id]
,hd.[first_service_date]
,hd.[last_service_date]
,1 AS [flag]

FROM [final].[mcaid_claim_header] AS hd
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Nonacute Inpatient Stay')
AND hed.[code_system] = 'UBTOB' 
AND hd.[type_of_bill_code] = hed.[code]
WHERE hd.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
))

EXCEPT

(
SELECT 
 dx.[id_mcaid]
,dx.[claim_header_id]
,dx.[first_service_date]
,dx.[last_service_date]
,1 AS [flag]

FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] = @dx_value_set_name
--ON [value_set_name] IN ('Mental Health Diagnosis')
AND hed.[code_system] = 'ICD10CM'
AND dx.[icdcm_version] = 10
-- Principal Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = hed.[code]
WHERE dx.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
)))

SELECT 
 [id_mcaid]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
,[flag]
FROM [readmit];
GO

/*
IF OBJECT_ID('tempdb..#fn_perf_fuh_inpatient_index_stay', 'U') IS NOT NULL
DROP TABLE #fn_perf_fuh_inpatient_index_stay;
SELECT * 
INTO #fn_perf_fuh_inpatient_index_stay 
FROM [stage].[fn_perf_fuh_inpatient_index_stay]('2017-01-01', '2017-12-31', 6, 'Mental Illness');

IF OBJECT_ID('tempdb..#fn_perf_fuh_inpatient_index_stay_readmit', 'U') IS NOT NULL
DROP TABLE #fn_perf_fuh_inpatient_index_stay_readmit;
SELECT * 
INTO #fn_perf_fuh_inpatient_index_stay_readmit
FROM [stage].[fn_perf_fuh_inpatient_index_stay_readmit]('2017-01-01', '2017-12-31', 'Mental Health Diagnosis');

SELECT DISTINCT
 a.[id_mcaid]
,a.[age]
,a.[claim_header_id]
,a.[first_service_date]
,a.[last_service_date]
,a.[flag]
,ISNULL(b.[flag], 0) AS [readmit_flag]
FROM #fn_perf_fuh_inpatient_index_stay AS a
LEFT JOIN #fn_perf_fuh_inpatient_index_stay_readmit AS b
ON a.[id_mcaid] = b.[id_mcaid]
AND b.[first_service_date] BETWEEN a.[last_service_date] AND DATEADD(DAY, 30, a.[last_service_date]);
*/
