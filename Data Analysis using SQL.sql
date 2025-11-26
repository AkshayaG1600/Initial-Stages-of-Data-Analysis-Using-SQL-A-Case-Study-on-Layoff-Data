--How data look like

Select * from layoffs;

-- Create backup of table
Select *
into layoffs_staging 
from layoffs;
Select * from layoffs_staging;

--Find shape of table (Number of rows and columns)
Select count(*) as total_row
from layoffs_staging;   -- Total number of rows
Select count(*) AS total_columns
from INFORMATION_SCHEMA.COLUMNS
where table_name = 'layoffs_staging';  ---- Total number of cloumns

--Find data type of columns of table
Select
	column_name,
	data_type,
	character_maximum_length
from INFORMATION_SCHEMA.COLUMNS
where table_name = 'layoffs_staging';

--Find duplicate values and remove it.
with duplicate_cte as
(
Select *,
row_number() over(partition by company, location, industry, total_laid_off, percentage_laid_off, stage, date, country, 
funds_raised_millions order by company) as row_num
from layoffs_staging
)
Delete from duplicate_cte
where row_num > 1;

--Find Null and blank cell and remove it.
SELECT *
FROM layoffs_staging
WHERE industry IS NULL
   or trim(industry) = '';  ---- Find how many cell are blank/Null

Delete from layoffs_staging
WHERE industry IS NULL
   or trim(industry) = '';   ---- Delect row which have are blank/Null cell

--Find and normalize values that have the same meaning but different forms (e.g., “crypto” vs. “cryptocurrency”).
Select Distinct industry
from layoffs_staging
order by industry;   ---- Find all Distinct values in column

Update layoffs_staging
set industry = 'Crypto'
where industry like 'Crypto%';  ---- Update value with same meaning

Update layoffs_staging
set country = 'United States'
where country like 'United States%';

-- Update the format of date column like 'MM-DD-YYYY'

Select company, FORMAT([date], 'MM-dd-yyyy') date
from layoffs_staging;

--Find the mathematical relation of number columns

WITH math_calculation AS (
    SELECT
        TRY_CONVERT(DECIMAL(18,4), total_laid_off)        AS total_laid_off_n,
        TRY_CONVERT(DECIMAL(18,4), percentage_laid_off)   AS percentage_laid_off_n,
        TRY_CONVERT(DECIMAL(18,4), funds_raised_millions) AS funds_raised_millions_n
    FROM layoffs_staging
),
stats AS (
    SELECT 'count' AS metric,
           COUNT(total_laid_off_n) AS total_laid_off,
           COUNT(percentage_laid_off_n) AS percentage_laid_off,
           COUNT(funds_raised_millions_n) AS funds_raised_millions
    FROM math_calculation

    UNION ALL SELECT 'mean',
           AVG(total_laid_off_n),
           AVG(percentage_laid_off_n),
           AVG(funds_raised_millions_n)
    FROM math_calculation

    UNION ALL SELECT 'std',
           STDEV(total_laid_off_n),
           STDEV(percentage_laid_off_n),
           STDEV(funds_raised_millions_n)
    FROM math_calculation

    UNION ALL SELECT 'min',
           MIN(total_laid_off_n),
           MIN(percentage_laid_off_n),
           MIN(funds_raised_millions_n)
    FROM math_calculation

    UNION ALL SELECT 'max',
           MAX(total_laid_off_n),
           MAX(percentage_laid_off_n),
           MAX(funds_raised_millions_n)
    FROM math_calculation
)
SELECT *
FROM stats
ORDER BY 
    CASE metric 
        WHEN 'count' THEN 1
        WHEN 'mean'  THEN 2
        WHEN 'std'   THEN 3
        WHEN 'min'   THEN 4
        WHEN 'max'   THEN 5
    END;

-- Fill blank or Null cell with specific value
Update layoffs_staging
set total_laid_off = '0'
WHERE total_laid_off IS NULL
   or total_laid_off = '';  --- For numerial (Int/Float) columns

Update layoffs_staging
set industry = 'Unknown'
where industry IS NULL
   or industry = '';   --- For character (varchar) columns









