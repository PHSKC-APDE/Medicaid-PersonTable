
USE PHClaims;
GO

IF OBJECT_ID('[stage].[v_perf_ah_medicine_surgery]', 'V') IS NOT NULL
DROP VIEW [stage].[v_perf_ah_medicine_surgery];
GO
CREATE VIEW [stage].[v_perf_ah_medicine_surgery]
AS
/*
SELECT [value_set_name]
      ,[code_system]
      ,COUNT([code])
FROM [ref].[hedis_code_system]
WHERE [value_set_name] IN
('Medicine MS-DRG'
,'Surgery'
,'Surgery MS-DRG')
GROUP BY [value_set_name], [code_system]
ORDER BY [value_set_name], [code_system];
*/
WITH [get_claims] AS
( 
SELECT 
 hd.[id_mcaid]
,hd.[claim_header_id]
,hed.[value_set_name]
,1 AS [flag]

FROM [final].[mcaid_claim_header] AS hd
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Medicine MS-DRG'
,'Surgery MS-DRG')
AND hed.[code_system] = 'MSDRG' 
AND hd.[drvd_drg_code] = hed.[code]

UNION

SELECT 
 ln.[id_mcaid]
,ln.[claim_header_id]
,hed.[value_set_name]
,1 AS [flag]

FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Surgery')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code]
)

SELECT 
 [id_mcaid]
,[claim_header_id]
,[Medicine MS-DRG]
,[Surgery]
,[Surgery MS-DRG]
FROM [get_claims]
PIVOT(MAX([flag]) FOR [value_set_name] IN
(
 [Medicine MS-DRG]
,[Surgery]
,[Surgery MS-DRG]
)) AS P;
GO

/*
SELECT COUNT(*) FROM [stage].[v_perf_ah_medicine_surgery];

SELECT
 [Medicine MS-DRG]
,[Surgery]
,[Surgery MS-DRG]
,COUNT(*)
FROM [stage].[v_perf_ah_medicine_surgery]
GROUP BY 
 [Medicine MS-DRG]
,[Surgery]
,[Surgery MS-DRG]
ORDER BY
 [Medicine MS-DRG]
,[Surgery]
,[Surgery MS-DRG];
*/