--Code to load data to stage.apcd_claim_procedure table
--Procedure codes in long format at claim header level
--Eli Kern (PHSKC-APDE)
--2019-8-22
--Run time: XX min

------------------
--STEP 1: Create temp claim header-level table with exclusions applied
--Exclude all denied and orphaned claim lines
--Run time: XX min
-------------------
if object_id('tempdb..#temp1') is not null drop table #temp1;
select distinct internal_member_id as 'id_apcd', medical_claim_header_id,
	min(first_service_dt) over(partition by medical_claim_header_id) as first_service_date,
	max(last_service_dt) over(partition by medical_claim_header_id) as last_service_date,
	cast(procedure_code as varchar(20)) as pcline, cast(principal_icd_procedure_code as varchar(20)) as pc01, cast(icd_procedure_code_1 as varchar(20)) as pc02,
	cast(icd_procedure_code_2 as varchar(20)) as pc03,  cast(icd_procedure_code_3 as varchar(20)) as pc04,
	cast(icd_procedure_code_4 as varchar(20)) as pc05, cast(icd_procedure_code_5 as varchar(20)) as pc06, cast(icd_procedure_code_6 as varchar(20)) as pc07,
	cast(icd_procedure_code_7 as varchar(20)) as pc08, cast(icd_procedure_code_8 as varchar(20)) as pc09, cast(icd_procedure_code_9 as varchar(20)) as pc10,
	cast(icd_procedure_code_10 as varchar(20)) as pc11, cast(icd_procedure_code_11 as varchar(20)) as pc12, cast(icd_procedure_code_12 as varchar(20)) as pc13,
    cast(icd_procedure_code_13 as varchar(20)) as pc14, cast(icd_procedure_code_14 as varchar(20)) as pc15, cast(icd_procedure_code_15 as varchar(20)) as pc16,
    cast(icd_procedure_code_16 as varchar(20)) as pc17, cast(icd_procedure_code_17 as varchar(20)) as pc18, cast(icd_procedure_code_18 as varchar(20)) as pc19,
    cast(icd_procedure_code_19 as varchar(20)) as pc20, cast(icd_procedure_code_20 as varchar(20)) as pc21, cast(icd_procedure_code_21 as varchar(20)) as pc22,
    cast(icd_procedure_code_22 as varchar(20)) as pc23, cast(icd_procedure_code_23 as varchar(20)) as pc24, cast(icd_procedure_code_24 as varchar(20)) as pc25,
	procedure_modifier_code_1 as modifier_1, procedure_modifier_code_2 as modifier_2,
	procedure_modifier_code_3 as modifier_3, procedure_modifier_code_4 as modifier_4
into #temp1
from PHClaims.stage.apcd_medical_claim
--exclude denied and orphaned claim lines
where denied_claim_flag = 'N' and orphaned_adjustment_flag = 'N';


------------------
--STEP 2: Reshape diagnosis codes from wide to long
--Exclude all missing procedure codes
--Run time: XX min
-------------------
if object_id('tempdb..#temp2') is not null drop table #temp2;
select distinct id_apcd, medical_claim_header_id, first_service_date, last_service_date, cast(pcodes as varchar(255)) as procedure_code,
	cast(substring(procedure_code_number, 3,10) as varchar(200)) as procedure_code_number, modifier_1, modifier_2,
	modifier_3, modifier_4
into #temp2
from #temp1 as a
unpivot(pcodes for procedure_code_number in(pcline, pc01, pc02, pc03, pc04, pc05, pc06, pc07, pc08, pc09, pc10, pc11, pc12, pc13,
	pc14, pc15, pc16, pc17, pc18, pc19, pc20, pc21, pc22, pc23, pc24, pc25)) as pcodes
--exclude all procedure codes that are empty
where pcodes is not null;

--drop 1st temp table to free memory
drop table #temp1;

------------------
--STEP 3: Assemble final table and insert into table shell 
--Run time: XX min
-------------------
insert into PHClaims.stage.apcd_claim_procedure with (tablock)
select distinct id_apcd, medical_claim_header_id as claim_header_id,
	first_service_date, last_service_date, procedure_code, procedure_code_number,
	modifier_1, modifier_2, modifier_3, modifier_4, getdate() as last_run
from #temp2;