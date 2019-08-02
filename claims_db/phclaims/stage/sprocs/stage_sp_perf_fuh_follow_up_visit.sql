
/*
This procedure gets follow-up visits for the FUH measure:
Follow-up Hospitalization for Mental Illness: 7 days
Follow-up Hospitalization for Mental Illness: 30 days

Author: Philip Sylling
Created: 2019-04-24
Modified: 2019-07-30 | Point to new [final] analytic tables

Returns:
SELECT 
 [id_mcaid]
,[claim_header_id]
,[first_service_date], [FROM_SRVC_DATE]
,[last_service_date], [TO_SRVC_DATE]
,[flag], 1 for claim meeting FUH follow-up visits criteria
,[only_30_day_fu], if 'Y' claim only meets requirement for 30-day follow-up, if 'N' claim meets requirement for 7-day and 30-day follow-up
*/

USE [PHClaims];
GO

/*
SELECT [measure_id]
      ,[value_set_name]
      ,[value_set_oid]
FROM [archive].[hedis_value_set]
WHERE [measure_id] = 'FUH';

SELECT [value_set_name]
      ,[code_system]
      ,COUNT([code])
FROM [archive].[hedis_code_system]
WHERE [value_set_name] IN
('FUH POS Group 1'
,'FUH POS Group 2'
,'FUH RevCodes Group 1'
,'FUH RevCodes Group 2'
,'FUH Stand Alone Visits'
,'FUH Visits Group 1'
,'FUH Visits Group 2'
,'Inpatient Stay'
,'Mental Health Diagnosis'
,'Mental Illness'
,'Nonacute Inpatient Stay'
,'TCM 14 Day'
,'TCM 7 Day'
,'Telehealth Modifier')
GROUP BY [value_set_name], [code_system]
ORDER BY [value_set_name], [code_system];
*/

/*
Condition 1:
A visit (FUH Stand Alone Visits Value Set) with a mental health practitioner, 
with or without a telehealth modifier (Telehealth Modifier Value Set).
*/
DECLARE 
 @measurement_start_date AS DATE = '2017-01-01'
,@measurement_end_date AS DATE = '2017-12-31';

(
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]
,'N' AS [only_30_day_fu]

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
--WHERE hd.[from_date] BETWEEN '2017-01-01' AND '2017-12-31'
)

UNION
/*
Condition 2:
A visit (FUH Visits Group 1 Value Set with FUH POS Group 1 Value Set) with a 
mental health practitioner, with or without a telehealth modifier (Telehealth 
Modifier Value Set).
*/
(
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]
,'N' AS [only_30_day_fu]

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
--WHERE hd.[from_date] BETWEEN '2017-01-01' AND '2017-12-31'

INTERSECT

SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]
,'N' AS [only_30_day_fu]

--SELECT COUNT(*)
FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [ref].[hedis_code_system] AS hed_pos
ON hed_pos.[value_set_name] IN 
('FUH POS Group 1')
AND hed_pos.[code_system] = 'POS' 
AND hd.[pos_code] = hed_pos.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE hd.[from_date] BETWEEN '2017-01-01' AND '2017-12-31'
)

UNION
/*
Condition 3:
A visit (FUH Visits Group 2 Value Set with FUH POS Group 2 Value Set) with a 
mental health practitioner, with or without a telehealth modifier (Telehealth 
Modifier Value Set).
*/
(
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]
,'N' AS [only_30_day_fu]

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
--WHERE hd.[from_date] BETWEEN '2017-01-01' AND '2017-12-31'

INTERSECT

SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]
,'N' AS [only_30_day_fu]

--SELECT COUNT(*)
FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [ref].[hedis_code_system] AS hed_pos
ON hed_pos.[value_set_name] IN 
('FUH POS Group 2')
AND hed_pos.[code_system] = 'POS' 
AND hd.[pos_code] = hed_pos.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE hd.[from_date] BETWEEN '2017-01-01' AND '2017-12-31'
)

UNION
/*
Condition 4:
A visit in a behavioral healthcare setting (FUH RevCodes Group 1 Value Set).
*/
(
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]
,'N' AS [only_30_day_fu]

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
--WHERE hd.[from_date] BETWEEN '2017-01-01' AND '2017-12-31'
)

UNION
/*
Condition 5:
A visit in a nonbehavioral healthcare setting (FUH RevCodes Group 2 Value Set) 
with a mental health practitioner.
*/
(
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]
,'N' AS [only_30_day_fu]

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
--WHERE hd.[from_date] BETWEEN '2017-01-01' AND '2017-12-31'
)

UNION
/*
Condition 7:
Transitional care management services (TCM 7 Day Value Set), with or without a 
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
,'N' AS [only_30_day_fu]

--SELECT COUNT(*)
FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_proc] AS pr
ON hd.[tcn] = pr.[tcn]
INNER JOIN [ref].[hedis_code_system] AS hed_cpt
ON hed_cpt.[value_set_name] IN 
('TCM 7 Day')
AND hed_cpt.[code_system] = 'CPT'
AND pr.[pcode] = hed_cpt.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE hd.[from_date] BETWEEN '2017-01-01' AND '2017-12-31'
)

UNION
/*
Condition 8:
Transitional care management services (TCM 14 Day Value Set), with or without a
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
,'Y' AS [only_30_day_fu]

--SELECT COUNT(*)
FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_proc] AS pr
ON hd.[tcn] = pr.[tcn]
INNER JOIN [ref].[hedis_code_system] AS hed_cpt
ON hed_cpt.[value_set_name] IN 
('TCM 14 Day')
AND hed_cpt.[code_system] = 'CPT'
AND pr.[pcode] = hed_cpt.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE hd.[from_date] BETWEEN '2017-01-01' AND '2017-12-31'
)
)

SELECT 
 [id]
,[tcn]
,[from_date]
,[to_date]
,[flag]
,MAX([only_30_day_fu]) AS [only_30_day_fu] 

FROM [get_claims]
GROUP BY [id], [tcn], [from_date], [to_date], [flag]
--WHERE [from_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE [from_date] BETWEEN '2017-01-01' AND '2017-12-31'
GO
/*
IF OBJECT_ID('tempdb..#temp') IS NOT NULL
DROP TABLE #temp;
SELECT * 
INTO #temp
FROM [stage].[fn_perf_fuh_follow_up_visit]('2017-01-01', '2017-12-31');

SELECT * FROM #temp WHERE [only_30_day_fu] = 'Y';
*/