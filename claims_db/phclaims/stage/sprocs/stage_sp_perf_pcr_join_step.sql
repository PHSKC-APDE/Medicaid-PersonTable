
USE PHClaims;
GO

IF OBJECT_ID('[stage].[sp_perf_pcr_join_step]', 'P') IS NOT NULL
DROP PROCEDURE [stage].[sp_perf_pcr_join_step];
GO
CREATE PROCEDURE [stage].[sp_perf_pcr_join_step]
AS

SET NOCOUNT ON;
DECLARE @SQL NVARCHAR(MAX) = '';

BEGIN
SET @SQL = @SQL + N'

IF OBJECT_ID(''tempdb..#index_hospital_stay'') IS NOT NULL
DROP TABLE #index_hospital_stay;

WITH CTE AS
(
SELECT
 a.*
,CASE WHEN [episode_from_date] = [episode_to_date] THEN 1 ELSE 0 END AS [same_day_admit_discharge]

/*
Exclude hospital stays for the following reasons:
 (Pregnancy Value Set)
,(Perinatal Conditions Value Set)
Note: For hospital stays where there was an acute-to-acute direct transfer,
use BOTH the original stay and the direct transfer stay to identify exclusions in this step.
THUS: aggregate b.[flag] over a.[episode_id]
*/

,ISNULL(MAX(b.[flag]) OVER(PARTITION BY a.[id], a.[episode_id]), 0) AS [pregnancy_exclusion]

/*
Exclude hospital stays if there was a planned hospital stay within 30 days after the acute inpatient discharge.
 (Chemotherapy Value Set)
,(Rehabilitation Value Set)
,(Kidney Transplant Value Set)
,(Bone Marrow Transplant Value Set)
,(Organ Transplant Other Than Kidney Value Set)
,(Potentially Planned Procedures Value Set) WITHOUT (Acute Condition Value Set)
Note: For hospital stays where there was an acute-to-acute direct transfer,
use ONLY only the original stay to identify planned hospital stays
THUS: DO NOT aggregate c.[flag] over a.[episode_id]
*/

,ISNULL(c.[flag], 0) AS [planned_exclusion]

FROM [stage].[v_perf_pcr_inpatient_direct_transfer] AS a
LEFT JOIN [stage].[v_perf_pcr_pregnancy_exclusion] AS b
ON a.[tcn] = b.[tcn]
LEFT JOIN [stage].[v_perf_pcr_planned_exclusion] AS c
ON a.[tcn] = c.[tcn]
AND a.[stay_id] = 1
)

SELECT *
INTO #index_hospital_stay
FROM CTE

WHERE 1 = 1

/*
Step 1 & Step 2: Exclude acute-to-acute direct transfers.
Keep 1st [stay_id] within [episode_id]
*/
AND [stay_id] = 1

/*
Step 4: Exclude if member died during the stay
*/
AND [death_during_stay] = 0

/*
Step 3: Exclude hospital stays where the Index Admission Date is the same as 
the Index Discharge Date.
*/
AND [same_day_admit_discharge] = 0

/*
Step 4: Exclude pregnancy-related stays
*/
AND [pregnancy_exclusion] = 0;

CREATE CLUSTERED INDEX idx_cl_#index_hospital_stay ON #index_hospital_stay([id], [episode_from_date], [episode_to_date]);

/*
Step 5: Determine if there was a planned hospital stay within 30 days after the
acute inpatient discharge.

These are already flagged by [planned_exclusion] in #index_hospital_stay.

Join #index_hospital_stay to itself.
*/

WITH CTE AS
(
SELECT
 a.[id]
,a.[episode_id]
,a.[episode_from_date]
,a.[episode_to_date]
,b.[episode_from_date] AS [readmission_from_date]
,b.[episode_to_date] AS [readmission_to_date]
,DATEDIFF(DAY, a.[episode_to_date], b.[episode_from_date]) AS [date_diff]
,b.[planned_exclusion] AS [planned_readmission]
/*
Exclude any hospital stay as an Index Hospital Stay if the admission date of 
the FIRST stay within 30 days is a planned hospital stay.

Check whether b.[episode_from_date] is for planned hospital stay where [row_num] = 1.
*/
,ROW_NUMBER() OVER(PARTITION BY a.[id], a.[episode_id] ORDER BY b.[episode_from_date]) AS [row_num]
FROM #index_hospital_stay AS a
LEFT JOIN #index_hospital_stay AS b
ON a.[id] = b.[id]
AND b.[episode_from_date] BETWEEN DATEADD(DAY, 1, a.[episode_to_date]) AND DATEADD(DAY, 30, a.[episode_to_date])
)
SELECT
 [id]
,[episode_id]
,[episode_from_date]
,[episode_to_date]
,[readmission_from_date]
,[readmission_to_date]
,CASE WHEN [readmission_from_date] IS NOT NULL THEN 1 ELSE 0 END AS [readmission_flag]
,[date_diff]
,[planned_readmission]
FROM CTE
WHERE 1 = 1
AND [row_num] = 1
AND ([planned_readmission] IS NULL OR [planned_readmission] = 0);'
PRINT @SQL;
END

EXEC sp_executeSQL 
 @statement=@SQL;
GO
/*
EXEC [stage].[sp_perf_pcr_join_step];
GO
*/