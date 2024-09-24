-- Data Cleaning

use world_layoffs;

select *
from layoffs;

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Values or blank values
-- 4. Remove any columns

-- Create a copy

create table layoffs_staging
like layoffs;

insert layoffs_staging
select *
from layoffs;

-- Remove Duplicates

select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) as row_num
from layoffs_staging
;

with duplicate_cte as
(
select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) as row_num
from layoffs_staging
)
select *
from duplicate_cte
where row_num > 1;
#74 duplicates

select *
from layoffs_staging
where company = 'Casper';
#Confirming thoses duplicates exist

with duplicate_cte as
(
select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) as row_num
from layoffs_staging
)
delete
from duplicate_cte
where row_num > 1;
#deleting duplicates in a cte to confirm it is correct

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
#creating a new table to add row_num column to delete duplicates in a second place

select *
from layoffs_staging2;

insert into layoffs_staging2
select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) as row_num
from layoffs_staging;
#adding row_num column

set sql_safe_updates = 0;
#setting up parameters so I can deleta rows

delete
from layoffs_staging2
where row_num > 1;
#deleting duplicates

-- Standardizing data

select company, trim(company)
from layoffs_staging2;

update layoffs_staging2
set company = trim(company);

#looking for anamalies in columns and correcting them through the further queries
select distinct industry
from layoffs_staging2
order by 1;

select *
from layoffs_staging2
where industry like 'Crypto%';

update layoffs_staging2
set industry = 'Crypto'
where industry like '%Crypto%';

select distinct country, trim(trailing '.' from country)
from layoffs_staging2
order by 1;

update layoffs_staging2
set country = 'United States'
where country like '%United States%';

#changing date type with the further queries
select `date`
from layoffs_staging2;

update layoffs_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y');

alter table layoffs_staging2
modify column `date` date;

-- step 3: blank and null values

select *
from layoffs_staging
where total_laid_off is null
and percentage_laid_off is null;

select *
from layoffs_staging2
where industry is null
or industry = '';

select *
from layoffs_staging2
where company = 'Airbnb';

select t1.industry, t2.industry
from layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company = t2.company
    and t1.location = t2.location
where (t1.industry is null or t1.industry = '')
and (t2.industry is not null and t2.industry != '');

update layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company = t2.company
set t1.industry = t2.industry
where (t1.industry is null or t1.industry = '')
and (t2.industry is not null and t2.industry != '');
#trying to populate the industry column with values we know

select *
from layoffs_staging2
;

delete
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;
#we can't retrieve value from rows with no total_laid_off and no percentage_laid_off

select *
from layoffs_staging2;

alter table layoffs_staging2
drop column row_num;
#This column is no longer interesting in the dataset since we have no more duplicates
#Ready for Exploratory Data Analysis