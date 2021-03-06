
/*
QA HEDIS reference tables
Philip Sylling
2019-07-17
*/

/*
Compare row counts between source spreadsheets and final tables
*/

-- 76
SELECT COUNT(*)
FROM
(
SELECT 
 CASE WHEN [Measure.ID] = 'GG' AND [Measure.Name] = 'CPT Code Modifiers' THEN 'GG_1'
      WHEN [Measure.ID] = 'GG' AND [Measure.Name] = 'Identifying Events/Diagnoses Using Laboratory or Pharmacy Data' THEN 'GG_2'
      WHEN [Measure.ID] = 'GG' AND [Measure.Name] = 'Members in Hospice' THEN 'GG_3'
      WHEN [Measure.ID] = 'PCR2020' AND [Measure.Name] = 'Plan All-Cause Readmissions 2020 Version' THEN 'PCR20'
	  ELSE [Measure.ID]
 END AS [Measure.ID]
FROM [tmp].[HEDIS_2019_Volume_2_VSD_11_05_2018-2.xlsx]
UNION
SELECT [Measure.ID] 
FROM [tmp].[HEDIS_2019_NDC_MLD_Directory-2.xlsx]
) AS a;
-- 76
SELECT COUNT(*) FROM [ref].[hedis_measure];

-- 364
SELECT COUNT(DISTINCT [Value.Set.Name]) FROM [tmp].[HEDIS_2019_Volume_2_VSD_11_05_2018-2.xlsx];
-- 364
SELECT COUNT(DISTINCT [value_set_name]) FROM [ref].[hedis_value_set];

-- 42
SELECT COUNT(DISTINCT [Medication.List.Name]) FROM [tmp].[HEDIS_2019_NDC_MLD_Directory-2.xlsx];
-- 42
SELECT COUNT(DISTINCT [medication_list_name]) FROM [ref].[hedis_medication_list];

-- 66,146
SELECT COUNT(*) FROM [tmp].[HEDIS_2019_NDC_MLD_Directory-3.xlsx];
-- 66,146
SELECT COUNT(*) FROM [ref].[hedis_ndc_code];

-- 119,910
SELECT COUNT(*) FROM [tmp].[HEDIS_2019_Volume_2_VSD_11_05_2018-3.xlsx];
-- 119,910
SELECT COUNT(*) FROM [ref].[hedis_code_system];

