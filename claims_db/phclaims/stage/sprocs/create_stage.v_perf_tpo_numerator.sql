
/*
This view gets claims that meet the requirements for the DSHS RDA Substance Use
Disorder Treatment Penetration (Opioid) rate numerator.

Author: Philip Sylling
Created: 2019-05-22
Modified: 2019-08-09 | Point to new [final] analytic tables
Modified: 2019-11-15 | Add [value_set_group], [value_set_name], [data_source_type], [code_set] columns to view

Returns:
 [value_set_group]
,[value_set_name]
,[data_source_type]
,[sub_group]
,[code_set]
,[id_mcaid]
,[claim_header_id]
,[first_service_date], [FROM_SRVC_DATE]
,[flag], 1 for claim meeting numerator criteria
*/

USE [PHClaims];
GO

IF OBJECT_ID('[stage].[v_perf_tpo_numerator]', 'V') IS NOT NULL
DROP VIEW [stage].[v_perf_tpo_numerator];
GO
CREATE VIEW [stage].[v_perf_tpo_numerator]
AS
/*
SELECT [value_set_group]
      ,[value_set_name]
      ,[data_source_type]
	  ,[sub_group]
      ,[code_set]
	  ,[active]
      ,COUNT([code])
FROM [ref].[rda_value_set]
WHERE [value_set_group] = 'OUD'
GROUP BY [value_set_group], [value_set_name], [data_source_type], [sub_group], [code_set], [active]
ORDER BY [value_set_group], [value_set_name], [data_source_type], [sub_group], [code_set], [active];
*/

/*
Data elements required for numerator:
All eligible individuals receiving at least one qualifying medication in the 
measurement year, based on the NDC codes in OUD-Tx-Pen-Value-Set-2 or an 
outpatient encounter with procedure code H0020
(receipt of methadone opiate substitution treatment).
*/

SELECT 
 rda.[value_set_group]
,rda.[value_set_name]
,rda.[data_source_type]
,rda.[sub_group]
,rda.[code_set]
,ph.[id_mcaid]
,ph.[claim_header_id]
,ph.[rx_fill_date] AS [first_service_date]
,1 AS [flag]

FROM [final].[mcaid_claim_pharm] AS ph
INNER JOIN [ref].[rda_value_set] AS rda
ON rda.[value_set_group] = 'OUD'
AND rda.[value_set_name] = 'OUD-Tx-Pen-Value-Set-2'
AND rda.[code_set] = 'NDC'
AND rda.[active] = 'Y'
AND ph.[ndc] = rda.[code]

UNION

SELECT 
 rda.[value_set_group]
,rda.[value_set_name]
,rda.[data_source_type]
,rda.[sub_group]
,rda.[code_set]
,pr.[id_mcaid]
,pr.[claim_header_id]
,pr.[first_service_date]
,1 AS [flag]

FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN [ref].[rda_value_set] AS rda
ON rda.[value_set_group] = 'OUD'
AND rda.[value_set_name] = 'OUD-Tx-Pen-Receipt-of-MAT'
AND rda.[code_set] IN ('HCPCS')
AND pr.[procedure_code] = rda.[code]
GO

/*
-- 3,094,680
SELECT COUNT(*) FROM [stage].[v_perf_tpo_numerator];

SELECT TOP(100) * FROM [stage].[v_perf_tpo_numerator];
*/