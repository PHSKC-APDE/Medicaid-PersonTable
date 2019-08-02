
USE [PHClaims]
GO

IF OBJECT_ID('[stage].[perf_staging]') IS NOT NULL
DROP TABLE [stage].[perf_staging];
CREATE TABLE [stage].[perf_staging]
([year_month] INT NOT NULL
,[id_mcaid] VARCHAR(255) NOT NULL
,[measure_id] SMALLINT NOT NULL
,[num_denom] CHAR(1) NOT NULL
,[measure_value] INT NOT NULL
,[load_date] DATE NOT NULL
) ON [PRIMARY];
GO
