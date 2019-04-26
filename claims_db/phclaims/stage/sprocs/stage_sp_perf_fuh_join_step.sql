
USE PHClaims;
GO

IF OBJECT_ID('[stage].[sp_perf_fuh_join_step]', 'P') IS NOT NULL
DROP PROCEDURE [stage].[sp_perf_fuh_join_step];
GO
CREATE PROCEDURE [stage].[sp_perf_fuh_join_step]
 @measurement_start_date DATE
,@measurement_end_date DATE
,@age INT
,@dx_value_set_name VARCHAR(100)
,@exclusion_value_set_name VARCHAR(100)
AS
SET NOCOUNT ON;
DECLARE @SQL NVARCHAR(MAX) = '';

BEGIN
SET @SQL = @SQL + N'

IF OBJECT_ID(''tempdb..#index_stays'', ''U'') IS NOT NULL
DROP TABLE #index_stays;
SELECT 
--TOP(100)
 b.year_month
,a.*
--If index stay occurs on 1st of month, then 31-day follow-up period contained within calendar month
,CASE WHEN DAY([to_date]) = 1 AND MONTH([to_date]) IN (1, 3, 5, 7, 8, 10, 12) THEN 1 ELSE 0 END AS [need_1_month_coverage]

INTO #index_stays

FROM [stage].[fn_perf_fuh_inpatient_index_stay_exclusion](''' 
+ CAST(@measurement_start_date AS VARCHAR(200)) + ''', ''' 
+ CAST(@measurement_end_date AS VARCHAR(200)) + ''', ' 
+ CAST(@age AS VARCHAR(200)) + ', ''' 
+ CAST(@dx_value_set_name AS VARCHAR(200)) + ''', '''
+ CAST(@exclusion_value_set_name AS VARCHAR(200)) + ''') AS a
INNER JOIN [ref].[perf_year_month] AS b
ON a.[from_date] BETWEEN b.[beg_month] AND b.[end_month]

WHERE 1 = 1
/* 
Discharges after the index stay are flagged by 
[stage].[fn_perf_fuh_inpatient_index_stay_exclusion]
EXCLUDE BELOW
Exclude discharges followed by readmission or direct transfer to a nonacute 
inpatient care setting within the 30-day follow-up period, regardless of 
principal diagnosis for the readmission.
Exclude discharges followed by readmission or direct transfer to an acute 
inpatient care setting within the 30-day follow-up period if the principal 
diagnosis was for non-mental health (any principal diagnosis code other than 
those included in the Mental Health Diagnosis Value Set).
*/
AND [inpatient_within_30_day] = 0;

CREATE CLUSTERED INDEX [idx_cl_#index_stays_id_from_date] ON #index_stays([id], [from_date]);
--SELECT * FROM #index_stays;

IF OBJECT_ID(''tempdb..#follow_up_visits'', ''U'') IS NOT NULL
DROP TABLE #follow_up_visits;
SELECT
--TOP(100)
 *
INTO #follow_up_visits
FROM [stage].[fn_perf_fuh_follow_up_visit]('''
+ CAST(@measurement_start_date AS VARCHAR(200)) + ''', ''' 
+ CAST(@measurement_end_date AS VARCHAR(200)) + ''');

CREATE CLUSTERED INDEX [idx_cl_#follow_up_visits_id_from_date] ON #follow_up_visits([id], [from_date]);
--SELECT * FROM #follow_up_visits;

/*
Join inpatient index stays with accompanying follow-up visits
*/
SELECT
 a.[year_month]
,a.[id]
,a.[age]
,a.[tcn]
,a.[from_date]
,a.[to_date]
,a.[flag] AS [inpatient_index_stay]
,a.[inpatient_within_30_day]
,a.[need_1_month_coverage]

/* Use aggregation function here because each index stay requires only one follow-up */
,MAX(ISNULL(b.[flag], 0)) AS [follow_up_7_day]
,MAX(ISNULL(c.[flag], 0)) AS [follow_up_30_day]

FROM #index_stays AS a

/*
THERE IS ONE IDIOSYNCRASY
Transitional care management services (TCM 14 Day Value Set), with or without a
telehealth modifier (Telehealth Modifier Value Set) meets criteria for only the
30-Day Follow-Up indicator.
*/
LEFT JOIN (SELECT * FROM #follow_up_visits WHERE [only_30_day_fu] = ''N'') AS b
ON a.[id] = b.[id]
AND b.[from_date] BETWEEN a.[to_date] AND DATEADD(DAY, 7, a.[to_date])

LEFT JOIN #follow_up_visits AS c
ON a.[id] = c.[id]
AND c.[from_date] BETWEEN a.[to_date] AND DATEADD(DAY, 30, a.[to_date])

GROUP BY
 a.[year_month]
,a.[id]
,a.[age]
,a.[tcn]
,a.[from_date]
,a.[to_date]
,a.[flag]
,a.[inpatient_within_30_day]
,a.[need_1_month_coverage];'
PRINT @SQL;
END

EXEC sp_executeSQL 
 @statement=@SQL
,@params=N'@measurement_start_date DATE, @measurement_end_date DATE, @age INT, @dx_value_set_name VARCHAR(100), @exclusion_value_set_name VARCHAR(100)'
,@measurement_start_date=@measurement_start_date
,@measurement_end_date=@measurement_end_date
,@age=@age
,@dx_value_set_name=@dx_value_set_name
,@exclusion_value_set_name=@exclusion_value_set_name;
GO

/*
IF OBJECT_ID('tempdb..#temp', 'U') IS NOT NULL
DROP TABLE #temp;
CREATE TABLE #temp
([year_month] INT
,[id] VARCHAR(200)
,[age] INT
,[tcn] VARCHAR(200)
,[from_date] DATE
,[to_date] DATE
,[inpatient_index_stay] INT
,[inpatient_within_30_day] INT
,[need_1_month_coverage] INT
,[follow_up_7_day] INT
,[follow_up_30_day] INT);

INSERT INTO #temp
EXEC [stage].[sp_perf_fuh_join_step]
 @measurement_start_date='2017-01-01'
,@measurement_end_date='2017-12-31'
,@age=6
,@dx_value_set_name='Mental Illness'
,@exclusion_value_set_name='Mental Health Diagnosis';

SELECT * FROM #temp;
*/