
/*
This procedure gets follow-up visits that meet the requirements for the 
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

IF OBJECT_ID('[stage].[sp_perf_fua_follow_up_visit]','P') IS NOT NULL
DROP PROCEDURE [stage].[sp_perf_fua_follow_up_visit];
GO
CREATE PROCEDURE [stage].[sp_perf_fua_follow_up_visit]
 @measurement_start_date DATE = NULL
,@measurement_end_date DATE = NULL
AS
--SET NOCOUNT ON;
DECLARE @SQL NVARCHAR(MAX) = '';
BEGIN

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

SET @SQL = @SQL + N'

IF OBJECT_ID(''tempdb..#AOD_Abuse_and_Dependence_icdcm_norm'') IS NOT NULL
DROP TABLE #AOD_Abuse_and_Dependence_icdcm_norm;
SELECT DISTINCT
TOP(100)
 [claim_header_id]

INTO #AOD_Abuse_and_Dependence_icdcm_norm

--SELECT COUNT(*)
FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
(''AOD Abuse and Dependence'')
AND hed.[code_system] = ''ICD10CM''
AND dx.[icdcm_version] = 10 
-- Principal Diagnosis
AND dx.[icdcm_number] = ''01''
AND dx.[icdcm_norm] = hed.[code]
WHERE [first_service_date] BETWEEN ''' + CAST(@measurement_start_date AS VARCHAR(10)) + ''' AND ''' + CAST(@measurement_end_date AS VARCHAR(10)) + '''

CREATE UNIQUE CLUSTERED INDEX idx_cl_#AOD_Abuse_and_Dependence_icdcm_norm ON #AOD_Abuse_and_Dependence_icdcm_norm([claim_header_id]);

/*
Condition 1:
IET Stand Alone Visits Value Set with a principal diagnosis of AOD abuse or 
dependence (AOD Abuse and Dependence Value Set), with or without a telehealth 
modifier (Telehealth Modifier Value Set).
*/

IF OBJECT_ID(''tempdb..#IET_Stand_Alone_Visits_procedure_code'') IS NOT NULL
DROP TABLE #IET_Stand_Alone_Visits_procedure_code;
SELECT 
TOP(100)
 [id_mcaid]
,pr.[claim_header_id]
,[first_service_date]
,[last_service_date]

INTO #IET_Stand_Alone_Visits_procedure_code

--SELECT COUNT(*)
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN #AOD_Abuse_and_Dependence_icdcm_norm AS dx
ON pr.[claim_header_id] = dx.[claim_header_id]
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
(''IET Stand Alone Visits'')
AND hed.[code_system] IN (''CPT'', ''HCPCS'')
AND pr.[procedure_code] = hed.[code]
WHERE [first_service_date] BETWEEN ''' + CAST(@measurement_start_date AS VARCHAR(10)) + ''' AND ''' + CAST(@measurement_end_date AS VARCHAR(10)) + '''

IF OBJECT_ID(''tempdb..#IET_Stand_Alone_Visits_rev_code'') IS NOT NULL
DROP TABLE #IET_Stand_Alone_Visits_rev_code;
SELECT 
TOP(100)
 [id_mcaid]
,ln.[claim_header_id]
,[first_service_date]
,[last_service_date]

INTO #IET_Stand_Alone_Visits_rev_code

--SELECT COUNT(*)
FROM [final].[mcaid_claim_line] AS ln
INNER JOIN #AOD_Abuse_and_Dependence_icdcm_norm AS dx
ON ln.[claim_header_id] = dx.[claim_header_id]
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
(''IET Stand Alone Visits'')
AND hed.[code_system] = ''UBREV''
AND ln.[rev_code] = hed.[code]
WHERE [first_service_date] BETWEEN ''' + CAST(@measurement_start_date AS VARCHAR(10)) + ''' AND ''' + CAST(@measurement_end_date AS VARCHAR(10)) + '''

/*
Condition 2:
IET Visits Group 1 Value Set with IET POS Group 1 Value Set and a principal 
diagnosis of AOD abuse or dependence (AOD Abuse and Dependence Value Set), with
or without a telehealth modifier (Telehealth Modifier Value Set).
*/

IF OBJECT_ID(''tempdb..#IET_Visits_Group_1_procedure_code'') IS NOT NULL
DROP TABLE #IET_Visits_Group_1_procedure_code;
SELECT 
TOP(100)
 [id_mcaid]
,pr.[claim_header_id]
,[first_service_date]
,[last_service_date]

INTO #IET_Visits_Group_1_procedure_code

--SELECT COUNT(*)
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN #AOD_Abuse_and_Dependence_icdcm_norm AS dx
ON pr.[claim_header_id] = dx.[claim_header_id]
INNER JOIN [archive].[hedis_code_system] AS hed_cpt
ON hed_cpt.[value_set_name] IN 
(''IET Visits Group 1'')
AND hed_cpt.[code_system] = ''CPT''
AND pr.[procedure_code] = hed_cpt.[code]
WHERE [first_service_date] BETWEEN ''' + CAST(@measurement_start_date AS VARCHAR(10)) + ''' AND ''' + CAST(@measurement_end_date AS VARCHAR(10)) + '''

IF OBJECT_ID(''tempdb..#IET_POS_Group_1_place_of_service_code'') IS NOT NULL
DROP TABLE #IET_POS_Group_1_place_of_service_code;
SELECT 
TOP(100)
 [id_mcaid]
,hd.[claim_header_id]
,[first_service_date]
,[last_service_date]

INTO #IET_POS_Group_1_place_of_service_code

--SELECT COUNT(*)
FROM [final].[mcaid_claim_header] AS hd
INNER JOIN #AOD_Abuse_and_Dependence_icdcm_norm AS dx
ON hd.[claim_header_id] = dx.[claim_header_id]
INNER JOIN [archive].[hedis_code_system] AS hed_pos
ON hed_pos.[value_set_name] IN 
(''IET POS Group 1'')
AND hed_pos.[code_system] = ''POS'' 
AND hd.[place_of_service_code] = hed_pos.[code]
WHERE [first_service_date] BETWEEN ''' + CAST(@measurement_start_date AS VARCHAR(10)) + ''' AND ''' + CAST(@measurement_end_date AS VARCHAR(10)) + '''

/*
Condition 3:
IET Visits Group 2 Value Set with IET POS Group 2 Value Set and a principal 
diagnosis of AOD abuse or dependence (AOD Abuse and Dependence Value Set), with
or without a telehealth modifier (Telehealth Modifier Value Set).
*/

IF OBJECT_ID(''tempdb..#IET_Visits_Group_2_procedure_code'') IS NOT NULL
DROP TABLE #IET_Visits_Group_2_procedure_code;
SELECT 
TOP(100)
 [id_mcaid]
,pr.[claim_header_id]
,[first_service_date]
,[last_service_date]

INTO #IET_Visits_Group_2_procedure_code

--SELECT COUNT(*)
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN #AOD_Abuse_and_Dependence_icdcm_norm AS dx
ON pr.[claim_header_id] = dx.[claim_header_id]
INNER JOIN [archive].[hedis_code_system] AS hed_cpt
ON hed_cpt.[value_set_name] IN 
(''IET Visits Group 2'')
AND hed_cpt.[code_system] = ''CPT''
AND pr.[procedure_code] = hed_cpt.[code]
WHERE [first_service_date] BETWEEN ''' + CAST(@measurement_start_date AS VARCHAR(10)) + ''' AND ''' + CAST(@measurement_end_date AS VARCHAR(10)) + '''

IF OBJECT_ID(''tempdb..#IET_POS_Group_2_place_of_service_code'') IS NOT NULL
DROP TABLE #IET_POS_Group_2_place_of_service_code;
SELECT 
TOP(100)
 [id_mcaid]
,hd.[claim_header_id]
,[first_service_date]
,[last_service_date]

INTO #IET_POS_Group_2_place_of_service_code

--SELECT COUNT(*)
FROM [final].[mcaid_claim_header] AS hd
INNER JOIN #AOD_Abuse_and_Dependence_icdcm_norm AS dx
ON hd.[claim_header_id] = dx.[claim_header_id]
INNER JOIN [archive].[hedis_code_system] AS hed_pos
ON hed_pos.[value_set_name] IN 
(''IET POS Group 2'')
AND hed_pos.[code_system] = ''POS'' 
AND hd.[place_of_service_code] = hed_pos.[code]
WHERE [first_service_date] BETWEEN ''' + CAST(@measurement_start_date AS VARCHAR(10)) + ''' AND ''' + CAST(@measurement_end_date AS VARCHAR(10)) + '''

/*
Condition 4:
A telephone visit (Telephone Visits Value Set) with a principal diagnosis of 
AOD abuse or dependence (AOD Abuse and Dependence Value Set). 
*/

IF OBJECT_ID(''tempdb..#Telephone_Visits_procedure_code'') IS NOT NULL
DROP TABLE #Telephone_Visits_procedure_code;
SELECT 
TOP(100)
 [id_mcaid]
,pr.[claim_header_id]
,[first_service_date]
,[last_service_date]

INTO #Telephone_Visits_procedure_code

--SELECT COUNT(*)
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN #AOD_Abuse_and_Dependence_icdcm_norm AS dx
ON pr.[claim_header_id] = dx.[claim_header_id]
INNER JOIN [archive].[hedis_code_system] AS hed_cpt
ON hed_cpt.[value_set_name] IN 
(''Telephone Visits'')
AND hed_cpt.[code_system] = ''CPT''
AND pr.[procedure_code] = hed_cpt.[code]
WHERE [first_service_date] BETWEEN ''' + CAST(@measurement_start_date AS VARCHAR(10)) + ''' AND ''' + CAST(@measurement_end_date AS VARCHAR(10)) + '''

/*
Condition 5:
An online assessment (Online Assessments Value Set) with a principal diagnosis 
of AOD abuse or dependence (AOD Abuse and Dependence Value Set).
*/

IF OBJECT_ID(''tempdb..#Online_Assessments_procedure_code'') IS NOT NULL
DROP TABLE #Online_Assessments_procedure_code;
SELECT 
TOP(100)
 [id_mcaid]
,pr.[claim_header_id]
,[first_service_date]
,[last_service_date]

INTO #Online_Assessments_procedure_code

--SELECT COUNT(*)
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN #AOD_Abuse_and_Dependence_icdcm_norm AS dx
ON pr.[claim_header_id] = dx.[claim_header_id]
INNER JOIN [archive].[hedis_code_system] AS hed_cpt
ON hed_cpt.[value_set_name] IN 
(''Online Assessments'')
AND hed_cpt.[code_system] = ''CPT''
AND pr.[procedure_code] = hed_cpt.[code]
WHERE [first_service_date] BETWEEN ''' + CAST(@measurement_start_date AS VARCHAR(10)) + ''' AND ''' + CAST(@measurement_end_date AS VARCHAR(10)) + '''

-- RETURN SET OF FOLLOW-UP VISITS
SELECT *, 1 AS [flag] FROM #IET_Stand_Alone_Visits_procedure_code

UNION

SELECT *, 1 AS [flag] FROM #IET_Stand_Alone_Visits_rev_code

UNION

(
SELECT *, 1 AS [flag] FROM #IET_Visits_Group_1_procedure_code

INTERSECT

SELECT *, 1 AS [flag] FROM #IET_POS_Group_1_place_of_service_code
)

UNION

(
SELECT *, 1 AS [flag] FROM #IET_Visits_Group_2_procedure_code

INTERSECT

SELECT *, 1 AS [flag] FROM #IET_POS_Group_2_place_of_service_code
)

UNION

SELECT *, 1 AS [flag] FROM #Telephone_Visits_procedure_code

UNION

SELECT *, 1 AS [flag] FROM #Online_Assessments_procedure_code;'

PRINT @SQL;
END
EXEC sp_executeSQL 
 @statement=@SQL
,@params=N'@measurement_start_date DATE, @measurement_end_date DATE'
,@measurement_start_date=@measurement_start_date, @measurement_end_date=@measurement_end_date;
GO

/*
IF OBJECT_ID('tempdb..#temp', 'U') IS NOT NULL
DROP TABLE #temp;
CREATE TABLE #temp
([id_mcaid] VARCHAR(255)
,[claim_header_id] BIGINT
,[first_service_date] DATE
,[last_service_date] DATE
,[flag] INT);

INSERT INTO #temp
EXEC [stage].[sp_perf_fua_follow_up_visit]
 @measurement_start_date='2017-01-01'
,@measurement_end_date='2017-12-31';

SELECT * FROM #temp;
*/