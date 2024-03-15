use retail_events_db;

/*fact_events_retails_view view will allow you to easily retrieve information about retail events, 
 the quantity after a promo code is applied and the revenue before and after applying the promo code */
 
create view fact_events_retails_view as
select * ,
case when promo_type = "BOGOF" then quantity_sold_after_promo*2
else quantity_sold_after_promo
end unit_sold_after_promo,
(base_price*quantity_sold_before_promo) as revenue_before_promo,
case when promo_type = "BOGOF" then (base_price*quantity_sold_after_promo*2)-(base_price*quantity_sold_after_promo*2*0.5)
	when  promo_type = "25% OFF"  then (base_price*quantity_sold_after_promo)-(base_price*quantity_sold_after_promo*0.25)
	when promo_type = "33% OFF"  then (base_price*quantity_sold_after_promo)-(base_price*quantity_sold_after_promo*0.33)
	when promo_type = "50% OFF"  then (base_price*quantity_sold_after_promo)-(base_price*quantity_sold_after_promo*0.5)
	else (base_price*quantity_sold_after_promo)-(500*quantity_sold_after_promo)
end as revenue_after_promo
from fact_events;

/*Q1.  Provide a list of products with a base price greater than 500 and that are featured in promo type of 'BOGOF' (Buy One Get One Free).
This information will help us identify high-value products that are currently being heavily discounted, which can be useful for evaluating 
our pricing and promotion strategies.*/

select product_name ,base_price, promo_type
from dim_products p
left join fact_events_retails_view f
on p.product_code = f.product_code
where f.promo_type = "BOGOF" 
and base_price > 500 ;


/*Q2.Generate a report that provides an overview of the number of stores in each city. 
The results will be sorted in descending order of store counts, allowing us to identify the cities with the highest store presence.
The report includes two essential fields: city and store count, which will assist in optimizing our retail operations.  */
select s.city ,count(s.store_id) store_count
from dim_stores s 
left join fact_events_retails_view f
on s.store_id = f.store_id 
group by city
order by count(s.store_id) desc;


/*Q3. Generate a report that displays each campaign along with the total revenue generated before and after the campaign? 
The report includes three key fields: campaign_name, totaI_revenue(before_promotion), totaI_revenue(after_promotion). 
This report should help in evaluating the financial impact of our promotional campaigns. (Display the values in millions)*/

with revenue_cte as
(select campaign_id, 
sum(revenue_before_promo) total_revenue_before_promo,
sum(revenue_after_promo) total_revenue_after_promo
from fact_events_retails_view f
group by campaign_id)
select c.campaign_name , 
round((rc.total_revenue_before_promo/1000000),2)  as 'total_revenue_before_promo in millions' ,
round((rc.total_revenue_after_promo/1000000),2) as 'total_revenue_after_promo in millions'
from dim_campaigns c
left join revenue_cte rc
on c.campaign_id= rc.campaign_id;

/*Q4. Produce a report that calculates the Incremental Sold Quantity (ISU%) for each category during the Diwali campaign. 
Additionally, provide rankings for the categories based on their ISU%. 
The report will include three key fields: category, isu%, and rank order. 
This information will assist in assessing the category-wise success and impact of the Diwali campaign on incremental sales
*/

with isu_cte as
(select p.category,
((sum(unit_sold_after_promo)-sum(quantity_sold_before_promo))/sum(quantity_sold_before_promo)*100) ISU_Percent
from dim_products p
left join fact_events_retails_view f
on p.product_code = f.product_code
where campaign_id = "CAMP_DIW_01"
group by p.category
)
select category,
round(ISU_Percent,2) "ISU%",
rank() over(order by ISU_Percent DESC) as 'rank'
from isu_cte ;

/*Q5. Create a report featuring the Top 5 products, ranked by Incremental Revenue Percentage (IR%), across all campaigns. 
The report will provide essential information including product name, category, and ir%.
This analysis helps identify the most successful products in terms of incremental revenue across our campaigns, assisting in product optimization.*/

select p.product_name,p.category,
round(((sum(base_price*quantity_sold_after_promo)-sum(base_price*quantity_sold_before_promo))/sum(base_price*quantity_sold_before_promo))*100,2) IR_Percetage
from dim_products p
left join fact_events_retails_view f
on p.product_code = f.product_code
group by p.category,p.product_name
order by IR_Percetage desc
limit 5;





 



