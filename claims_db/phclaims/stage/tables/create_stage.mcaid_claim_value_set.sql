
USE PHClaims;
GO

IF OBJECT_ID('[stage].[mcaid_claim_value_set]') IS NOT NULL
DROP TABLE [stage].[mcaid_claim_value_set];
CREATE TABLE [stage].[mcaid_claim_value_set]
([value_set_group] VARCHAR(20) NULL
,[value_set_name] VARCHAR(100) NOT NULL
,[data_source_type] VARCHAR(50) NULL
,[sub_group] VARCHAR(50) NULL
,[code_set] VARCHAR(50) NOT NULL
,[primary_dx_only] CHAR(1) NULL
,[id_mcaid] VARCHAR(255) NOT NULL
,[claim_header_id] BIGINT NULL
,[service_date] DATE NULL)
ON [PRIMARY]
GO

/*
SELECT DISTINCT [code_set]
FROM [PHClaims].[ref].[rda_value_set]
ORDER BY [code_set];
*/

TRUNCATE TABLE [stage].[mcaid_claim_value_set];

INSERT INTO [stage].[mcaid_claim_value_set]
SELECT DISTINCT
--TOP(100)
 rda.[value_set_group]
,rda.[value_set_name]
,rda.[data_source_type]
,rda.[sub_group]
,rda.[code_set]
,NULL AS [primary_dx_only]
,pr.[id_mcaid]
,pr.[claim_header_id]
,pr.[first_service_date] AS [service_date]
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN [ref].[rda_value_set] AS rda
ON rda.[code_set] IN ('CPT', 'HCPCS', 'ICD10PCS', 'ICD9PCS')
AND pr.[procedure_code] = rda.[code];

INSERT INTO [stage].[mcaid_claim_value_set]
SELECT DISTINCT
--TOP(100)
 rda.[value_set_group]
,rda.[value_set_name]
,rda.[data_source_type]
,rda.[sub_group]
,rda.[code_set]
,NULL AS [primary_dx_only]
,hd.[id_mcaid]
,hd.[claim_header_id]
,hd.[first_service_date] AS [service_date]
FROM [final].[mcaid_claim_header] AS hd
INNER JOIN [ref].[rda_value_set] AS rda
ON rda.[code_set] IN ('DRG')
AND hd.[drvd_drg_code] = rda.[code];

INSERT INTO [stage].[mcaid_claim_value_set]
SELECT DISTINCT
--TOP(100)
 rda.[value_set_group]
,rda.[value_set_name]
,rda.[data_source_type]
,rda.[sub_group]
,rda.[code_set]
,'Y' AS [primary_dx_only]
,dx.[id_mcaid]
,dx.[claim_header_id]
,dx.[first_service_date] AS [service_date]
FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [ref].[rda_value_set] AS rda
ON rda.[code_set] IN ('ICD10CM')
AND dx.[icdcm_version] = 10
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = rda.[code];

INSERT INTO [stage].[mcaid_claim_value_set]
SELECT DISTINCT
--TOP(100)
 rda.[value_set_group]
,rda.[value_set_name]
,rda.[data_source_type]
,rda.[sub_group]
,rda.[code_set]
,'Y' AS [primary_dx_only]
,dx.[id_mcaid]
,dx.[claim_header_id]
,dx.[first_service_date] AS [service_date]
FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [ref].[rda_value_set] AS rda
ON rda.[code_set] IN ('ICD9CM')
AND dx.[icdcm_version] = 9
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = rda.[code];

INSERT INTO [stage].[mcaid_claim_value_set]
SELECT DISTINCT
--TOP(100)
 rda.[value_set_group]
,rda.[value_set_name]
,rda.[data_source_type]
,rda.[sub_group]
,rda.[code_set]
,'N' AS [primary_dx_only]
,dx.[id_mcaid]
,dx.[claim_header_id]
,dx.[first_service_date] AS [service_date]
FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [ref].[rda_value_set] AS rda
ON rda.[code_set] IN ('ICD10CM')
AND dx.[icdcm_version] = 10
--AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = rda.[code];

INSERT INTO [stage].[mcaid_claim_value_set]
SELECT DISTINCT
--TOP(100)
 rda.[value_set_group]
,rda.[value_set_name]
,rda.[data_source_type]
,rda.[sub_group]
,rda.[code_set]
,'N' AS [primary_dx_only]
,dx.[id_mcaid]
,dx.[claim_header_id]
,dx.[first_service_date] AS [service_date]
FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [ref].[rda_value_set] AS rda
ON rda.[code_set] IN ('ICD9CM')
AND dx.[icdcm_version] = 9
--AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = rda.[code];

INSERT INTO [stage].[mcaid_claim_value_set]
SELECT DISTINCT
--TOP(100)
 rda.[value_set_group]
,rda.[value_set_name]
,rda.[data_source_type]
,rda.[sub_group]
,rda.[code_set]
,NULL AS [primary_dx_only]
,ph.[id_mcaid]
,ph.[claim_header_id]
,ph.[rx_fill_date] AS [service_date]
FROM [final].[mcaid_claim_pharm] AS ph
INNER JOIN [ref].[rda_value_set] AS rda
ON rda.[code_set] IN ('NDC')
AND rda.[active] = 'Y'
AND ph.[ndc] = rda.[code];

INSERT INTO [stage].[mcaid_claim_value_set]
SELECT DISTINCT
--TOP(100)
 rda.[value_set_group]
,rda.[value_set_name]
,rda.[data_source_type]
,rda.[sub_group]
,rda.[code_set]
,NULL AS [primary_dx_only]
,ln.[id_mcaid]
,ln.[claim_header_id]
,ln.[first_service_date] AS [service_date]
FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [ref].[rda_value_set] AS rda
ON rda.[code_set] IN ('UBREV')
AND ln.[rev_code] = rda.[code];

--CREATE CLUSTERED COLUMNSTORE INDEX idx_ccs_mcaid_claim_value_set 
--ON [stage].[mcaid_claim_value_set];

/*
INSERT INTO [stage].[mcaid_claim_value_set]
SELECT DISTINCT
 hed.[version]
,hed.[value_set_name]
,hed.[code_system]
,'Y' AS [primary_dx_only]
,dx.[id_mcaid]
,dx.[claim_header_id]
,dx.[first_service_date]
,dx.[last_service_date]
FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [archive].[hedis_code_system] AS hed
ON hed.[value_set_name] IN 
('AOD Abuse and Dependence'
,'Mental Health Diagnosis'
,'Mental Illness')
AND hed.[code_system] = 'ICD10CM'
AND dx.[icdcm_version] = 10
-- Principal Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = hed.[code];

INSERT INTO [stage].[mcaid_claim_value_set]
SELECT DISTINCT
 hed.[version]
,hed.[value_set_name]
,hed.[code_system]
,'N' AS [primary_dx_only]
,ln.[id_mcaid]
,ln.[claim_header_id]
,ln.[first_service_date]
,ln.[last_service_date]
FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON hed.[value_set_name] IN 
('ED')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code];

INSERT INTO [stage].[mcaid_claim_value_set]
SELECT DISTINCT
 hed.[version]
,hed.[value_set_name]
,hed.[code_system]
,'N' AS [primary_dx_only]
,pr.[id_mcaid]
,pr.[claim_header_id]
,pr.[first_service_date]
,pr.[last_service_date]
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN [archive].[hedis_code_system] AS hed
ON hed.[value_set_name] IN 
('ED')
AND hed.[code_system] = 'CPT'
AND pr.[procedure_code] = hed.[code];
*/

/*
SELECT 
 [value_set_group]
,[value_set_name]
,[data_source_type]
,[sub_group]
,[code_set]
,[primary_dx_only]
,COUNT(*)
FROM [stage].[mcaid_claim_value_set]
GROUP BY
 [value_set_group]
,[value_set_name]
,[data_source_type]
,[sub_group]
,[code_set]
,[primary_dx_only]
ORDER BY
 [value_set_group]
,[value_set_name]
,[data_source_type]
,[sub_group]
,[code_set]
,[primary_dx_only];
*/