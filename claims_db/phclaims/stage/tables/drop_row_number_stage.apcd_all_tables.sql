-----------------------
--Drop row_number column from all big tables
--Eli Kern, APDE, PHSKC
--3/28/2019
-----------------------

alter table PHClaims.stage.apcd_dental_claim
drop column row_number;

alter table PHClaims.stage.apcd_eligibility
drop column row_number;

alter table PHClaims.stage.apcd_medical_claim
drop column row_number;

alter table PHClaims.stage.apcd_medical_claim_header
drop column row_number;

alter table PHClaims.stage.apcd_medical_crosswalk
drop column row_number;

alter table PHClaims.stage.apcd_member_month_detail
drop column row_number;

alter table PHClaims.stage.apcd_pharmacy_claim
drop column row_number;

alter table PHClaims.stage.apcd_provider
drop column row_number;