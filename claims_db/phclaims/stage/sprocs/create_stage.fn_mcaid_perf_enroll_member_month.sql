
USE [PHClaims];
GO

IF OBJECT_ID('[stage].[fn_mcaid_perf_enroll_member_month]', 'IF') IS NOT NULL
DROP FUNCTION [stage].[fn_mcaid_perf_enroll_member_month];
GO
CREATE FUNCTION [stage].[fn_mcaid_perf_enroll_member_month]
(@start_date_int INT = 201701
,@end_date_int INT = 201712)
RETURNS TABLE 
AS
RETURN
/*
1. Create Age at beginning of month and end of month. This would correspond to age
at Beginning of Measurement Year or End of Measurement Year (typical)
2. Create enrollment gaps as ZERO rows by the following join
[stage].[mcaid_elig_demo] CROSS JOIN [ref].[perf_year_month] LEFT JOIN [stage].[mcaid_perf_elig_member_month]
The ZERO rows are used to track changing enrollment threshold over time.
*/

SELECT 
 b.[year_month]
,b.[month]
--,b.[beg_month]
--,b.[end_month]
,a.[id_mcaid]
,a.[dob]

--,DATEDIFF(YEAR, a.[dob], b.[beg_month]) - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, a.[dob], b.[beg_month]), a.[dob]) > b.[beg_month] THEN 1 ELSE 0 END AS [beg_month_age]
,DATEDIFF(YEAR, a.[dob], b.[end_month]) - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, a.[dob], b.[end_month]), a.[dob]) > b.[end_month] THEN 1 ELSE 0 END AS [end_month_age]
,DATEDIFF(MONTH, a.[dob], b.[end_month]) - CASE WHEN DATEADD(MONTH, DATEDIFF(MONTH, a.[dob], b.[end_month]), a.[dob]) > b.[end_month] THEN 1 ELSE 0 END AS [age_in_months]

,CASE WHEN c.[MEDICAID_RECIPIENT_ID] IS NOT NULL THEN 1 ELSE 0 END AS [enrolled_any]
-- Use BSP Group Full Benefit Methodology from HCA/Providence CORE
,CASE WHEN d.[full_benefit] = 'Y' THEN 1 ELSE 0 END AS [full_benefit]
,CASE WHEN c.[DUAL_ELIG] = 'Y' THEN 1 ELSE 0 END AS [dual]
,CASE WHEN c.[TPL_FULL_FLAG] = 'Y' THEN 1 ELSE 0 END AS [tpl]
,ISNULL(e.[hospice_flag], 0) AS [hospice]
,CASE WHEN c.[MEDICAID_RECIPIENT_ID] IS NOT NULL AND d.[full_benefit] = 'Y' AND c.[DUAL_ELIG] = 'N' AND c.[TPL_FULL_FLAG] = ' ' THEN 1 ELSE 0 END AS [full_criteria]
--,CASE WHEN c.[MEDICAID_RECIPIENT_ID] IS NOT NULL AND d.[full_benefit] = 'Y' AND c.[DUAL_ELIG] = 'N' THEN 1 ELSE 0 END AS [full_criteria_without_tpl]
--,CASE WHEN [COVERAGE_TYPE_IND] = 'FFS' THEN 'FFS' ELSE [MC_PRVDR_NAME] END AS [mco_or_ffs]
,c.[RSDNTL_POSTAL_CODE] AS [zip_code]
,b.[row_num]

FROM [final].[mcaid_elig_demo] AS a

CROSS JOIN 
(
SELECT *, ROW_NUMBER() OVER(ORDER BY [year_month]) AS [row_num]
FROM [ref].[perf_year_month]
WHERE [year_month] BETWEEN @start_date_int AND @end_date_int
--WHERE [year_month] BETWEEN 201701 AND 201712
) AS b

LEFT JOIN [stage].[mcaid_perf_elig_member_month] AS c
ON a.[id_mcaid] = c.[MEDICAID_RECIPIENT_ID]
AND b.[year_month] = c.[CLNDR_YEAR_MNTH]

LEFT JOIN [ref].[mcaid_rac_code] AS d
ON c.[RPRTBL_RAC_CODE] = d.[rac_code]

LEFT JOIN [stage].[v_mcaid_perf_hospice_member_month] AS e
ON a.[id_mcaid] = e.[id_mcaid]
AND b.[year_month] = e.[year_month];

GO

/*
IF OBJECT_ID('tempdb..#temp', 'U') IS NOT NULL
DROP TABLE #temp;
SELECT *
INTO #temp
FROM [stage].[fn_mcaid_perf_enroll_member_month](201901, 201906);

SELECT TOP 100 *
FROM #temp;
*/