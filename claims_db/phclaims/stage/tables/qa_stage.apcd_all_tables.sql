--count rows
SELECT count(*) as row_cnt
--,min(row_number) as row_min, max(row_number) as row_max
FROM [PHClaims].stage.apcd_medical_claim;

use PHClaims
go
--count columns
SELECT COUNT(*)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'PHClaims' -- the database
AND table_name = 'apcd_' + 'medical_claim';