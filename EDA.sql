-- Exploratory Data Analysis

select *
from layoffs_staging2;

select min(`date`), max(`date`)
from layoffs_staging2;
# 2020-03-11 --> 2023-03-06 (only 3 months of 2023)

select max(total_laid_off), max(percentage_laid_off)
from layoffs_staging2;
# max total laid off: 12000
# max percentage laid off: 1 corresponding to the all company

-- Analysis concerning the most popular variables in bankruptcies
select industry, count(industry) as nbr_companies
from layoffs_staging2
where percentage_laid_off = 1
group by industry
order by nbr_companies desc;
# Retail, Food and Finance are industries in which the most companies have filed for bankruptcy.

select country, count(industry) as nbr_companies
from layoffs_staging2
where percentage_laid_off = 1
group by country
order by nbr_companies desc;
# The United States is, by far, the country with the most bankruptcy cases

select location, count(industry) as nbr_companies
from layoffs_staging2
where percentage_laid_off = 1 and country = 'United States'
group by location
order by nbr_companies desc;
# In the United States, the locations mostly concerned by bankruptcy cases are 1st 'San Francisco Bay' and 2nd 'New York City'

select year(`date`) as `year`, count(*) as nbr_companies
from layoffs_staging2
where percentage_laid_off = 1
group by `year`
order by nbr_companies desc;
# More bankruptcy cases are happening since 2022

-- Analysis of the highest cases of layoffs
select company, sum(total_laid_off)
from layoffs_staging2
group by company
order by 2 desc;
# Companies involved in the highest cases of layoffs are huge companies such as Amazon, Google, Meta, Salesforce, Microsoft, and so on.

select industry, sum(total_laid_off)
from layoffs_staging2
group by industry
order by 2 desc;
# Industries with the most layoffs are the following: Consumer, Retail, Transportation, Finance

select country, sum(total_laid_off)
from layoffs_staging2
group by country
order by 2 desc;
# The country with the most layoffs, and by far, is the United States, with almost 10x layoffs more than the second one India

select year(`date`), sum(total_laid_off)
from layoffs_staging2
group by year(`date`)
order by 2 desc;
# The second year with the most layoffs is 2023 but very close to 2022, and through the next query we discover that we only have 3 month 
# of 2023 which means 2023 is going to take first place by far of total layoffs over the year

select year(`date`), month(`date`), sum(total_laid_off)
from layoffs_staging2
where year(`date`) = '2022'
group by year(`date`), month(`date`)
order by 2 desc;
# we have data of only 3 months for 2023

select stage, sum(total_laid_off)
from layoffs_staging2
group by stage
order by 2 desc;
# Post-IPO companies are companies that layoff the most. 
# That is consistent with the names of the companies with the most layoffs that we found earlier (Microsoft, Amazon, Google, Meta, ...)

with rolling_total as
(
select substring(`date`, 1, 7) as `month`, sum(total_laid_off) as total_off
from layoffs_staging2
where substring(`date`, 1, 7) is not null
group by `month`
order by 1 asc
)
select `month`, total_off, sum(total_off) over(order by `month`) as rolling_total
from rolling_total;
# This query shows the evolution of the cumulative total of layoffs as time progresses
# We observe that 2021 was a light year in terms of layoffs compared to the begin of 2023 for example

# The following table will be used for the next query, we retrieve top 5 companies with the most layoffs
create temporary table companies_most_layoffs
select company, sum(total_laid_off)
from layoffs_staging2
group by company
order by 2 desc
limit 5;

select *
from companies_most_layoffs;

with annual_layoffs as
(
select company, year(`date`) as `year`, sum(total_laid_off) as laid_off
from layoffs_staging2
where company in (select company
					from companies_most_layoffs)
group by company, year(`date`)
order by company, `year` asc
)
select *, sum(laid_off) over(partition by company order by company, `year`) as rolling_company_total
from annual_layoffs;
# this query presents the rolling total by year of the top 5 companies that layoff the most people

with company_year (company, years, total_laid_off) as
(
select company, year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
), 
company_year_rank as
(
select *, dense_rank() over(partition by years order by total_laid_off desc) as ranking
from company_year
where years is not null
)
select *
from company_year_rank
where ranking <= 5;
# This query reveals the ranking, top 5, of the companies with the most layoffs for each year from 2020 to beginning of 2023
# 2020: Uber, Booking.com, Groupon, Swiggy, Airbnb
# 2021: Bytedance, Katerra, Zillow, Instacart, WhiteHat Jr
# 2022: Meta, Amazon, Cisco, Pelo, Carvana and Philips (both 5th)
# 2023: Google, Microsoft, Ericsson, Amazon and Salesforce (both 4th), Dell