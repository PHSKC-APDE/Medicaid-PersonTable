/*
This function gets follow-up visits that meet the requirements for the 
HEDIS FUA (Follow-Up After Emergency Department Visit for Alcohol and 
Other Drug Abuse or Dependence) measure.

Author: Philip Sylling
Created: 2019-04-24
Modified: 2019-07-25 | Point to new [final] analytic tables

Returns:
 [id_mcaid]
,[claim_header_id]
,[first_service_date], [FROM_SRVC_DATE]
,[last_service_date], [TO_SRVC_DATE]
,[flag], 1 for claim meeting follow-up visit criteria
*/

USE [PHClaims];
GO

IF OBJECT_ID('[stage].[fn_perf_fua_follow_up_visit]', 'IF') IS NOT NULL
DROP FUNCTION [stage].[fn_perf_fua_follow_up_visit];
GO
CREATE FUNCTION [stage].[fn_perf_fua_follow_up_visit](@measurement_start_date DATE, @measurement_end_date DATE)
RETURNS TABLE 
AS
RETURN
/*
SELECT [measure_id]
      ,[value_set_name]
      ,[value_set_oid]
FROM [archive].[hedis_value_set]
WHERE [measure_id] = 'FUA';
SELECT [value_set_name]
      ,[code_system]
      ,COUNT([code])
FROM [archive].[hedis_code_system]
WHERE [value_set_name] IN
('IET POS Group 1'
,'IET POS Group 2'
,'IET Stand Alone Visits'
,'IET Visits Group 1'
,'IET Visits Group 2'
,'Online Assessments'
,'Telehealth Modifier' 
,'Telephone Visits')
GROUP BY [value_set_name], [code_system]
ORDER BY [value_set_name], [code_system];
*/

WITH [get_claims] AS
(
/*
Condition 1:
IET Stand Alone Visits Value Set with a principal diagnosis of AOD abuse or 
dependence (AOD Abuse and Dependence Value Set), with or without a telehealth 
modifier (Telehealth Modifier Value Set).
*/
((
SELECT 
 [id_mcaid]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('IET Stand Alone Visits')
AND hed.[code_system] IN ('CPT', 'HCPCS')
AND pr.[procedure_code] = hed.[code]
WHERE [first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE [first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'

UNION

SELECT 
 [id_mcaid]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('IET Stand Alone Visits')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code]
WHERE [first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE [first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'
)

INTERSECT

SELECT 
 [id_mcaid]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('AOD Abuse and Dependence')
AND hed.[code_system] = 'ICD10CM'
AND dx.[icdcm_version] = 10 
-- Principal Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = hed.[code]
WHERE [first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE [first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'

)

UNION

/*
Condition 2:
IET Visits Group 1 Value Set with IET POS Group 1 Value Set and a principal 
diagnosis of AOD abuse or dependence (AOD Abuse and Dependence Value Set), with
or without a telehealth modifier (Telehealth Modifier Value Set).
*/
(
SELECT 
 [id_mcaid]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN [archive].[hedis_code_system] AS hed_cpt
ON hed_cpt.[value_set_name] IN 
('IET Visits Group 1')
AND hed_cpt.[code_system] = 'CPT'
AND pr.[procedure_code] = hed_cpt.[code]
WHERE [first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE [first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'

INTERSECT

SELECT 
 [id_mcaid]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_header] AS hd
INNER JOIN [archive].[hedis_code_system] AS hed_pos
ON hed_pos.[value_set_name] IN 
('IET POS Group 1')
AND hed_pos.[code_system] = 'POS' 
AND hd.[place_of_service_code] = hed_pos.[code]
WHERE [first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE [first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'

INTERSECT

SELECT 
 [id_mcaid]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('AOD Abuse and Dependence')
AND hed.[code_system] = 'ICD10CM'
AND dx.[icdcm_version] = 10 
-- Principal Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = hed.[code]
WHERE [first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE [first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'
)

UNION

/*
Condition 3:
IET Visits Group 2 Value Set with IET POS Group 2 Value Set and a principal 
diagnosis of AOD abuse or dependence (AOD Abuse and Dependence Value Set), with
or without a telehealth modifier (Telehealth Modifier Value Set).
*/
(
SELECT 
 [id_mcaid]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN [archive].[hedis_code_system] AS hed_cpt
ON hed_cpt.[value_set_name] IN 
('IET Visits Group 2')
AND hed_cpt.[code_system] = 'CPT'
AND pr.[procedure_code] = hed_cpt.[code]
WHERE [first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE [first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'

INTERSECT

SELECT 
 [id_mcaid]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_header] AS hd
INNER JOIN [archive].[hedis_code_system] AS hed_pos
ON hed_pos.[value_set_name] IN 
('IET POS Group 2')
AND hed_pos.[code_system] = 'POS' 
AND hd.[place_of_service_code] = hed_pos.[code]
WHERE [first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE [first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'

INTERSECT

SELECT 
 [id_mcaid]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('AOD Abuse and Dependence')
AND hed.[code_system] = 'ICD10CM'
AND dx.[icdcm_version] = 10 
-- Principal Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = hed.[code]
WHERE [first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE [first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'
)

UNION

/*
Condition 4:
A telephone visit (Telephone Visits Value Set) with a principal diagnosis of 
AOD abuse or dependence (AOD Abuse and Dependence Value Set). 
*/
(
SELECT 
 [id_mcaid]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN [archive].[hedis_code_system] AS hed_cpt
ON hed_cpt.[value_set_name] IN 
('Telephone Visits')
AND hed_cpt.[code_system] = 'CPT'
AND pr.[procedure_code] = hed_cpt.[code]
WHERE [first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE [first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'

INTERSECT

SELECT 
 [id_mcaid]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('AOD Abuse and Dependence')
AND hed.[code_system] = 'ICD10CM'
AND dx.[icdcm_version] = 10 
-- Principal Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = hed.[code]
WHERE [first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE [first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'
)

UNION

/*
Condition 5:
An online assessment (Online Assessments Value Set) with a principal diagnosis 
of AOD abuse or dependence (AOD Abuse and Dependence Value Set).
*/
(
SELECT 
 [id_mcaid]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN [archive].[hedis_code_system] AS hed_cpt
ON hed_cpt.[value_set_name] IN 
('Online Assessments ')
AND hed_cpt.[code_system] = 'CPT'
AND pr.[procedure_code] = hed_cpt.[code]
WHERE [first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE [first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'

INTERSECT

SELECT 
 [id_mcaid]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('AOD Abuse and Dependence')
AND hed.[code_system] = 'ICD10CM'
AND dx.[icdcm_version] = 10 
-- Principal Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = hed.[code]
WHERE [first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE [first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'
)
)
SELECT 
 [id_mcaid]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
,[flag]
FROM [get_claims]
--WHERE [first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE [first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'
GO

/*
IF OBJECT_ID('tempdb..#temp') IS NOT NULL
DROP TABLE #temp;
SELECT * 
INTO #temp
FROM [stage].[fn_perf_fua_follow_up_visit]('2017-01-01', '2017-12-31');
*/
