create database zomato;


use zomato;

select count(*) from data;



-- ----------------------------------------  CREATING TABLE STRUCTURE  ---------------------------
create table data
(
Restaurant_ID int,
Restaurant_Name varchar(255),
Country_Code int,
City varchar(50),
Locality varchar(255),
Cuisines varchar(255),
Currency varchar(255),
Has_Table_Booking varchar(50),
Has_Online_Delivery varchar(50),
Is_delivering_now varchar(50),
Switch_to_order_menu varchar(50),
Price_range int,
Votes int,
Average_Cost_for_two int,
Rating double,
Datekey_Opening date
);

select * from data;

-- show variables like "secure_file_priv";


--  -------------------------------------------- LOAD FILE TO MYSQL WORKBENCH ------------------------------
load data infile 'Data.csv' into table data
fields terminated by ','
ignore 1 lines;

select count(*) from data;
select * from data;


-- ------------------------------------------- CREATING DATE TABLE -----------------------------------------

select year(datekey_opening) as Year,
		month(datekey_opening) as MonthNo,
        monthname(datekey_opening) as MonthfullName,
        concat('Q', quarter(datekey_opening)) as Quarter,
        concat(year(datekey_opening), '-',  monthname(datekey_opening)) as YearMonth,
        weekday(datekey_opening) Weekdayno,
        dayname(datekey_opening) as WeekDayName,
        
        if(month(datekey_opening) < 4, 
        concat('FM', month(datekey_opening) + 9),
        concat('FM', month(datekey_opening) - 3)) as FinancialMonth,
        
        case when monthname(datekey_opening) in ('January','February','March') then 'FQ-4'
			when monthname(datekey_opening) in ('April','May','June') then 'FQ-1'
            when monthname(datekey_opening) in ('July','August','September') then 'FQ-2'
            else 'FQ-3'
		end as FinancialQuarter
from data;


-- --------------------------------------  CONVERTING AVERAGE COST FOR TWO PEOPLE IN USD  ----------------------------------------

set SQL_SAFE_UPDATES=0;	-- To create new column in existing table disable safe updates.

alter table data add column Cost_for_two_USD double;	-- Create new cost_for_two_usd column.

update Data D 
join Currency C on D.Currency = C.Currency
set D.Cost_for_two_USD = ROUND(D.Average_Cost_for_two * C.USDRate, 2) 
where D.Cost_for_two_USD is null;

set SQL_SAFE_UPDATES=1;


-- ----------------------------------------------- NUMBER OF RESTAURANTS IN EACH COUNTRY -------------------------------------
select C.Countryname, count(*) as restaurants
from Data D
join Country C on D.Country_Code = C.CountryID
group by C.Countryname
order by restaurants desc;


-- ----------------------------------------------- NUMBER OF RESTAURANTS IN EACH CITY -------------------------------------

select C.Countryname, D.City, count(*) as restaurants
from Data D
join Country C on D.Country_Code = C.CountryID
group by C.Countryname, D.City
order by restaurants desc;


-- ---------------------------------------------- RESTAURANTS OPENING STATS FOR YEAR, QUARTER AND MONTH ---------------------------------

select year(datekey_opening) as Year,
	monthname(datekey_opening) as Month,
	quarter(datekey_opening) as Quarter,
    count(*) as Restaurants from data
group by Year, Month, Quarter
order by year; 


-- --------------------------------------------- RESTAURANTS BASED ON USER AVERAGE RATING ----------------------------------------------

select case  
        when Rating <= 1 then '1'
        when Rating <= 2 then '2'
        when Rating <= 3 then '3'
        when Rating <= 4 then '4'
        else '5'
end as Ratings,
count(Restaurant_ID) as Restaurants
from data
group by Ratings
order by Ratings;


-- -------------------------------------------------- AVERAGE PRICE BUCKET -----------------------------------------------------

select case when Cost_for_two_USD <= 10 then "10$"
			when Cost_for_two_USD <= 20 then "20$"
            when Cost_for_two_USD <= 30 then "30$"
            when Cost_for_two_USD <= 40 then "40$"
            when Cost_for_two_USD <= 50 then "50$"
			else ">50$"
		end as Cost_Bucket,
        count(Restaurant_ID) as Restaurants
from Data
group by Cost_Bucket
order by Restaurants Desc;


-- ---------------------------------------------- RESTAURANTS PROVIDING TABLE BOOKINGS -------------------------------------------------

select Has_Table_Booking as TableBooking, count(restaurant_ID) as Restaurants,
concat(round((count(restaurant_ID)/100)),'%') as Restaurants_Percent 
from Data 
group by TableBooking;


-- --------------------------------------------- RESTAURANTS PROVIDING ONLINE DELIVERY --------------------------------------------------

select Has_Online_Delivery as OnlineDelivery, count(restaurant_ID) as Restaurants,
concat(round((count(restaurant_ID)/100)),'%') as Restaurants_Percent 
from Data 
group by OnlineDelivery;

-- ----------------------------------------------- COUNTRY WISE DINING COST FOR TWO PEOPLE -----------------------------------------------

select C.Countryname, round(avg(D.Cost_for_two_USD)) as Cost
	from Data D
join Country C on C.CountryID = D.Country_Code
group by C.Countryname
order by Cost desc;
    
    
    
    
-- --------------------------------------------------------- UNIQUE CUISINES --------------------------------------------------------

select count(*) as Unique_Cuisines from (
SELECT DISTINCT
    TRIM(BOTH ' ' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(t.cuisines, '&', numbers.n), '&', -1)) AS cuisine
FROM
    (SELECT 1 n 
     UNION ALL SELECT 2 
     UNION ALL SELECT 3 
     UNION ALL SELECT 4 
     -- more unions if you expect more cuisines
    ) numbers INNER JOIN data t
    ON CHAR_LENGTH(t.cuisines)
       -CHAR_LENGTH(REPLACE(t.cuisines, '&', '')) >= numbers.n-1 ) as unique_cuisines;
       
       
       