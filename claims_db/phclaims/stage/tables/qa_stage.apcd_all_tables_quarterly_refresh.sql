-----------------------
--row and column counts
-----------------------
use phclaims
go
select s.Name AS schema_name, t.NAME AS table_name, 
	max(p.rows) AS row_count, --I'm taking max here because an index that is not on all rows creates two entries in this summary table
    max(p.rows)/1000000 as row_count_million,
	count(c.COLUMN_NAME) as col_count
from sys.tables t
inner join sys.indexes i on t.OBJECT_ID = i.object_id
inner join sys.partitions p on i.object_id = p.OBJECT_ID and i.index_id = p.index_id
inner join sys.allocation_units a on p.partition_id = a.container_id
left outer join sys.schemas s on t.schema_id = s.schema_id
left join information_schema.columns c on t.name = c.TABLE_NAME and s.name = c.TABLE_SCHEMA
where t.NAME NOT LIKE 'dt%' and t.is_ms_shipped = 0 and i.OBJECT_ID > 255
	and left(t.name, 4) = 'apcd' and s.name = 'stage'
group by s.Name, t.Name
order by table_name;

-----------------------
--counts of pre-cutoff rows for tables where last 12 months are overwritten
-----------------------
--dental claim table
select count(*)
from PHClaims.archive.apcd_dental_claim
where first_service_dt <= '2017-12-31';
--medical claim header table
select count(*)
from PHClaims.archive.apcd_medical_claim_header
where first_service_dt <= '2017-12-31';
--medical claim table
select count(*)
from PHClaims.archive.apcd_medical_claim
where first_service_dt <= '2017-12-31';
--pharmacy claim table
select count(*)
from PHClaims.archive.apcd_pharmacy_claim
where first_paid_dt <= '2017-12-31';

-----------------------
--date checks for tables where last 12 months were overwritten
--Run time: 15-20 min
-----------------------
--dental claim table
select extract_id, min(first_service_dt) as min_date, max(first_service_dt) as max_date
from PHClaims.stage.apcd_dental_claim
group by extract_id;

--medical claim header claim table
select extract_id, min(first_service_dt) as min_date, max(first_service_dt) as max_date
from PHClaims.stage.apcd_medical_claim_header
group by extract_id;

--pharmacy claim table
select extract_id, min(first_paid_dt) as min_date, max(first_paid_dt) as max_date
from PHClaims.stage.apcd_pharmacy_claim
group by extract_id;

--medical claim claim table
select extract_id, min(first_service_dt) as min_date, max(first_service_dt) as max_date
from PHClaims.stage.apcd_medical_claim
group by extract_id;

-----------------------
--checks for tables where new columns were added
--Run time: 21 min
-----------------------
select count(*)
from PHClaims.load_raw.apcd_medical_claim_column_add
where submitted_claim_type_id is not null;
select count(*)
from PHClaims.load_raw.apcd_medical_claim_column_add
where eci_diagnosis is not null;
select count(*)
from PHClaims.stage.apcd_medical_claim
where submitted_claim_type_id is not null;
select count(*)
from PHClaims.stage.apcd_medical_claim
where eci_diagnosis is not null;