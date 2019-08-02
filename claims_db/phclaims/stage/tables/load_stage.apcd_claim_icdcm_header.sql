--Code to load data to stage.apcd_claim_icdcm_header table
--ICD-CM diagnosis codes in long format at claim header level
--Eli Kern (PHSKC-APDE)
--2019-5-3
--Run time: 6hr 44min

------------------
--STEP 1: Create temp claim line table with exclusions applied
--Exclude all denied and orphaned claim lines
--Exclude all members with no eligibility information using ref.apcd_claim_no_elig
--Run time: 18 min
-------------------
if object_id('tempdb..#temp1') is not null drop table #temp1;
select a.*
into #temp1
from (
select internal_member_id as 'id_apcd', extract_id, medical_claim_service_line_id, icd_version_ind,
	admitting_diagnosis_code as dxadmit, principal_diagnosis_code as dx01, diagnosis_code_other_1 as dx02,
	diagnosis_code_other_2 as dx03,  diagnosis_code_other_3 as dx04,
	diagnosis_code_other_4 as dx05, diagnosis_code_other_5 as dx06, diagnosis_code_other_6 as dx07,
	diagnosis_code_other_7 as dx08, diagnosis_code_other_8 as dx09, diagnosis_code_other_9 as dx10,
	diagnosis_code_other_10 as dx11, diagnosis_code_other_11 as dx12, diagnosis_code_other_12 as dx13,
    diagnosis_code_other_13 as dx14, diagnosis_code_other_14 as dx15, diagnosis_code_other_15 as dx16,
    diagnosis_code_other_16 as dx17, diagnosis_code_other_17 as dx18, diagnosis_code_other_18 as dx19,
    diagnosis_code_other_19 as dx20, diagnosis_code_other_20 as dx21, diagnosis_code_other_21 as dx22,
    diagnosis_code_other_22 as dx23, diagnosis_code_other_23 as dx24, diagnosis_code_other_24 as dx25,
	eci_diagnosis as dxecode
from PHClaims.stage.apcd_medical_claim
--exclude denied and orphaned claim lines
where denied_claim_flag = 'N' and orphaned_adjustment_flag = 'N'
) as a
left join PHClaims.ref.apcd_claim_no_elig as b
on a.id_apcd = b.id_apcd
where b.id_apcd is null;


------------------
--STEP 2: Reshape diagnosis codes from wide to long, normalize ICD-9-CM to 5 digits
--Exclude all missing (-1, -2) diagnosis codes
--Write this as a persistent table to take pressure off of tempdb
-------------------
if object_id('PHClaims.tmp.apcd_claim_icdcm_header', 'U') is not null drop table PHClaims.tmp.apcd_claim_icdcm_header;
create table PHClaims.tmp.apcd_claim_icdcm_header (
	id_apcd bigint,
	extract_id int,
	medical_claim_service_line_id bigint,
	icdcm_raw varchar(200),
	icdcm_norm varchar(200),
	icdcm_version tinyint,
	icdcm_number varchar(200)
);

insert into PHClaims.tmp.apcd_claim_icdcm_header with (tablock)
select distinct id_apcd, extract_id, medical_claim_service_line_id,
	--raw diagnosis codes
	cast(diagnoses as varchar(200)) as 'icdcm_raw',
	--normalized diagnosis codes
	cast(
		case
			when (icd_version_ind = '9' and len(diagnoses) = 3) then diagnoses + '00'
			when (icd_version_ind = '9' and len(diagnoses) = 4) then diagnoses + '0'
			else diagnoses 
		end 
	as varchar(200)) as 'icdcm_norm',
	--convert ICD-CM version to integer
	cast(case when icd_version_ind = '9' then 9 when icd_version_ind = '0' then 10 end as tinyint) as 'icdcm_version',
	--ICD-CM number
	cast(substring(icdcm_number, 3,10) as varchar(200)) as 'icdcm_number'
from #temp1 as a
unpivot(diagnoses for icdcm_number in(dxadmit, dx01, dx02, dx03, dx04, dx05, dx06, dx07, dx08, dx09, dx10, dx11, dx12, dx13,
	dx14, dx15, dx16, dx17, dx18, dx19, dx20, dx21, dx22, dx23, dx24, dx25, dxecode)) as diagnoses
where diagnoses != '-1' and diagnoses != '-2';

--drop 1st temp table to free memory
drop table #temp1;

--Create index on claim line ID for tmp schema table
--Run time: 80 min (added 9GB to table)
create clustered index idx_cl_tmp_apcd_claim_icdcm_header_medical_claim_service_line_id
on phclaims.tmp.apcd_claim_icdcm_header (medical_claim_service_line_id);


------------------
--STEP 3: Assemble final table and insert into table shell 
--Join to claim crosswalk to get header ID
--Join to claim header to get service dates
--Run time: 130 min
-------------------
insert into PHClaims.stage.apcd_claim_icdcm_header with (tablock)
select distinct a.id_apcd, a.extract_id, b.medical_claim_header_id as 'claim_header_id',
	c.first_service_dt as 'first_service_date', c.last_service_dt as 'last_service_date',
	a.icdcm_raw, a.icdcm_norm, a.icdcm_version, a.icdcm_number
from PHClaims.tmp.apcd_claim_icdcm_header as a
left join PHClaims.stage.apcd_medical_crosswalk as b
on a.medical_claim_service_line_id = b.medical_claim_service_line_id
left join PHClaims.stage.apcd_medical_claim_header as c
on b.medical_claim_header_id = c.medical_claim_header_id;

--drop tmp schema table
drop table PHClaims.tmp.apcd_claim_icdcm_header;