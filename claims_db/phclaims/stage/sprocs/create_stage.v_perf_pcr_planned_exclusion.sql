
/*
This view gets claims that meet the requirements for Planned Hospital Stays.
These stays should not be counted as Hospital Readmissions.

Author: Philip Sylling
Created: 2019-04-30
Modified: 2019-08-14

Logic:
SELECT

((('Inpatient Stay')
FOR
('Bone Marrow Transplant'
,'Chemotherapy'
,'Kidney Transplant'
,'Organ Transplant Other Than Kidney'
,'Rehabilitation'))

UNION

(('Inpatient Stay')
FOR
('Potentially Planned Procedures'))
EXCEPT
(('Inpatient Stay')
FOR
('Acute Condition')))

EXCEPT

('Nonacute Inpatient Stay')

Returns:
 [id_mcaid]
,[claim_header_id]
,[first_service_date], [FROM_SRVC_DATE]
,[last_service_date], [TO_SRVC_DATE]
,[flag], 1 for claim meeting planned hospital stay criteria
*/

USE [PHClaims];
GO

IF OBJECT_ID('[stage].[v_perf_pcr_planned_exclusion]', 'V') IS NOT NULL
DROP VIEW [stage].[v_perf_pcr_planned_exclusion];
GO
CREATE VIEW [stage].[v_perf_pcr_planned_exclusion]
AS
/*
SELECT 
 [value_set_name]
,[code_system]
,COUNT([code])
FROM [archive].[hedis_code_system]
WHERE [value_set_name] IN
('Chemotherapy'
,'Rehabilitation'
,'Kidney Transplant'
,'Bone Marrow Transplant'
,'Organ Transplant Other Than Kidney'
,'Potentially Planned Procedures'
,'Acute Condition')
GROUP BY [value_set_name], [code_system]
ORDER BY [code_system], [value_set_name];
*/

/*
Exclude any hospital stay as an Index Hospital Stay if the admission date of 
the first stay within 30 days meets any of the following criteria:
A principal diagnosis of maintenance chemotherapy (Chemotherapy Value Set).
A principal diagnosis of rehabilitation (Rehabilitation Value Set).
An organ transplant (Kidney Transplant Value Set, Bone Marrow Transplant Value 
Set, Organ Transplant Other Than Kidney Value Set).
A potentially planned procedure (Potentially Planned Procedures Value Set) 
without a principal acute diagnosis (Acute Condition Value Set).
*/

/*
Diagnosis Codes for
A principal diagnosis of maintenance chemotherapy (Chemotherapy Value Set).
A principal diagnosis of rehabilitation (Rehabilitation Value Set).
An organ transplant (Kidney Transplant Value Set).
*/

WITH [get_claims] AS
(((
SELECT 
 ln.[id_mcaid]
,ln.[claim_header_id]
,ln.[first_service_date]
,ln.[last_service_date]
FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON hed.[value_set_name] IN 
('Inpatient Stay')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code]

INTERSECT

SELECT 
 dx.[id_mcaid]
,dx.[claim_header_id]
,dx.[first_service_date]
,dx.[last_service_date]
FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [archive].[hedis_code_system] AS hed
ON hed.[value_set_name] IN 
('Chemotherapy'
,'Kidney Transplant'
,'Rehabilitation')
AND hed.[code_system] = 'ICD10CM'
AND dx.[icdcm_version] = 10
-- Principal Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = hed.[code]
)

UNION

/*
Procedure Codes for
An organ transplant (Kidney Transplant Value Set, Bone Marrow Transplant Value 
Set, Organ Transplant Other Than Kidney Value Set).
*/
(
SELECT 
 ln.[id_mcaid]
,ln.[claim_header_id]
,ln.[first_service_date]
,ln.[last_service_date]
FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON hed.[value_set_name] IN 
('Inpatient Stay')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code]

INTERSECT

SELECT 
 pr.[id_mcaid]
,pr.[claim_header_id]
,pr.[first_service_date]
,pr.[last_service_date]
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN [archive].[hedis_code_system] AS hed
ON hed.[value_set_name] IN 
('Bone Marrow Transplant'
,'Kidney Transplant'
,'Organ Transplant Other Than Kidney')
AND hed.[code_system] IN ('CPT', 'HCPCS', 'ICD10PCS')
AND pr.[procedure_code] = hed.[code]
)

UNION

/*
Revenue Codes for
An organ transplant (Kidney Transplant Value Set, Organ Transplant Other Than 
Kidney Value Set).
*/
(
SELECT 
 ln.[id_mcaid]
,ln.[claim_header_id]
,ln.[first_service_date]
,ln.[last_service_date]

FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON hed.[value_set_name] IN 
('Inpatient Stay')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code]

INTERSECT

SELECT 
 ln.[id_mcaid]
,ln.[claim_header_id]
,ln.[first_service_date]
,ln.[last_service_date]

FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON hed.[value_set_name] IN 
('Kidney Transplant'
,'Organ Transplant Other Than Kidney')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code]
)

UNION

/*
A potentially planned procedure (Potentially Planned Procedures Value Set) 
without a principal acute diagnosis (Acute Condition Value Set).
*/
((
SELECT 
 ln.[id_mcaid]
,ln.[claim_header_id]
,ln.[first_service_date]
,ln.[last_service_date]
FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON hed.[value_set_name] IN 
('Inpatient Stay')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code]

INTERSECT

SELECT 
 pr.[id_mcaid]
,pr.[claim_header_id]
,pr.[first_service_date]
,pr.[last_service_date]
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN [archive].[hedis_code_system] AS hed
ON hed.[value_set_name] IN 
('Potentially Planned Procedures')
AND hed.[code_system] IN ('ICD10PCS')
AND pr.[procedure_code] = hed.[code]
)

EXCEPT

(
SELECT 
 ln.[id_mcaid]
,ln.[claim_header_id]
,ln.[first_service_date]
,ln.[last_service_date]
FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON hed.[value_set_name] IN 
('Inpatient Stay')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code]

INTERSECT

SELECT 
 dx.[id_mcaid]
,dx.[claim_header_id]
,dx.[first_service_date]
,dx.[last_service_date]
FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [archive].[hedis_code_system] AS hed
ON hed.[value_set_name] IN 
('Acute Condition')
AND hed.[code_system] = 'ICD10CM'
AND dx.[icdcm_version] = 10
-- Principal Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = hed.[code]
)))

/*
Only 0.3% of the above planned stays are non-acute.
The EXCEPT below removes these non-acute stays.
To include non-acute stays, the below EXCEPT should be commented out.
*/

EXCEPT

(
SELECT 
 ln.[id_mcaid]
,ln.[claim_header_id]
,ln.[first_service_date]
,ln.[last_service_date]

FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON hed.[value_set_name] IN 
('Nonacute Inpatient Stay')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code]

UNION

SELECT 
 hd.[id_mcaid]
,hd.[claim_header_id]
,hd.[first_service_date]
,hd.[last_service_date]

FROM [final].[mcaid_claim_header] AS hd
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Nonacute Inpatient Stay')
AND hed.[code_system] = 'UBTOB' 
AND hd.[type_of_bill_code] = hed.[code]
))

SELECT
 [id_mcaid]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
,1 AS [flag]
FROM [get_claims];
GO

/*
SELECT * FROM [stage].[v_perf_pcr_planned_exclusion];
*/
