
USE PHClaims;
GO

IF OBJECT_ID('[stage].[fn_perf_fua_ed_index_visit]', 'IF') IS NOT NULL
DROP FUNCTION [stage].[fn_perf_fua_ed_index_visit];
GO
CREATE FUNCTION [stage].[fn_perf_fua_ed_index_visit]
(@measurement_start_date DATE
,@measurement_end_date DATE
,@age INT
,@dx_value_set_name VARCHAR(100))
RETURNS TABLE 
AS
RETURN
/*
SELECT [measure_id]
      ,[value_set_name]
      ,[value_set_oid]
FROM [ref].[hedis_value_set]
WHERE [measure_id] IN ('FUA')
ORDER BY [measure_id], [value_set_name], [value_set_oid];

SELECT [value_set_name]
      ,[code_system]
      ,COUNT([code])
FROM [ref].[hedis_code_system]
WHERE [value_set_name] IN 
('AOD Abuse and Dependence'
,'ED'
,'IET POS Group 1'
,'IET POS Group 2'
,'IET Stand Alone Visits'
,'IET Visits Group 1'
,'IET Visits Group 2'
,'Inpatient Stay'
,'Online Assessments' 
,'Telehealth Modifier' 
,'Telephone Visits')
GROUP BY [value_set_name], [code_system]
ORDER BY [value_set_name], [code_system];

SELECT [value_set_name]
      ,[code_system]
      ,[code]
FROM [ref].[hedis_code_system]
WHERE [value_set_name] IN 
('ED')
ORDER BY [value_set_name], [code_system];

SELECT [value_set_name]
      ,[code_system]
      ,COUNT([code])
FROM [ref].[hedis_code_system]
WHERE [value_set_name] IN
('FUH POS Group 1'
,'FUH POS Group 2'
,'FUH RevCodes Group 1'
,'FUH RevCodes Group 2'
,'FUH Stand Alone Visits'
,'FUH Visits Group 1'
,'FUH Visits Group 2'
,'Mental Health Diagnosis'
,'Telehealth Modifier')
GROUP BY [value_set_name], [code_system]
ORDER BY [value_set_name], [code_system];
*/

WITH [get_claims] AS
(
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]

FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_dx] AS dx
ON hd.[tcn] = dx.[tcn]
INNER JOIN [ref].[hedis_code_system] AS hed
-- 2 Values: 'AOD Abuse and Dependence', 'Mental Illness'
ON [value_set_name] = @dx_value_set_name
AND hed.[code_system] = 'ICD10CM'
AND dx.[dx_ver] = 10
AND dx.[dx_number] = 1
AND dx.[dx_norm] = hed.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date

INTERSECT

(
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]

FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_line] AS ln
ON hd.[tcn] = ln.[tcn]
INNER JOIN [ref].[hedis_code_system] AS hed
ON [value_set_name] IN 
('ED')
AND hed.[code_system] = 'UBREV'
AND ln.[rcode] = hed.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date

UNION

SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]
--,hed.[value_set_name]
,1 AS [flag]

FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_proc] AS pr
ON hd.[tcn] = pr.[tcn]
INNER JOIN [ref].[hedis_code_system] AS hed
ON [value_set_name] IN 
('ED')
AND hed.[code_system] = 'CPT'
AND pr.[pcode] = hed.[code]
WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date
)),

[age_x_year_old] AS
(
SELECT 
 cl.[id]
,DATEDIFF(YEAR, elig.[dobnew], cl.[from_date]) - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, elig.[dobnew], cl.[from_date]), elig.[dobnew]) > cl.[from_date] THEN 1 ELSE 0 END AS [age]
,[tcn]
,[from_date]
,[to_date]
,[flag]
FROM [get_claims] AS cl
INNER JOIN [dbo].[mcaid_elig_demoever] AS elig
ON cl.[id] = elig.[id]
WHERE DATEDIFF(YEAR, elig.[dobnew], cl.[from_date]) - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, elig.[dobnew], cl.[from_date]), elig.[dobnew]) > cl.[from_date] THEN 1 ELSE 0 END >= @age
)

SELECT *
FROM [age_x_year_old];
GO

/*
IF OBJECT_ID('tempdb..#temp', 'U') IS NOT NULL
DROP TABLE #temp;
SELECT *
INTO #temp
FROM [stage].[fn_perf_fua_ed_index_visit]('2017-01-01', '2017-12-31', 6, 'Mental Illness');

IF OBJECT_ID('tempdb..#temp2', 'U') IS NOT NULL
DROP TABLE #temp2;
SELECT *
INTO #temp2
FROM [stage].[fn_perf_fua_ed_index_visit]('2017-01-01', '2017-12-31', 13, 'AOD Abuse and Dependence');
*/
