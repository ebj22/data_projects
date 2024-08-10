use sales_db;

select * from sales_exercise; 

-- store 20. What was the total (rounded) profit of this store? 

select round(sum(Weekly_Sales), 0) 
from sales_exercise
where store = 20
group by store;

-- 2. What was the total profit for department 51 (store 20)?

select sum(Weekly_Sales) 
from sales_exercise
where store = 20 and dept = 51
group by store, dept;

-- 3. In which week did store 20 achieve a profit record (for the whole store)? How much profit did they make? 

with cte_week1 as(
select distinct store, date, round(sum(Weekly_Sales) over (
partition by store, date
), 2) tot_week_sale
from sales_exercise
where store = 20)
select Date, tot_week_sale -- (select max(tot_week_sale) from cte_week1) as max_profit
from cte_week1
order by tot_week_sale desc
limit 1;

-- 4. Which was the worst week for store 20 (for the whole store)? How much was the profit?

with cte_week1 as(
select distinct Store, Date, round(sum(Weekly_Sales) over (
partition by Store, date
), 2) tot_week_sale
from sales_exercise
where Store = 20)
select Date, tot_week_sale -- (select max(tot_week_sale) from cte_week1) as max_profit
from cte_week1
order by tot_week_sale asc
limit 1;

-- 5. What is the (rounded) average of the weekly sales for store 20 (the whole store)?

select round(avg(Weekly_Sales), 0) 
from sales_exercise
where Store = 20
group by Store;

-- 6. What are the 3 stores that have the best historical average of weekly sales?

with cte_week_avg as(
select distinct Store, round(avg(Weekly_Sales) over (
partition by Store
), 2) as avg_week
from sales_exercise)
select Store, avg_week
from cte_week_avg
order by avg_week desc
limit 5;

-- 7. Which departments from store 20 were the best and the worst in terms of overall sales?

with cte_dept1 as(
select distinct Store, Dept, round(sum(Weekly_Sales) over (
partition by Store, Dept
), 2) tot_dept_sale
from sales_exercise
where Store = 20)
select 
(select Dept 
from cte_dept1
where tot_dept_sale = (select max(tot_dept_sale) from cte_dept1)) as best_sale_dept,
(select Dept 
from cte_dept1
where tot_dept_sale = (select min(tot_dept_sale) from cte_dept1)) as worst_sale_dept; 


-- 8. How much profit does the average department make in store 20?

with cte_avg_dept1 as (
select distinct store, dept, round(sum(Weekly_Sales) over (
partition by store, dept
), 2) tot_dept_sale2
from sales_exercise
where Store = 20)
select round(avg(tot_dept_sale2), 0) as avg_dept_profit
from cte_avg_dept1;


-- 9. Consider store 20. Calculate the difference between the total profit of each 
-- department and the total profit of the average department. This will be the 
-- departments’ “performance metric”. Which department is the worst performer and what’s its performance?

-- drop function if exists diff_;
delimiter $$

create function diff_( tot_prof_dept decimal(12, 2) )
returns decimal(12, 2)
not deterministic
reads sql data

begin
declare var_1 decimal(12, 2);

with cte_avg_dept1 as (
select distinct Store, Dept, round(sum(Weekly_Sales) over (
partition by store, dept
), 2) tot_dept_sale2
from sales_exercise
where store = 20)
select round(avg(tot_dept_sale2), 0) into var_1 
from cte_avg_dept1;

set var_1 = round(tot_prof_dept - var_1, 0);

return var_1;

end$$

delimiter ;

with cte_diff1 as (
select distinct store, dept, round(sum(Weekly_Sales) over (
partition by store, dept
), 2) tot_dept_sale2
from sales_exercise
where store = 20)
select dept, diff_(tot_dept_sale2)
from cte_diff1
order by diff_(tot_dept_sale2) asc
limit 3;

-- or

with cte_diff1 as (
select distinct Store, Dept, round(sum(Weekly_Sales) over (
partition by Store, Dept
), 2) tot_dept_sale2
from sales_exercise
where Store = 20),
cte_d2 as (
select Dept, diff_(tot_dept_sale2) as dif2
from cte_diff1
order by diff_(tot_dept_sale2) asc
limit 3)
select * 
from cte_d2
order by dif2;



-- 10. Which department-store combination is the overall best performer (and what’s its performance?)? Consider the performance 
-- metric from the previous question, that is, the difference between a department’s sales and the sales of the average department of the corresponding store.


-- drop function diff_4;
delimiter $$

create function diff_4( tot_prof_dept4 decimal(12, 2) )
returns decimal(12, 2)
not deterministic
reads sql data

begin
declare var_4 decimal(12, 2);

with cte_avg_dept4 as (
select distinct store, dept, round(sum(Weekly_Sales) over (
partition by Store, Dept
), 2) tot_dept_sale4
from sales_exercise)
select round(avg(tot_dept_sale4), 0) into var_4 
from cte_avg_dept1;

set var_4 = round(tot_prof_dept4 - var_4, 0);

return var_4;

end$$

delimiter ;


-- ********* crashes the connection each time i try to run it, it take a long time to complete running leading to the crash of the connection 
with cte_dept_store4 as (
select distinct store, dept, round(sum(Weekly_Sales) over (
partition by store, dept
), 2) tot_dept_sale4
from sales_exercise)
select Store, Dept, diff_4(tot_dept_sale4)
from cte_dept_store4
order by diff_4(tot_dept_sale4) desc
limit 3;


-- ****** OR 


delimiter $$

create function diff_5( var1 decimal(12, 2), var2 decimal(12, 2) )
returns decimal(12, 2)
not deterministic
reads sql data

begin
declare var_5 decimal(12, 2);

with cte_avg_dept5 as (
select distinct store, dept, round(sum(Weekly_Sales) over (
partition by store, dept
), 2) tot_dept_sale5
from sales_exercise
where store = var1)
select round(avg(tot_dept_sale5), 0) into var_5 
from cte_avg_dept5;

set var_5 = round(var2 - var_5, 0);

return var_5;

end$$

delimiter ;

with cte_dept_store5 as (
select distinct store, dept, round(sum(Weekly_Sales) over (
partition by Store, Dept
), 2) as tot_dept_sale5
from sales_exercise)
select store, dept, diff_5(store, tot_dept_sale5)
from cte_dept_store5
order by diff_5(store, tot_dept_sale5) desc
limit 3;



-- *** This one actually works because it is running on only two stores (20, 5) 
with cte_dept_store4 as (
select distinct store, ddept, round(sum(Weekly_Sales) over (
partition by store, dept
), 2) as tot_dept_sale4
from sales_exercise
where store in (20, 5))
select store, dept, diff_4(tot_dept_sale4)
from cte_dept_store4
order by diff_4(tot_dept_sale4) desc
limit 3;


-- ***** Alternative Solution, but i am not sure if its correct
select round(avg(Weekly_Sales), 2) into @tot_prof_avg
from sales_exercise;

with cte_dept_store4 as (
select distinct store, dept, round(sum(Weekly_Sales) over (
partition by store, dept
), 2) as tot_dept_s4
from sales_exercise)
select store, dept, tot_dept_s4 - @tot_prof_avg as metric
from cte_dept_store4
order by tot_dept_s4 - @tot_prof_avg desc
limit 3;


