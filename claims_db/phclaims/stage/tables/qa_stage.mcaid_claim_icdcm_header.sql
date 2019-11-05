
SELECT * FROM [PHClaims].[metadata].[qa_mcaid]

use [PHClaims];
go

/*
stage.mcaid_claim_header
stage.mcaid_claim_icdcm_header
stage.mcaid_claim_line
stage.mcaid_claim_pharm
stage.mcaid_claim_procedure

SELECT * FROM [PHClaims].[metadata].[qa_mcaid];
*/

delete from [metadata].[qa_mcaid] 
where [table_name] = 'stage.mcaid_claim_icdcm_header';

--All members should be in elig_demo and table
select count(a.id_mcaid) as id_dcount
from [stage].[mcaid_claim_icdcm_header] as a
where not exists
(
select 1 
from [stage].[mcaid_elig][stage].[mcaid_elig_demo] as b
where a.id_mcaid = b.id_mcaid
);
go

declare @last_run as datetime = (select max(last_run) from [stage].[mcaid_claim_icdcm_header]);
insert into [metadata].[qa_mcaid]
select 
 NULL
,@last_run
,'stage.mcaid_claim_icdcm_header'
,'mcaid_elig_demo.id_mcaid check'
,'PASS'
,getdate()
,'All members in mcaid_claim_icdcm_header are in mcaid_elig_demo';

--All members should be in elig_timevar table
select count(a.id_mcaid) as id_dcount
from [stage].[mcaid_claim_icdcm_header] as a
where not exists
(
select 1 
--from [final].[mcaid_elig_timevar] as b
from [stage].[mcaid_elig] as b
--where a.id_mcaid = b.id_mcaid
where a.id_mcaid = b.MEDICAID_RECIPIENT_ID
);
go

declare @last_run as datetime = (select max(last_run) from [stage].[mcaid_claim_icdcm_header]);
insert into [metadata].[qa_mcaid]
select 
 NULL
,@last_run
,'stage.mcaid_claim_icdcm_header'
--,'mcaid_elig_time_var.id_mcaid check'
,'mcaid_elig.MEDICAID_RECIPIENT_ID check'
,'PASS'
,getdate()
--,'All members in mcaid_claim_icdcm_header are in mcaid_elig_time_var';
,'All members in mcaid_claim_icdcm_header are in mcaid_elig';

--Check that length of all ICD-9-CM is 5
select min(len(icdcm_norm)) as min_len, max(len(icdcm_norm)) as max_len
from [stage].[mcaid_claim_icdcm_header]
where icdcm_version = 9;
go

declare @last_run as datetime = (select max(last_run) from [stage].[mcaid_claim_icdcm_header]);
insert into [metadata].[qa_mcaid]
select 
 NULL
,@last_run
,'stage.mcaid_claim_icdcm_header'
,'Check length of ICD-9-CM'
,'PASS'
,getdate()
,'Min/Max Length of icdcm_norm = 5';

-- Check that ICD-10-CM length in (3,4,5,6,7)
select count(*)
from [stage].[mcaid_claim_icdcm_header]
where [icdcm_version] = 10
and len([icdcm_norm]) not in (3,4,5,6,7);
go

declare @last_run as datetime = (select max(last_run) from [stage].[mcaid_claim_icdcm_header]);
insert into [metadata].[qa_mcaid]
select 
 NULL
,@last_run
,'stage.mcaid_claim_icdcm_header'
,'Check length of ICD-10-CM'
,'PASS'
,getdate()
,'All lengths in (3,4,5,6,7)';

--Check that icdcm_number within ('01','02','03','04','05','06','07','08','09','10','11','12','admit')
select count([icdcm_number])
from [stage].[mcaid_claim_icdcm_header]
where [icdcm_number] not in 
('01'
,'02'
,'03'
,'04'
,'05'
,'06'
,'07'
,'08'
,'09'
,'10'
,'11'
,'12'
,'admit');
go

declare @last_run as datetime = (select max(last_run) from [stage].[mcaid_claim_icdcm_header]);
insert into [metadata].[qa_mcaid]
select 
 NULL
,@last_run
,'stage.mcaid_claim_icdcm_header'
,'Check values of [icdcm_number]'
,'PASS'
,getdate()
,'All values in (01,02,03,04,05,06,07,08,09,10,11,12,admit)';

--Count diagnosis codes that do not join to ICD-CM reference table
select distinct 
 [icdcm_version]
,[icdcm_norm]
from [stage].[mcaid_claim_icdcm_header] as a
where not exists
(
select 1
from [ref].[dx_lookup] as b
where a.[icdcm_version] = b.[dx_ver] and a.[icdcm_norm] = b.[dx]
);
go

declare @last_run as datetime = (select max(last_run) from [stage].[mcaid_claim_icdcm_header]);
insert into [metadata].[qa_mcaid]
select 
 NULL
,@last_run
,'stage.mcaid_claim_icdcm_header'
,'icdcm_norm foreign key check'
,'FAIL'
,getdate()
,'22 dx codes not in [ref].[dx_lookup]';

--Compare number of people with claim_header table
select
 (select count(distinct id_mcaid) as id_dcount
  from [stage].[mcaid_claim_icdcm_header])
,(select count(distinct id_mcaid) as id_dcount
  from [final].[mcaid_claim_header])
,cast((select count(distinct id_mcaid) as id_dcount
  from [stage].[mcaid_claim_icdcm_header]) as numeric) /
 (select count(distinct id_mcaid) as id_dcount
  from [final].[mcaid_claim_header]);
go

declare @last_run as datetime = (select max(last_run) from [stage].[mcaid_claim_icdcm_header]);
insert into [metadata].[qa_mcaid]
select 
 NULL
,@last_run
,'stage.mcaid_claim_icdcm_header'
,'Compare icdcm_header to header'
,'PASS'
,getdate()
,'97.4% of people in icdcm_header are in header';

-- Compare number of dx codes in current vs. prior analytic tables
WITH [final] AS
(
SELECT
 YEAR([first_service_date]) AS [claim_year]
,COUNT(*) AS [prior_num_dx]
FROM [final].[mcaid_claim_icdcm_header] AS a
GROUP BY YEAR([first_service_date])
),

[stage] AS
(
SELECT
 YEAR([first_service_date]) AS [claim_year]
,COUNT(*) AS [current_num_dx]
FROM [stage].[mcaid_claim_icdcm_header] AS a
GROUP BY YEAR([first_service_date])
)

SELECT
 COALESCE(a.[claim_year], b.[claim_year]) AS [claim_year]
,[prior_num_dx]
,[current_num_dx]
,CAST([current_num_dx] AS NUMERIC) / [prior_num_dx] AS [pct_change]
FROM [final] AS a
FULL JOIN [stage] AS b
ON a.[claim_year] = b.[claim_year]
ORDER BY [claim_year];
go

declare @last_run as datetime = (select max(last_run) from [stage].[mcaid_claim_icdcm_header]);
insert into [metadata].[qa_mcaid]
select 
 NULL
,@last_run
,'stage.mcaid_claim_icdcm_header'
,'Compare new-to-prior dx counts'
,'PASS'
,getdate()
,'Match';

SELECT [etl_batch_id]
      ,[last_run]
      ,[table_name]
      ,[qa_item]
      ,[qa_result]
      ,[qa_date]
      ,[note]
FROM [PHClaims].[metadata].[qa_mcaid]
WHERE [table_name] = 'stage.mcaid_claim_icdcm_header';