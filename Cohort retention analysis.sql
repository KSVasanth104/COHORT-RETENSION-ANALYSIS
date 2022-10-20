use CA;

select * from online_retail

-------------------------------------------------------------------------------------- Cleaning data--------------------------------------------------------------------

-------- 1. checking all distinct values of all columns

select distinct * from online_retail;

-- some customerID  has value 0
-- some UnitPrice column  has value 0
-- some Quantities has negative values
-- removing those customers 

select count(CustomerID) from online_retail
where CustomerID = 0;

-- cleaning using CTE 

with cleaning1 as 
(
	-- Total record 541909
	-- with Customer ID = 406829
	select * from [dbo].[online_retail]
	where CustomerID != 0

)
, cleaning2 as
(	
	-- 397882 Records
	select *
	from cleaning1 
	where Quantity>0 and UnitPrice >0
)
,cleaning3 as
(
-- Duplicates check

select *, 
ROW_NUMBER() over(partition by InvoiceNo, StockCode,Quantity order by InvoiceDate) duplicates
from cleaning2
)
, final_data as
(
-- Total 392667 data
select * from cleaning3
where duplicates=1
)

-- creating temporary table for final data
select *
into #cleaned_online_retails
from final_data

----------------------------------------------------------------------------------------------ANALYSIS----------------------------------------------------------------------------------------

-- Cohort Analysis based on
-- Unique Identifier = CustomerID
-- Intial Start DAte = First Invoice Date
-- Revenue Date

select * from  #cleaned_online_retails


-- First Purchase Date for each Customer
-- Cohort Date column focus mainly on month and year of 1st perchase 
select customerID, min(invoicedate) first_purchase_date
,DATEFROMPARTS(year(min(invoicedate)), month(min(invoicedate)),01) as cohot_date
into #cohort
from  #cleaned_online_retails
group by customerID


select * from  #cohort

-- create cohort index - tells number of months passed since first purchase
-- Join both tables
select xx.* ,
cohort_index = yr_diff * 12 + month_diff +1  -- 1 means purchase made in same month as first purchase
into #cohort_retension
from
(select 
	x.*,
	yr_diff = invoice_year-cohort_year,
	month_diff = invoice_month-cohort_month
from
(select o.*,c.cohot_date, 
		year(o.invoicedate) invoice_year,
		month(o.invoicedate) invoice_month,
		year(c.cohot_date) cohort_year,
		month(c.cohot_date) cohort_month
from #cleaned_online_retails o
left join #cohort c
on o.CustomerID=c.CustomerID) x)xx

select * from  #cohort_retension
where CustomerID=12567
-- Grouping People by cohort index
--select * 
--from(
--select distinct customerid,cohot_date,cohort_index
--from #cohort_retension
--) tbl
--pivot(
--	count(customerid)
--	for cohort_index in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24]) )as pivot_table
--	order by 1

	