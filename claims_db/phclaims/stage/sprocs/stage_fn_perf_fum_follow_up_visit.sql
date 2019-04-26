/*
This function gets follow-up visits that meet the requirements for the HEDIS FUM measure.
Note, 
FUM (Follow-Up After Emergency Department Visit for Mental Illness) and
FUH (Follow-Up After Hospitalization for Mental Illness)
use the same value sets.

Author: Philip Sylling
Created: 2019-04-24
Last Modified: 2019-04-24

Returns:
 [id]
,[tcn]
,[from_date], [FROM_SRVC_DATE]
,[to_date], [TO_SRVC_DATE]
,[flag], 1 for claim meeting follow-up visit criteria
*/

USE PHClaims;
GO

IF OBJECT_ID('[stage].[fn_perf_fum_follow_up_visit]', 'IF') IS NOT NULL
DROP FUNCTION [stage].[fn_perf_fum_follow_up_visit];
GO
CREATE FUNCTION [stage].[fn_perf_fum_follow_up_visit](@measurement_start_date DATE, @measurement_end_date DATE)
RETURNS TABLE 
AS
RETURN
/*
SELECT [value_set_name]
      ,[code_system]
      ,COUNT([code])
FROM [ref].[hedis_code_system]
WHERE [value_set_name] IN
('FUH Stand Alone Visits'
,'Mental Health Diagnosis'
,'Telehealth Modifier'
,'FUH POS Group 1'
,'FUH Visits Group 1'
,'FUH POS Group 2'
,'FUH Visits Group 2'
,'FUH RevCodes Group 1'
,'FUH RevCodes Group 2')
GROUP BY [value_set_name], [code_system]
ORDER BY [value_set_name], [code_system]

SELECT [value_set_name]
      ,[code_system]
      ,[code]
FROM [ref].[hedis_code_system]
WHERE [value_set_name] IN
('FUH RevCodes Group 1'
,'FUH RevCodes Group 2')
ORDER BY [value_set_name], [code_system]
*/

/*
Condition 1:
A visit (FUH Stand Alone Visits Value Set) with a principal diagnosis of a 
mental health disorder (Mental Health Diagnosis Value Set), with or without a 
telehealth modifier (Telehealth Modifier Value Set).
*/
(
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_proc] AS pr
ON hd.[tcn] = pr.[tcn]
INNER JOIN [ref].[hedis_code_system] AS hed
ON [value_set_name] IN 
('FUH Stand Alone Visits')
AND hed.[code_system] IN ('CPT', 'HCPCS')
AND pr.[pcode] = hed.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date

INTERSECT

SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_dx] AS dx
ON hd.[tcn] = dx.[tcn]
-- Principal Diagnosis
AND dx.[dx_number] = 1
INNER JOIN [ref].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Mental Health Diagnosis')
AND hed.[code_system] = 'ICD10CM'
AND dx.[dx_ver] = 10 
AND dx.[dx_norm] = hed.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date
)

UNION

/*
Condition 2:
A visit (FUH Visits Group 1 Value Set with FUH POS Group 1 Value Set) with a 
principal diagnosis of a mental health disorder (Mental Health Diagnosis Value 
Set), with or without a telehealth modifier (Telehealth Modifier Value Set).
*/
(
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_proc] AS pr
ON hd.[tcn] = pr.[tcn]
INNER JOIN [ref].[hedis_code_system] AS hed_cpt
ON hed_cpt.[value_set_name] IN 
('FUH Visits Group 1')
AND hed_cpt.[code_system] = 'CPT'
AND pr.[pcode] = hed_cpt.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date

INTERSECT

SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [ref].[hedis_code_system] AS hed_pos
ON hed_pos.[value_set_name] IN 
('FUH POS Group 1')
AND hed_pos.[code_system] = 'POS' 
AND hd.[pos_code] = hed_pos.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date

INTERSECT

SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_dx] AS dx
ON hd.[tcn] = dx.[tcn]
-- Principal Diagnosis
AND dx.[dx_number] = 1
INNER JOIN [ref].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Mental Health Diagnosis')
AND hed.[code_system] = 'ICD10CM'
AND dx.[dx_ver] = 10 
AND dx.[dx_norm] = hed.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date
)

UNION

/*
Condition 3:
A visit (FUH Visits Group 2 Value Set with FUH POS Group 2 Value Set) with a 
principal diagnosis of a mental health disorder (Mental Health Diagnosis Value 
Set), with or without a telehealth modifier (Telehealth Modifier Value Set).
*/
(
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_proc] AS pr
ON hd.[tcn] = pr.[tcn]
INNER JOIN [ref].[hedis_code_system] AS hed_cpt
ON hed_cpt.[value_set_name] IN 
('FUH Visits Group 2')
AND hed_cpt.[code_system] = 'CPT'
AND pr.[pcode] = hed_cpt.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date

INTERSECT

SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [ref].[hedis_code_system] AS hed_pos
ON hed_pos.[value_set_name] IN 
('FUH POS Group 2')
AND hed_pos.[code_system] = 'POS' 
AND hd.[pos_code] = hed_pos.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date

INTERSECT

SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_dx] AS dx
ON hd.[tcn] = dx.[tcn]
-- Principal Diagnosis
AND dx.[dx_number] = 1
INNER JOIN [ref].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Mental Health Diagnosis')
AND hed.[code_system] = 'ICD10CM'
AND dx.[dx_ver] = 10 
AND dx.[dx_norm] = hed.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date
)

UNION

/*
Condition 4:
A visit to a behavioral healthcare setting (FUH RevCodes Group 1 Value Set).
*/
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_line] AS ln
ON hd.[tcn] = ln.[tcn]
INNER JOIN [ref].[hedis_code_system] AS hed
ON [value_set_name] IN 
('FUH RevCodes Group 1')
AND hed.[code_system] = 'UBREV'
AND ln.[rcode] = hed.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date

UNION

/*
Condition 5:
A visit to a nonbehavioral healthcare setting (FUH RevCodes Group 2 Value Set) 
with a principal diagnosis of a mental health disorder (Mental Health Diagnosis
Value Set).
*/
(
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_line] AS ln
ON hd.[tcn] = ln.[tcn]
INNER JOIN [ref].[hedis_code_system] AS hed
ON [value_set_name] IN 
('FUH RevCodes Group 2')
AND hed.[code_system] = 'UBREV'
AND ln.[rcode] = hed.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date

INTERSECT

SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_dx] AS dx
ON hd.[tcn] = dx.[tcn]
-- Principal Diagnosis
AND dx.[dx_number] = 1
INNER JOIN [ref].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Mental Health Diagnosis')
AND hed.[code_system] = 'ICD10CM'
AND dx.[dx_ver] = 10 
AND dx.[dx_norm] = hed.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date
);
GO
/*
IF OBJECT_ID('tempdb..#temp') IS NOT NULL
DROP TABLE #temp;
SELECT * 
INTO #temp
FROM [stage].[fn_perf_fum_follow_up_visit]('2017-01-01', '2017-12-31');

SELECT TOP(100) *
FROM [stage].[fn_perf_fum_follow_up_visit]('2017-01-01', '2017-12-31');
*/