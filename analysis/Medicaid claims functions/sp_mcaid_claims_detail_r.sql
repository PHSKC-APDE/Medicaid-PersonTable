--Eli Kern
--Assessment, Policy Development & Evaluation, Public Health - Seattle & King County
--6/27/18
--Code to return a claim summary for a member cohort generated by the Medicaid eligibility cohort function
--This script creates a stored procedure for use within R (only difference is that this does not create a temp table)
--This stored procedure is intended to be run in sequence with the MEdicaid eligibilty cohort function (sp_mcaidcohort_sql)
--This "detailed" version returns a longer subset of available claim summary variables than the "simple" version

--select database
use PHClaims
go

--drop stored procedure before creating new
drop procedure dbo.sp_mcaid_claims_detail_r
go

--create stored procedure
create proc dbo.sp_mcaid_claims_detail_r
	(
	@from_date as date,
	@to_date as date
	)
as
begin

select query_from_date = @from_date, query_to_date = @to_date,

	--Eligibility variables
	elig.id, elig.cov_cohort, elig.covd, elig.covper, elig.ccovd_max, elig.covgap_max, elig.duald, elig.dualper, 
	elig.dual_flag, elig.dobnew, elig.age, elig.age_grp7, elig.gender_mx, elig.male, elig.female, elig.male_t, elig.female_t, elig.gender_unk, elig.race_eth_mx, 
	elig.race_mx, elig.aian, elig.asian, elig.black, elig.nhpi, elig.white, elig.latino, elig.aian_t, elig.asian_t, elig.black_t, elig.nhpi_t, elig.white_t, 
	elig.latino_t, elig.race_unk, elig.tractce10, elig.zip_new, elig.hra_id, hra, elig.region_id, elig.region, elig.maxlang, elig.english, elig.spanish, elig.vietnamese,
	elig.chinese, elig.somali, elig.russian, elig.arabic, elig.korean, elig.ukrainian, elig.amharic, elig.english_t, elig.spanish_t, elig.vietnamese_t, elig.chinese_t,
	elig.somali_t, elig.russian_t, elig.arabic_t, elig.korean_t, elig.ukrainian_t, elig.amharic_t, elig.lang_unk,
	
	--Claims variables 
	case when claim.mental_dx1_cnt is null then 0 else claim.mental_dx1_cnt end as 'mental_dx1_cnt',
	case when claim.mental_dxany_cnt is null then 0 else claim.mental_dxany_cnt end as 'mental_dxany_cnt',
	case when claim.maternal_dx1_cnt is null then 0 else claim.maternal_dx1_cnt end as 'maternal_dx1_cnt',
	case when claim.maternal_broad_dx1_cnt is null then 0 else claim.maternal_broad_dx1_cnt end as 'maternal_broad_dx1_cnt',
	case when claim.newborn_dx1_cnt is null then 0 else claim.newborn_dx1_cnt end as 'newborn_dx1_cnt',
	case when claim.inpatient_cnt is null then 0 else claim.inpatient_cnt end as 'inpatient_cnt',
	case when claim.ipt_medsurg_cnt is null then 0 else claim.ipt_medsurg_cnt end as 'ipt_medsurg_cnt',
	case when claim.ipt_bh_cnt is null then 0 else claim.ipt_bh_cnt end as 'ipt_bh_cnt',
	case when claim.ed_cnt is null then 0 else claim.ed_cnt end as 'ed_cnt',
	case when claim.ed_nohosp_cnt is null then 0 else claim.ed_nohosp_cnt end as 'ed_nohosp_cnt',
	case when claim.ed_bh_cnt is null then 0 else claim.ed_bh_cnt end as 'ed_bh_cnt',
	case when claim.ed_avoid_ca_cnt is null then 0 else claim.ed_avoid_ca_cnt end as 'ed_avoid_ca_cnt',
	case when claim.ed_sdoh_cnt is null then 0 else claim.ed_sdoh_cnt end as 'ed_sdoh_cnt',
	case when claim.ipt_sdoh_cnt is null then 0 else claim.ipt_sdoh_cnt end as 'ipt_sdoh_cnt',
	case when claim.mental_dx_rda_any_cnt is null then 0 else claim.mental_dx_rda_any_cnt end as 'mental_dx_rda_any_cnt',
	case when claim.sud_dx_rda_any_cnt is null then 0 else claim.sud_dx_rda_any_cnt end as 'sud_dx_rda_any_cnt',
	case when claim.dental_cnt is null then 0 else claim.dental_cnt end as 'dental_cnt',
	case when claim.ed_ne_nyu_cnt is null then 0 else claim.ed_ne_nyu_cnt end as 'ed_ne_nyu_cnt',
	case when claim.ed_pct_nyu_cnt is null then 0 else claim.ed_pct_nyu_cnt end as 'ed_pct_nyu_cnt',
	case when claim.ed_pa_nyu_cnt is null then 0 else claim.ed_pa_nyu_cnt end as 'ed_pa_nyu_cnt',	
	case when claim.ed_npa_nyu_cnt is null then 0 else claim.ed_npa_nyu_cnt end as 'ed_npa_nyu_cnt',	
	case when claim.ed_mh_nyu_cnt is null then 0 else claim.ed_mh_nyu_cnt end as 'ed_mh_nyu_cnt',
	case when claim.ed_sud_nyu_cnt is null then 0 else claim.ed_sud_nyu_cnt end as 'ed_sud_nyu_cnt',
	case when claim.ed_alc_nyu_cnt is null then 0 else claim.ed_alc_nyu_cnt end as 'ed_alc_nyu_cnt',
	case when claim.ed_injury_nyu_cnt is null then 0 else claim.ed_injury_nyu_cnt end as 'ed_injury_nyu_cnt',
	case when claim.ed_unclass_nyu_cnt is null then 0 else claim.ed_unclass_nyu_cnt end as 'ed_unclass_nyu_cnt',
	case when claim.ed_emergent_nyu_cnt is null then 0 else claim.ed_emergent_nyu_cnt end as 'ed_emergent_nyu_cnt',
	case when claim.ed_nonemergent_nyu_cnt is null then 0 else claim.ed_nonemergent_nyu_cnt end as 'ed_nonemergent_nyu_cnt',
	case when claim.ed_intermediate_nyu_cnt is null then 0 else claim.ed_intermediate_nyu_cnt end as 'ed_intermediate_nyu_cnt',

	case when claim.ed_cnt is null then 1 else 0 end as 'no_claims'

from (
	select id, cov_cohort,	covd, covper, ccovd_max, covgap_max, duald, dualper, dual_flag, dobnew, age, age_grp7, gender_mx, male, female, 
		male_t, female_t, gender_unk, race_eth_mx, race_mx, aian, asian, black, nhpi, white, latino, aian_t, asian_t, black_t, 
		nhpi_t, white_t, latino_t, race_unk, tractce10, zip_new, hra_id, hra, region_id, region, maxlang, english, spanish, vietnamese, chinese, somali, 
		russian, arabic, korean, ukrainian, amharic, english_t, spanish_t, vietnamese_t, chinese_t, somali_t, russian_t,
		arabic_t, korean_t, ukrainian_t, amharic_t, lang_unk 
	from ##mcaidcohort
) as elig

left join (
	select b.id,
			sum(b.mental_dx1) as 'mental_dx1_cnt', sum(b.mental_dxany) as 'mental_dxany_cnt',
			sum(b.maternal_dx1) as 'maternal_dx1_cnt', sum(b.maternal_broad_dx1) as 'maternal_broad_dx1_cnt',
			sum(b.newborn_dx1) as 'newborn_dx1_cnt', sum(b.inpatient) as 'inpatient_cnt', sum(b.ipt_medsurg) as 'ipt_medsurg_cnt',
			sum(b.ipt_bh) as 'ipt_bh_cnt', sum( b.ed) as 'ed_cnt', sum(b.ed_nohosp) as 'ed_nohosp_cnt', sum(b.ed_bh) as 'ed_bh_cnt', 
			sum(b.ed_avoid_ca) as 'ed_avoid_ca_cnt', sum(b.mental_dx_rda_any) as 'mental_dx_rda_any_cnt', sum(b.sud_dx_rda_any) as 'sud_dx_rda_any_cnt',
			sum(b.dental) as 'dental_cnt', sum(b.ed_emergent_nyu) as 'ed_emergent_nyu_cnt', 
			sum(b.ed_ne_nyu) as 'ed_ne_nyu_cnt', sum(b.ed_pct_nyu) as 'ed_pct_nyu_cnt', sum(b.ed_pa_nyu) as 'ed_pa_nyu_cnt',
			sum(b.ed_npa_nyu) as 'ed_npa_nyu_cnt', sum(b.ed_mh_nyu) as 'ed_mh_nyu_cnt', sum(b.ed_sud_nyu) as 'ed_sud_nyu_cnt', 
			sum(b.ed_alc_nyu) as 'ed_alc_nyu_cnt', sum(b.ed_injury_nyu) as 'ed_injury_nyu_cnt', sum(b.ed_unclass_nyu) as 'ed_unclass_nyu_cnt',
			sum(b.ed_nonemergent_nyu) as 'ed_nonemergent_nyu_cnt', sum(b.ed_intermediate_nyu) as 'ed_intermediate_nyu_cnt', 
			sum(b.ed_sdoh) as ed_sdoh_cnt, sum(b.ipt_sdoh) as ipt_sdoh_cnt

	from (
		select a.id,
			max(a.mental_dx1) as 'mental_dx1', max(a.mental_dxany) as 'mental_dxany',
			max(a.maternal_dx1) as 'maternal_dx1', max(a.maternal_broad_dx1) as 'maternal_broad_dx1',
			max(a.newborn_dx1) as 'newborn_dx1', max(a.inpatient) as 'inpatient', max(a.ipt_medsurg) as 'ipt_medsurg',
			max(a.ipt_bh) as 'ipt_bh', max(a.ed) as 'ed', max(a.ed_nohosp) as 'ed_nohosp', max(a.ed_bh) as 'ed_bh', max(a.ed_avoid_ca) as 'ed_avoid_ca', 
			max(a.mental_dx_rda_any) as 'mental_dx_rda_any', max(a.sud_dx_rda_any) as 'sud_dx_rda_any',
			max(a.dental) as 'dental', max(a.ed_ne_nyu) as 'ed_ne_nyu', max(a.ed_pct_nyu) as 'ed_pct_nyu', max(a.ed_pa_nyu) as 'ed_pa_nyu',
			max(a.ed_npa_nyu) as 'ed_npa_nyu', max(a.ed_mh_nyu) as 'ed_mh_nyu', max(a.ed_sud_nyu) as 'ed_sud_nyu',
			max(a.ed_alc_nyu) as 'ed_alc_nyu', max(a.ed_injury_nyu) as 'ed_injury_nyu', max(a.ed_unclass_nyu) as 'ed_unclass_nyu',
			max(a.ed_emergent_nyu) as 'ed_emergent_nyu', max(a.ed_nonemergent_nyu) as 'ed_nonemergent_nyu',
			max(a.ed_intermediate_nyu) as 'ed_intermediate_nyu', 
			max(a.ed_sdoh) as 'ed_sdoh', max(a.ipt_sdoh) as 'ipt_sdoh'

		from (
			select id from ##mcaidcohort
		) as id

		left join (
			select id, tcn, from_date, mental_dx1, mental_dxany, maternal_dx1, maternal_broad_dx1, newborn_dx1,
				inpatient, ipt_medsurg, ipt_bh, ed, ed_nohosp, ed_bh, ed_avoid_ca, mental_dx_rda_any, sud_dx_rda_any,
				ed_ne_nyu, ed_pct_nyu, ed_pa_nyu, ed_npa_nyu,
				ed_mh_nyu, ed_sud_nyu, ed_alc_nyu, ed_injury_nyu, ed_unclass_nyu,
				ed_emergent_nyu, ed_nonemergent_nyu, ed_intermediate_nyu, ed_sdoh, ipt_sdoh,
			case when clm_type_code = '4' then 1 else 0 end as 'dental'
			from PHClaims.dbo.mcaid_claim_summary
			 --This captures health care events that overlapped any part of window
			--where from_date <= @to_date and to_date >= @from_date
			 --This captures health care events that BEGAN during window
			where from_date >= @from_date and from_date <= @to_date
				and exists (select id from ##id where id = PHClaims.dbo.mcaid_claim_summary.id)
		) as a
		on id.id = a.id
		--This crucial grouping step only allows one event to be counted for each member-from_date
		group by a.id, a.from_date
	) as b
	--This second grouping counts the event flags that were deduplicated at the member-from_date level
	group by b.id
) as claim
on elig.id = claim.id

end