-----------------------
--Combine all table parts of medical_claim table
--Eli Kern, APDE, PHSKC
--3/27/2019
-----------------------

-----------------------
--Check sum of rows from all table parts
-----------------------
select count(*) from PHClaims.stage.apcd_medical_claim;
select count(*) from PHClaims.stage.apcd_medical_claim_15;
select count(*) from PHClaims.stage.apcd_medical_claim_20;
select count(*) from PHClaims.stage.apcd_medical_claim_26_final;
select count(*) from PHClaims.stage.apcd_medical_claim_37_final;
select count(*) from PHClaims.stage.apcd_medical_claim_42;
select count(*) from PHClaims.stage.apcd_medical_claim_45;
select count(*) from PHClaims.stage.apcd_medical_claim_48;
select count(*) from PHClaims.stage.apcd_medical_claim_50;
select count(*) from PHClaims.stage.apcd_medical_claim_8;

--------------------------
--Insert tables, one by one, into medical_claim table
--------------------------

--Batch 1 & 2
--insert into PHClaims.stage.apcd_medical_claim with (tablock)
--select * from PHClaims.stage.apcd_medical_claim_15;

select count(*) from PHClaims.stage.apcd_medical_claim;
drop table PHClaims.stage.apcd_medical_claim_15;

--Batch 3
--insert into PHClaims.stage.apcd_medical_claim with (tablock)
--select * from PHClaims.stage.apcd_medical_claim_20;

select count(*) from PHClaims.stage.apcd_medical_claim;
drop table PHClaims.stage.apcd_medical_claim_20;

--Batch 4
--insert into PHClaims.stage.apcd_medical_claim with (tablock)
--select * from PHClaims.stage.apcd_medical_claim_26_final;

select count(*) from PHClaims.stage.apcd_medical_claim;
drop table PHClaims.stage.apcd_medical_claim_26_final;

--Batch 5
--insert into PHClaims.stage.apcd_medical_claim with (tablock)
--select * from PHClaims.stage.apcd_medical_claim_37_final;

select count(*) from PHClaims.stage.apcd_medical_claim;
drop table PHClaims.stage.apcd_medical_claim_37_final;

--Batch 6
--insert into PHClaims.stage.apcd_medical_claim with (tablock)
--select * from PHClaims.stage.apcd_medical_claim_42;

select count(*) from PHClaims.stage.apcd_medical_claim;
drop table PHClaims.stage.apcd_medical_claim_42;

--Batch 7
--insert into PHClaims.stage.apcd_medical_claim with (tablock)
--select * from PHClaims.stage.apcd_medical_claim_45;

select count(*) from PHClaims.stage.apcd_medical_claim;
drop table PHClaims.stage.apcd_medical_claim_45;

--Batch 8
--insert into PHClaims.stage.apcd_medical_claim with (tablock)
--select * from PHClaims.stage.apcd_medical_claim_48;

select count(*) from PHClaims.stage.apcd_medical_claim;
drop table PHClaims.stage.apcd_medical_claim_48;

--Batch 9 & 10
--insert into PHClaims.stage.apcd_medical_claim with (tablock)
--select * from PHClaims.stage.apcd_medical_claim_50;

--insert into PHClaims.stage.apcd_medical_claim with (tablock)
--select * from PHClaims.stage.apcd_medical_claim_8;

drop table PHClaims.stage.apcd_medical_claim_50;
drop table PHClaims.stage.apcd_medical_claim_8;

--------------------------
--QA final table
--------------------------
select count(distinct row_number) as 'row_dcount' from PHClaims.stage.apcd_medical_claim;
select min(row_number) as row_min, max(row_number) as row_max from PHClaims.stage.apcd_medical_claim;

