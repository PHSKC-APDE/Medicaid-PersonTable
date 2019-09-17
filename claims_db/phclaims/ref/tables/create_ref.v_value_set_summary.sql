
USE PHClaims;
GO

IF OBJECT_ID('[ref].[v_value_set_summary]', 'V') IS NOT NULL
DROP VIEW [ref].[v_value_set_summary];
GO
CREATE VIEW [ref].[v_value_set_summary] AS
SELECT TOP(1000)
 [value_set_group]
,[value_set_name]
,[data_source_type]
,[sub_group]
,[code_set]
,[active]
,COUNT([code]) AS [num_code]

FROM [ref].[rda_value_set]
GROUP BY
 [value_set_group]
,[value_set_name]
,[data_source_type]
,[sub_group]
,[code_set]
,[active]
ORDER BY
 [value_set_group]
,[value_set_name]
,[data_source_type]
,[sub_group]
,[code_set]
,[active];
GO

SELECT * FROM [ref].[v_value_set_summary];
