
USE PHClaims;
GO

IF OBJECT_ID('[stage].[v_perf_tpm_numerator]', 'V') IS NOT NULL
DROP VIEW [stage].[v_perf_tpm_numerator];
GO
CREATE VIEW [stage].[v_perf_tpm_numerator]
AS
/*
SELECT [value_set_group]
      ,[value_set_name]
      ,[data_source_type]
      ,[code_set]
      ,COUNT([code])
FROM [ref].[rda_value_set]
GROUP BY [value_set_group], [value_set_name], [data_source_type], [code_set]
ORDER BY [value_set_group], [value_set_name], [data_source_type], [code_set];

SELECT 
 YEAR([from_date]) AS [year]
,MONTH([from_date]) AS [month]
,[dx_ver]
,COUNT(*)
FROM [PHClaims].[dbo].[mcaid_claim_header] AS hd
INNER JOIN [PHClaims].[dbo].[mcaid_claim_dx] AS dx
ON hd.[tcn] = dx.[tcn]
GROUP BY YEAR([from_date]), MONTH([from_date]), [dx_ver]
ORDER BY [dx_ver], YEAR([from_date]), MONTH([from_date]);
*/

/*
Receipt of an outpatient service with a procedure code in the MH-procedure-value-set
*/
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
--,ym.[year_month]
,1 AS [flag]

FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_proc] AS pr
ON hd.[tcn] = pr.[tcn]
INNER JOIN [ref].[rda_value_set] AS rda
ON rda.[value_set_name] = 'MH-procedure-value-set'
AND rda.[code_set] IN ('CPT', 'HCPCS')
AND pr.[pcode] = rda.[code]
--INNER JOIN [ref].[perf_year_month] AS ym
--ON hd.[from_date] BETWEEN ym.[beg_month] AND ym.[end_month]
--WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE hd.[from_date] BETWEEN CAST(DATEADD(YEAR, -1, @measurement_start_date) AS DATE) AND @measurement_end_date

UNION

/*
Receipt of an outpatient service with a servicing provider taxonomy code in the
MH-taxonomy-value-set AND primary diagnosis code in the MH-Dx-value-set
PROVIDER TAXONOMY CODE NOT AVAILABLE IN MEDICAID
*/

/*
Receipt of an outpatient service with a procedure code in the 
MH-procedure-with-Dx-value-set AND primary diagnosis code in the 
MH-Dx-value-set
*/
SELECT 
 [id]
,[tcn]
,[from_date]
--,[year_month]
,1 AS [flag]
FROM
(
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
--,ym.[year_month]
,1 AS [flag]

FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_proc] AS pr
ON hd.[tcn] = pr.[tcn]
INNER JOIN [ref].[rda_value_set] AS rda
ON rda.[value_set_name] = 'MH-procedure-with-Dx-value-set'
AND rda.[code_set] IN ('CPT', 'HCPCS')
AND pr.[pcode] = rda.[code]
--INNER JOIN [ref].[perf_year_month] AS ym
--ON hd.[from_date] BETWEEN ym.[beg_month] AND ym.[end_month]
WHERE hd.[from_date] >= '2015-10-01'
--WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE hd.[from_date] BETWEEN CAST(DATEADD(YEAR, -1, @measurement_start_date) AS DATE) AND @measurement_end_date

INTERSECT

SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
--,ym.[year_month]
,1 AS [flag]

FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_dx] AS dx
ON hd.[tcn] = dx.[tcn]
-- Primary Diagnosis
AND dx.[dx_number] = 1
INNER JOIN [ref].[rda_value_set] AS rda
ON [value_set_name] = 'MH-Dx-value-set'
AND rda.[code_set] = 'ICD10CM'
AND dx.[dx_ver] = 10 
AND dx.[dx_norm] = rda.[code]
--INNER JOIN [ref].[perf_year_month] AS ym
--ON hd.[from_date] BETWEEN ym.[beg_month] AND ym.[end_month]
WHERE hd.[from_date] >= '2015-10-01'
--WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE hd.[from_date] BETWEEN CAST(DATEADD(YEAR, -1, @measurement_start_date) AS DATE) AND @measurement_end_date
) AS MH_procedure_with_Dx_value_set_ICD10CM

UNION

SELECT 
 [id]
,[tcn]
,[from_date]
--,[year_month]
,1 AS [flag]
FROM
(
SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
--,ym.[year_month]
,1 AS [flag]

FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_proc] AS pr
ON hd.[tcn] = pr.[tcn]
INNER JOIN [ref].[rda_value_set] AS rda
ON rda.[value_set_name] = 'MH-procedure-with-Dx-value-set'
AND rda.[code_set] IN ('CPT', 'HCPCS')
AND pr.[pcode] = rda.[code]
--INNER JOIN [ref].[perf_year_month] AS ym
--ON hd.[from_date] BETWEEN ym.[beg_month] AND ym.[end_month]
WHERE hd.[from_date] < '2015-10-01'
--WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE hd.[from_date] BETWEEN CAST(DATEADD(YEAR, -1, @measurement_start_date) AS DATE) AND @measurement_end_date

INTERSECT

SELECT 
 hd.[id]
,hd.[tcn]
,hd.[from_date]
--,ym.[year_month]
,1 AS [flag]

FROM [dbo].[mcaid_claim_header] AS hd
INNER JOIN [dbo].[mcaid_claim_dx] AS dx
ON hd.[tcn] = dx.[tcn]
-- Primary Diagnosis
AND dx.[dx_number] = 1
INNER JOIN [ref].[rda_value_set] AS rda
ON [value_set_name] = 'MH-Dx-value-set'
AND rda.[code_set] = 'ICD9CM'
AND dx.[dx_ver] = 9 
AND dx.[dx_norm] = rda.[code]
--INNER JOIN [ref].[perf_year_month] AS ym
--ON hd.[from_date] BETWEEN ym.[beg_month] AND ym.[end_month]
WHERE hd.[from_date] < '2015-10-01'
--WHERE hd.[from_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE hd.[from_date] BETWEEN CAST(DATEADD(YEAR, -1, @measurement_start_date) AS DATE) AND @measurement_end_date
) AS MH_procedure_with_Dx_value_set_ICD9CM;
GO

/*
-- 5,965,208
SELECT COUNT(*) FROM [stage].[v_perf_tpm_numerator];
*/