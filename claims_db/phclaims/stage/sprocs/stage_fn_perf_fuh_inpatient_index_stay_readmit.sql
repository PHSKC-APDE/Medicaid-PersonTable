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
Last Modified: 2019-04-25

Returns:
 [id]
,[tcn]
,[from_date]
,[to_date]
,[flag], = 1
*/

USE PHClaims;
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
FROM [ref].[hedis_code_system]
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
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
,1 AS [flag]

FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_line] AS ln
ON hd.[tcn] = ln.[tcn]
INNER JOIN [ref].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Inpatient Stay')
AND hed.[code_system] = 'UBREV'
AND ln.[rcode] = hed.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date

INTERSECT

(
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
,1 AS [flag]

FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_line] AS ln
ON hd.[tcn] = ln.[tcn]
INNER JOIN [ref].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Nonacute Inpatient Stay')
AND hed.[code_system] = 'UBREV'
AND ln.[rcode] = hed.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date

UNION

SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
,1 AS [flag]

FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [ref].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Nonacute Inpatient Stay')
AND hed.[code_system] = 'UBTOB' 
AND hd.[bill_type_code] = hed.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date
))

UNION

((
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
,1 AS [flag]

FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_line] AS ln
ON hd.[tcn] = ln.[tcn]
INNER JOIN [ref].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Inpatient Stay')
AND hed.[code_system] = 'UBREV'
AND ln.[rcode] = hed.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date

EXCEPT

(
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
,1 AS [flag]

FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_line] AS ln
ON hd.[tcn] = ln.[tcn]
INNER JOIN [ref].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Nonacute Inpatient Stay')
AND hed.[code_system] = 'UBREV'
AND ln.[rcode] = hed.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date

UNION

SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
,1 AS [flag]

FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [ref].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Nonacute Inpatient Stay')
AND hed.[code_system] = 'UBTOB' 
AND hd.[bill_type_code] = hed.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date
))

EXCEPT

(
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
,1 AS [flag]

FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_dx] AS dx
ON hd.[tcn] = dx.[tcn]
-- Principal Diagnosis
AND dx.[dx_number] = 1
INNER JOIN [ref].[hedis_code_system] AS hed
ON [value_set_name] = @dx_value_set_name
--ON [value_set_name] IN ('Mental Health Diagnosis')
AND hed.[code_system] = 'ICD10CM'
AND dx.[dx_ver] = 10 
AND dx.[dx_norm] = hed.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date
)))

SELECT 
 [id]
,[tcn]
,[from_date]
,[to_date]
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
 a.[id]
,a.[age]
,a.[tcn]
,a.[from_date]
,a.[to_date]
,a.[flag]
,ISNULL(b.[flag], 0) AS [readmit_flag]
FROM #fn_perf_fuh_inpatient_index_stay AS a
LEFT JOIN #fn_perf_fuh_inpatient_index_stay_readmit AS b
ON a.[id] = b.[id]
AND b.[from_date] BETWEEN a.[to_date] AND DATEADD(DAY, 30, a.[to_date]);
*/