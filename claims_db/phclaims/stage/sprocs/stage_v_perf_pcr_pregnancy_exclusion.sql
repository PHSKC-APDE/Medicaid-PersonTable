
USE PHClaims;
GO

IF OBJECT_ID('[stage].[v_perf_pcr_pregnancy_exclusion]', 'V') IS NOT NULL
DROP VIEW [stage].[v_perf_pcr_pregnancy_exclusion];
GO
CREATE VIEW [stage].[v_perf_pcr_pregnancy_exclusion]
AS
/*
SELECT [value_set_name]
      ,[code_system]
      ,COUNT([code])
FROM [ref].[hedis_code_system]
WHERE [value_set_name] IN
('Inpatient Stay'
,'Nonacute Inpatient Stay'
,'Pregnancy'
,'Perinatal Conditions')
GROUP BY [value_set_name], [code_system]
ORDER BY [code_system], [value_set_name];
*/
WITH [get_claims] AS
(
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]

FROM [dbo].[mcaid_claim_header] AS hd

INNER JOIN [dbo].[mcaid_claim_line] AS ln
ON hd.[tcn] = ln.[tcn]

INNER JOIN [dbo].[mcaid_claim_dx] AS dx
ON hd.[tcn] = dx.[tcn]
AND dx.[dx_number] = 1
AND dx.[dx_ver] = 10

INNER JOIN [ref].[hedis_code_system] AS hed_rev
ON hed_rev.[value_set_name] IN 
('Inpatient Stay')
AND hed_rev.[code_system] = 'UBREV'
AND ln.[rcode] = hed_rev.[code]

INNER JOIN [ref].[hedis_code_system] AS hed_dx
ON hed_dx.[value_set_name] IN 
('Perinatal Conditions'
,'Pregnancy')
AND hed_dx.[code_system] = 'ICD10CM' 
AND dx.[dx_norm] = hed_dx.[code]

EXCEPT

(
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]

FROM [dbo].[mcaid_claim_header] AS hd

INNER JOIN [dbo].[mcaid_claim_line] AS ln
ON hd.[tcn] = ln.[tcn]

INNER JOIN [ref].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Nonacute Inpatient Stay')
AND hed.[code_system] = 'UBREV'
AND ln.[rcode] = hed.[code]

UNION

SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
,hd.[to_date]

FROM [dbo].[mcaid_claim_header] AS hd

INNER JOIN [ref].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Nonacute Inpatient Stay')
AND hed.[code_system] = 'UBTOB' 
AND hd.[bill_type_code] = hed.[code]
))

SELECT
 [id]
,[tcn]
,[from_date]
,[to_date]
,1 AS [flag]
FROM [get_claims];
GO

/*
SELECT * FROM [stage].[v_perf_pcr_pregnancy_exclusion];
*/