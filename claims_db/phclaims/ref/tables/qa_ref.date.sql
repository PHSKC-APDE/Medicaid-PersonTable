
SELECT COUNT(*)
FROM [PHClaims].[ref].[date];

SELECT COUNT(*)
FROM [PHClaims].[ref].[date]
WHERE (YEAR([date]) * 10000 + MONTH([date]) * 100 + DAY([date])) = [year_month_day];

SELECT COUNT(*)
FROM [PHClaims].[ref].[date]
WHERE (YEAR([date]) * 100 + MONTH([date])) = [year_month];

SELECT COUNT(*)
FROM [PHClaims].[ref].[date]
WHERE (YEAR([date]) * 100 + DATEPART(QUARTER, [date])) = [year_quarter];

SELECT COUNT(*)
FROM [PHClaims].[ref].[date]
WHERE YEAR([date]) = [year];

SELECT COUNT(*)
FROM [PHClaims].[ref].[date]
WHERE (YEAR([date]) * 10000 + MONTH([date]) * 100 + DAY([date])) <> [year_month_day];

SELECT COUNT(*)
FROM [PHClaims].[ref].[date]
WHERE (YEAR([date]) * 100 + MONTH([date])) <> [year_month];

SELECT COUNT(*)
FROM [PHClaims].[ref].[date]
WHERE (YEAR([date]) * 100 + DATEPART(QUARTER, [date])) <> [year_quarter];

SELECT COUNT(*)
FROM [PHClaims].[ref].[date]
WHERE YEAR([date]) <> [year];