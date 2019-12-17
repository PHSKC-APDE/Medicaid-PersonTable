
USE [PHClaims];
GO

IF OBJECT_ID('[stage].[sp_perf_elig_member_month]','P') IS NOT NULL
DROP PROCEDURE [stage].[sp_perf_elig_member_month];
GO
CREATE PROCEDURE [stage].[sp_perf_elig_member_month]
AS
SET NOCOUNT ON;

BEGIN

-- Create slim table for temporary work
IF OBJECT_ID('tempdb..#temp') IS NOT NULL
DROP TABLE #temp;
SELECT
 [CLNDR_YEAR_MNTH]
,[MEDICAID_RECIPIENT_ID]
,[RPRTBL_RAC_CODE]
,[FROM_DATE]
,[TO_DATE]
,[COVERAGE_TYPE_IND]
,CASE WHEN ([COVERAGE_TYPE_IND] = 'MC' AND [MC_PRVDR_NAME] = 'Amerigroup Washington Inc') THEN 'AGP'
      WHEN ([COVERAGE_TYPE_IND] = 'MC' AND [MC_PRVDR_NAME] = 'Community Health Plan of Washington') THEN 'CHP'
	  WHEN ([COVERAGE_TYPE_IND] = 'MC' AND [MC_PRVDR_NAME] IN ('Coordinated Care Corporation', 'Coordinated Care of Washington')) THEN 'CCW'
	  WHEN ([COVERAGE_TYPE_IND] = 'MC' AND [MC_PRVDR_NAME] = 'Molina Healthcare of Washington Inc') THEN 'MHW'
	  WHEN ([COVERAGE_TYPE_IND] = 'MC' AND [MC_PRVDR_NAME] = 'United Health Care Community Plan') THEN 'UHC'
	  WHEN ([COVERAGE_TYPE_IND] = 'MC') THEN NULL
      ELSE NULL END AS [MC_PRVDR_NAME]
,[DUAL_ELIG]
,[TPL_FULL_FLAG]
,[RSDNTL_POSTAL_CODE]
INTO #temp
FROM [stage].[mcaid_elig];

CREATE CLUSTERED INDEX [idx_cl_#temp] 
ON #temp([MEDICAID_RECIPIENT_ID], [CLNDR_YEAR_MNTH]);

/*
-- ZERO ROWS
-- THERE ARE NO MEMBER MONTHS WITH CONFLICTING DUAL_ELIG, TPL_FULL_FLAG, OR full_benefit
-- SO THE MEMBER-MONTH TABLE ABOVE (#temp) CAN BE COLLAPSED ARBITRARILY
SELECT *
FROM
(
SELECT
 [CLNDR_YEAR_MNTH]
,[MEDICAID_RECIPIENT_ID]
,MIN([RPRTBL_RAC_CODE]) AS [MIN_RPRTBL_RAC_CODE]
,MAX([RPRTBL_RAC_CODE]) AS [MAX_RPRTBL_RAC_CODE]
,MIN([COVERAGE_TYPE_IND]) AS [MIN_COVERAGE_TYPE_IND]
,MAX([COVERAGE_TYPE_IND]) AS [MAX_COVERAGE_TYPE_IND]
,MIN([MC_PRVDR_NAME]) AS [MIN_MC_PRVDR_NAME]
,MAX([MC_PRVDR_NAME]) AS [MAX_MC_PRVDR_NAME]
,MIN([DUAL_ELIG]) AS [MIN_DUAL_ELIG]
,MAX([DUAL_ELIG]) AS [MAX_DUAL_ELIG]
,MIN([TPL_FULL_FLAG]) AS [MIN_TPL_FULL_FLAG]
,MAX([TPL_FULL_FLAG]) AS [MAX_TPL_FULL_FLAG]
,MIN([RSDNTL_POSTAL_CODE]) AS [MIN_RSDNTL_POSTAL_CODE]
,MAX([RSDNTL_POSTAL_CODE]) AS [MAX_RSDNTL_POSTAL_CODE]
--,MIN(CASE WHEN b.[full_benefit] IS NULL THEN 'N' ELSE b.[full_benefit] END) AS [MIN_full_benefit]
--,MAX(CASE WHEN b.[full_benefit] IS NULL THEN 'N' ELSE b.[full_benefit] END) AS [MAX_full_benefit]
FROM #temp AS a
LEFT JOIN [ref].[mcaid_rac_code] AS b
ON a.[RPRTBL_RAC_CODE] = b.[rac_code]
GROUP BY [CLNDR_YEAR_MNTH], [MEDICAID_RECIPIENT_ID]
) AS a
WHERE 
[MIN_RPRTBL_RAC_CODE] <> [MAX_RPRTBL_RAC_CODE]
OR [MIN_COVERAGE_TYPE_IND] <> [MAX_COVERAGE_TYPE_IND]
OR [MIN_MC_PRVDR_NAME] <> [MAX_MC_PRVDR_NAME]
OR [MIN_DUAL_ELIG] <> [MAX_DUAL_ELIG]
OR [MIN_TPL_FULL_FLAG] <> [MAX_TPL_FULL_FLAG]
OR [MIN_RSDNTL_POSTAL_CODE] <> [MAX_RSDNTL_POSTAL_CODE]
*/

IF OBJECT_ID('[stage].[perf_elig_member_month]', 'U') IS NOT NULL
DROP TABLE [stage].[perf_elig_member_month];

WITH CTE AS
(
SELECT
 [CLNDR_YEAR_MNTH]
,[MEDICAID_RECIPIENT_ID]
,[RPRTBL_RAC_CODE]
,[FROM_DATE]
,[TO_DATE]
,[COVERAGE_TYPE_IND]
,[MC_PRVDR_NAME]
,[DUAL_ELIG]
,[TPL_FULL_FLAG]
,[RSDNTL_POSTAL_CODE]
,ROW_NUMBER() OVER(PARTITION BY [MEDICAID_RECIPIENT_ID], [CLNDR_YEAR_MNTH] 
                   ORDER BY DATEDIFF(DAY, [FROM_DATE], [TO_DATE]) DESC) AS [row_num]
FROM #temp AS a
INNER JOIN [ref].[apcd_zip] AS b
ON a.[RSDNTL_POSTAL_CODE] = b.[zip_code]
WHERE b.[state] = 'WA' AND b.[county_name] = 'King'
)

SELECT
 [CLNDR_YEAR_MNTH]
,[MEDICAID_RECIPIENT_ID]
,[RPRTBL_RAC_CODE]
,[FROM_DATE]
,[TO_DATE]
,[COVERAGE_TYPE_IND]
,[MC_PRVDR_NAME]
,[DUAL_ELIG]
,[TPL_FULL_FLAG]
,[RSDNTL_POSTAL_CODE]
,CAST(GETDATE() AS DATE) AS [load_date]

INTO [stage].[perf_elig_member_month]
FROM CTE
WHERE 1 = 1
AND [row_num] = 1;

ALTER TABLE [stage].[perf_elig_member_month] ALTER COLUMN [CLNDR_YEAR_MNTH] INT NOT NULL;
ALTER TABLE [stage].[perf_elig_member_month] ALTER COLUMN [MEDICAID_RECIPIENT_ID] VARCHAR(200) NOT NULL;
ALTER TABLE [stage].[perf_elig_member_month] 
ADD CONSTRAINT [pk_perf_elig_member_month_MEDICAID_RECIPIENT_ID_CLNDR_YEAR_MNTH] PRIMARY KEY ([MEDICAID_RECIPIENT_ID], [CLNDR_YEAR_MNTH]);
END
GO

--EXEC [stage].[sp_perf_elig_member_month];

/*
SELECT 
 NumRows
,COUNT(*)
FROM
(
SELECT 
 [MEDICAID_RECIPIENT_ID]
,[CLNDR_YEAR_MNTH]
,COUNT(*) AS NumRows
FROM [stage].[perf_elig_member_month]
GROUP BY [MEDICAID_RECIPIENT_ID], [CLNDR_YEAR_MNTH]
) AS SubQuery
GROUP BY NumRows
ORDER BY NumRows;
*/