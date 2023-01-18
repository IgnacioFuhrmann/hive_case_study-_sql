-- STEP 1 IMPORT TABLES (AS CSV)

-- Table 1. Creating Packaging_Used table
CREATE TABLE public.packaging_used
(
    "id" integer,
    "customer_id" integer,
    "sku_id" integer,
    "quantity" integer,
    "use_date" timestamp without time zone,
	PRIMARY KEY ("id")
);

-- Import csv file
Copy public.packaging_used
From '/Users/patasa/Desktop/pgAdmin-SQL/BA_Case_Packaging_Packaging_Used.csv'
Delimiter ','
csv header;

-- Preview Packaging_Used table
Select *
From packaging_used

-- Table 2. Creating SKUs table
CREATE TABLE public.skus
(
    "sku_id" integer,
    "name" varchar,
    "type" varchar,
    "weight_(gr)" int,
    "volume_(cm3)" double precision,
	PRIMARY KEY ("sku_id")
);

-- Import csv file
Copy public.skus
From '/Users/patasa/Desktop/pgAdmin-SQL/BA_Case_Packaging_SKUs.csv'
Delimiter ','
csv header;

-- Preview SKUs table
Select *
From skus

-- Table 3. Creating Prices table
CREATE TABLE public.prices
(
    id integer,
    sku_id integer,
    valid_from timestamp without time zone,
    valid_until timestamp without time zone,
    unit_price double precision,
	PRIMARY KEY (id)
);
	
-- Import csv file
Copy public.prices
From '/Users/patasa/Desktop/pgAdmin-SQL/BA_Case_Packaging_Prices.csv'
Delimiter ','
csv header;

-- Preview Prices table
Select *
From prices


-- Table 4. Creating Costs table
CREATE TABLE public.costs
(
    id integer,
    sku_id integer,
    valid_from timestamp without time zone,
    valid_until timestamp without time zone,
    unit_cost double precision,
	PRIMARY KEY (id)
);

-- Import csv file
Copy public.costs
From '/Users/patasa/Desktop/pgAdmin-SQL/BA_Case_Packaging_Costs.csv'
Delimiter ','
csv header;

-- Preview Costs table
Select *
From costs

--STEP 2 Querys
-- Question 1,2
-- objective: create a big table with all the importan data 
-- and calculation for vizualization 

-- 1
-- Quantities (Usage) per sku firts semester
create table usage_table_s1 as 
Select packaging_used.sku_id, sum(quantity) as s1_quatity
From packaging_used
where packaging_used.use_date <= '06/30/2022 23:59:59'
Group by packaging_used.sku_id
order by sku_id;
	
-- Quantities (usage) per sku second semester
create table usage_table_s2 as 
Select packaging_used.sku_id, sum(quantity) as s2_quantity
From packaging_used
where packaging_used.use_date >= '06/30/2022 23:59:59'
Group by packaging_used.sku_id
order by sku_id;

-- Quantities (usage) per sku 2022
create table usage_table_2022 as 
Select packaging_used.sku_id, sum(quantity) as "total_quantity"
From packaging_used
Group by packaging_used.sku_id
order by sku_id;

-- 2
-- profit per sku firts semester
create table profit_table_s1 as 
Select prices.sku_id, round((unit_price - unit_cost)::numeric, 2) as profit_s1
From costs, prices
where costs.valid_until <= '6/30/2022 23:59:59' and 
prices.valid_until <= '6/30/2022 23:59:59' and 
prices.sku_id=costs.sku_id;


-- profit per sku second semester
create table profit_table_s2 as 
Select prices.sku_id, round((unit_price - unit_cost)::numeric, 2) as profit_s2
From costs, prices
where costs.valid_from >= '7/01/2022 00:00:00' and 
prices.valid_from >= '7/01/2022 00:00:00' and 
prices.sku_id=costs.sku_id;

-- total profit 2022 per sku
create table profit_table_2022 as
select profit_table_s1.sku_id, sum(profit_table_s1.profit_s1 + profit_table_s2.profit_s2) as profit_total
from profit_table_s1
join profit_table_s2 on profit_table_s1.sku_id = profit_table_s2.sku_id
group by profit_table_s1.sku_id

-- 3
-- revenue per sku firts semester
create table revenue_table_s1 as 
Select packaging_used.sku_id, round(sum(quantity*(unit_price - unit_cost))::numeric, 2) as revenue_s1
From packaging_used, costs, prices
where packaging_used.use_date <= '06/30/2022 23:59:59' and
costs.valid_until <= '6/30/2022 23:59:59' and 
prices.valid_until <= '6/30/2022 23:59:59' and 
packaging_used.sku_id=costs.sku_id and
packaging_used.sku_id=prices.sku_id
Group by packaging_used.sku_id 
order by sku_id;

-- revenue per sku second semester
create table revenue_table_s2 as 
Select packaging_used.sku_id, round(sum(quantity*(unit_price - unit_cost))::numeric, 2) as revenue_s2
From packaging_used, costs, prices
where packaging_used.use_date >= '7/01/2022 00:00:00' and
costs.valid_until >= '7/01/2022 00:00:00' and 
prices.valid_until >= '7/01/2022 00:00:00' and 
packaging_used.sku_id=costs.sku_id and
packaging_used.sku_id=prices.sku_id
Group by packaging_used.sku_id 
order by sku_id;

-- total revenue 2022 per sku
create table revenue_table_2022 as
select revenue_table_s1.sku_id, sum(revenue_table_s1.revenue_s1 + revenue_table_s2.revenue_s2) as revenue_total
from revenue_table_s1
join revenue_table_s2 on revenue_table_s1.sku_id = revenue_table_s2.sku_id
group by revenue_table_s1.sku_id


-- 4
-- margin profit per sku firts semester
create table margin_profit_s1 as 
Select prices.sku_id, round(((unit_price - unit_cost)/unit_price)::numeric, 2) as profit_margin_s1
From costs, prices
where costs.valid_until <= '6/30/2022 23:59:59' and 
prices.valid_until <= '6/30/2022 23:59:59' and 
prices.sku_id=costs.sku_id

-- revenue per sku second semester
create table margin_profit_s2 as 
Select prices.sku_id, round(((unit_price - unit_cost)/unit_price)::numeric, 2) as profit_margin_s2
From costs, prices
where costs.valid_until >= '7/01/2022 00:00:00' and 
prices.valid_until >= '7/01/2022 00:00:00' and 
prices.sku_id=costs.sku_id
-- 
-- join all tables and export it
copy(
Select *
from skus
join usage_table_s1 using (sku_id)
join usage_table_s2 using (sku_id)
join usage_table_2022 using (sku_id)
join profit_table_s1 using (sku_id)
join margin_profit_s1 using (sku_id)
join profit_table_s2 using (sku_id)
join margin_profit_s2 using (sku_id)
join profit_table_2022 using (sku_id)
join revenue_table_s1 using (sku_id)
join revenue_table_s2 using (sku_id)
join revenue_table_2022 using (sku_id)
	
  ) to '/Users/patasa/Desktop/pgAdmin-SQL/query_tables/join_table.csv' Delimiter ',' csv header;
  
