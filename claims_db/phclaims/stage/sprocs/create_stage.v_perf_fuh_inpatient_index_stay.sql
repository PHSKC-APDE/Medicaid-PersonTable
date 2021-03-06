
/*
This view gets inpatient stays for the FUH (Follow-up After Hospitalization for Mental Illness).
Two result sets are STACKED on each other
FIRST, for Mental Illness
SECOND, for Mental Health Diagnosis

LOGIC: Acute Inpatient Stays with a Mental Illness Principal Diagnosis
Principal diagnosis in Mental Illness Value Set
INTERSECT
(
Inpatient Stay Value Set
EXCEPT
Nonacute Inpatient Stay
)

UNION ALL

LOGIC: Acute Inpatient Stays with a Mental Health Diagnosis Principal Diagnosis
Principal diagnosis in Mental Health Diagnosis Value Set
INTERSECT
(
Inpatient Stay Value Set
EXCEPT
Nonacute Inpatient Stay
)

Author: Philip Sylling
Created: 2019-04-25
Modified: 2019-08-09 | Point to new [final] analytic tables
Modified: 2019-09-20 | Use admit/discharge dates instead of first/last service dates

Returns:
 [value_set_name]
,[id_mcaid]
,[age]
,[claim_header_id]
,[admit_date]
,[discharge_date]
,[flag] = 1
*/

USE [PHClaims];
GO

IF OBJECT_ID('[stage].[v_perf_fuh_inpatient_index_stay]', 'V') IS NOT NULL
DROP VIEW [stage].[v_perf_fuh_inpatient_index_stay];
GO
CREATE VIEW [stage].[v_perf_fuh_inpatient_index_stay]
AS
/*
SELECT [value_set_name]
      ,[code_system]
      ,COUNT([code])
FROM [archive].[hedis_code_system]
WHERE [value_set_name] IN
('Mental Illness'
,'Mental Health Diagnosis'
,'Inpatient Stay'
,'Nonacute Inpatient Stay')
GROUP BY [value_set_name], [code_system]
ORDER BY [value_set_name], [code_system];
*/

WITH [mental_illness_value_set] AS
(
/*
Mental Illness Value Set does not include ICD9CM diagnosis codes
*/
SELECT 
 [id_mcaid]
,[claim_header_id]
,1 AS [flag]

--SELECT COUNT(*)
FROM [stage].[mcaid_claim_value_set]
WHERE 1 = 1
AND [value_set_group] = 'HEDIS'
AND [value_set_name] IN ('Mental Illness')
AND [code_set] = 'ICD10CM'
-- Principal Diagnosis
AND [primary_dx_only] = 'Y'

INTERSECT

(
SELECT 
 [id_mcaid]
,[claim_header_id]
,1 AS [flag]

--SELECT COUNT(*)
FROM [stage].[mcaid_claim_value_set]
WHERE 1 = 1
AND [value_set_group] = 'HEDIS'
AND [value_set_name] IN 
('Inpatient Stay')
AND [code_set] = 'UBREV'

EXCEPT

(
SELECT 
 [id_mcaid]
,[claim_header_id]
,1 AS [flag]

--SELECT COUNT(*)
FROM [stage].[mcaid_claim_value_set]
WHERE 1 = 1
AND [value_set_group] = 'HEDIS'
AND [value_set_name] IN 
('Nonacute Inpatient Stay')
AND [code_set] = 'UBREV'

UNION

SELECT 
 [id_mcaid]
,[claim_header_id]
,1 AS [flag]

--SELECT COUNT(*)
FROM [stage].[mcaid_claim_value_set]
WHERE 1 = 1
AND [value_set_group] = 'HEDIS'
AND [value_set_name] IN 
('Nonacute Inpatient Stay')
AND [code_set] = 'UBTOB'
))),

[mental_health_diagnosis_value_set] AS
(
/*
Mental Health Diagnosis Value Set does not include ICD9CM diagnosis codes
*/
SELECT 
 [id_mcaid]
,[claim_header_id]
,1 AS [flag]

--SELECT COUNT(*)
FROM [stage].[mcaid_claim_value_set]
WHERE 1 = 1
AND [value_set_group] = 'HEDIS'
AND [value_set_name] IN ('Mental Health Diagnosis')
AND [code_set] = 'ICD10CM'
-- Principal Diagnosis
AND [primary_dx_only] = 'Y'

INTERSECT

(
SELECT 
 [id_mcaid]
,[claim_header_id]
,1 AS [flag]

--SELECT COUNT(*)
FROM [stage].[mcaid_claim_value_set]
WHERE 1 = 1
AND [value_set_group] = 'HEDIS'
AND [value_set_name] IN 
('Inpatient Stay')
AND [code_set] = 'UBREV'

EXCEPT

(
SELECT 
 [id_mcaid]
,[claim_header_id]
,1 AS [flag]

--SELECT COUNT(*)
FROM [stage].[mcaid_claim_value_set]
WHERE 1 = 1
AND [value_set_group] = 'HEDIS'
AND [value_set_name] IN 
('Nonacute Inpatient Stay')
AND [code_set] = 'UBREV'

UNION

SELECT 
 [id_mcaid]
,[claim_header_id]
,1 AS [flag]

--SELECT COUNT(*)
FROM [stage].[mcaid_claim_value_set]
WHERE 1 = 1
AND [value_set_group] = 'HEDIS'
AND [value_set_name] IN 
('Nonacute Inpatient Stay')
AND [code_set] = 'UBTOB'
))),

[age_x_year_old] AS
(
SELECT 
 'Mental Illness' AS [value_set_name]
,cl.[id_mcaid]
,elig.[dob]
,DATEDIFF(YEAR, elig.[dob], COALESCE(hd.[dschrg_date], hd.[last_service_date])) - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, elig.[dob], COALESCE(hd.[dschrg_date], hd.[last_service_date])), elig.[dob]) > COALESCE(hd.[dschrg_date], hd.[last_service_date]) THEN 1 ELSE 0 END AS [age]
,cl.[claim_header_id]
,hd.[admsn_date] AS [admit_date]
,hd.[dschrg_date] AS [discharge_date]
,hd.[first_service_date]
,hd.[last_service_date]
,cl.[flag]
FROM [mental_illness_value_set] AS cl
INNER JOIN [final].[mcaid_elig_demo] AS elig
ON cl.[id_mcaid] = elig.[id_mcaid]
INNER JOIN [final].[mcaid_claim_header] AS hd
ON cl.[claim_header_id] = hd.[claim_header_id]

UNION ALL

SELECT 
 'Mental Health Diagnosis' AS [value_set_name]
,cl.[id_mcaid]
,elig.[dob]
,DATEDIFF(YEAR, elig.[dob], COALESCE(hd.[dschrg_date], hd.[last_service_date])) - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, elig.[dob], COALESCE(hd.[dschrg_date], hd.[last_service_date])), elig.[dob]) > COALESCE(hd.[dschrg_date], hd.[last_service_date]) THEN 1 ELSE 0 END AS [age]
,cl.[claim_header_id]
,hd.[admsn_date] AS [admit_date]
,hd.[dschrg_date] AS [discharge_date]
,hd.[first_service_date]
,hd.[last_service_date]
,cl.[flag]
FROM [mental_health_diagnosis_value_set] AS cl
INNER JOIN [final].[mcaid_elig_demo] AS elig
ON cl.[id_mcaid] = elig.[id_mcaid]
INNER JOIN [final].[mcaid_claim_header] AS hd
ON cl.[claim_header_id] = hd.[claim_header_id]
)

SELECT *
FROM [age_x_year_old];
GO

/*
SELECT *
FROM [stage].[v_perf_fuh_inpatient_index_stay]
WHERE [value_set_name] = 'Mental Illness';

SELECT DISTINCT
 [value_set_name]
,[id_mcaid]
,[dob]
,[age]
,[claim_header_id]
,[admit_date]
,[discharge_date]
,[first_service_date]
,[last_service_date]
,[flag]
FROM [stage].[v_perf_fuh_inpatient_index_stay]
WHERE [value_set_name] = 'Mental Illness';

SELECT 
 [year_quarter]
,COUNT(*)
FROM [stage].[v_perf_fuh_inpatient_index_stay] AS a
INNER JOIN [ref].[date] AS b
ON a.[discharge_date] = b.[date]
WHERE [value_set_name] = 'Mental Illness'
GROUP BY [year_quarter]
ORDER BY [year_quarter];
*/