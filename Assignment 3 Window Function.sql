-- Question 1) Rank the customers based on the total amount they've spent on rentals.
select c.customer_id, concat(c.first_name, ' ', c.last_name) as Customer_name,
 sum(amount) as total_amount, rank() over (order by sum(amount) desc) as rank_no
 from customer c inner join rental r on c.customer_id = r.customer_id
 inner join payment p on r.rental_id = p.rental_id
 group by customer_id
 order by total_amount;
 
-- Question 2) Calculate the cumulative revenue generated by each film over time.
select f.film_id, f.title, p.payment_date, p.amount, sum(p.amount) over (partition by f.film_id order by p.payment_date) as total_revenue
from film f 
inner join inventory i on f.film_id = i.film_id 
inner join rental r on i.inventory_id = r.inventory_id
inner join payment p on r.rental_id =p.rental_id
order by f.film_id, p.payment_date;

-- Question 3) Determine the average rental duration for each film, considering films with similar lengths.
select film_id, title, length, rental_duration, avg(rental_duration) over (partition by length) as average_rental_duration
from film 
order by film_id;

-- Question 4) Identify the top 3 films in each category based on their rental counts.
with rankedfilm as (
select f.film_id, f.title, c.name as category, count(rental_id) as rental_count,
row_number() over (partition by c.name order by count(rental_id) desc) as ranking
from film f 
inner join film_category fc on f.film_id = fc.film_id
inner join category c on fc.category_id = c.category_id
inner join inventory i on f.film_id = i.film_id
inner join rental r on i.inventory_id = r.inventory_id
group by f.film_id, f.title, c.name)
select film_id, title, category, rental_count
from rankedfilm
where ranking <= 3;

-- Question 5) Calculate the difference in rental counts between each customer's total rentals and the average rentals across all customers.
WITH CustomerRentalCounts AS (
SELECT customer_id, COUNT(rental_id) AS total_rentals,
AVG(COUNT(rental_id)) OVER () AS avg_rentals_across_all_customers
FROM rental
GROUP BY customer_id
)
select customer_id, total_rentals, avg_rentals_across_all_customers,
total_rentals - avg_rentals_across_all_customers as rental_count_difference
from CustomerRentalCounts;

-- Question 6) Find the monthly revenue trend for the entire rental store over time
SELECT DATE_FORMAT(rental_date, '%Y-%m') AS YearMonth,
SUM(rental_rate * rental_duration) AS monthly_revenue
FROM rental
JOIN inventory ON rental.inventory_id = inventory.inventory_id
JOIN film ON inventory.film_id = film.film_id
GROUP BY DATE_FORMAT(rental_date, '%Y-%m')
ORDER BY DATE_FORMAT(rental_date, '%Y-%m');

-- Question 7) Identify the customers whose total spending on rentals falls within the top 20
with CustomerSpending AS (
select customer_id, sum(amount) as total_spending,
dense_rank() over (order by sum(amount) desc) as spending_rank
from payment
group by customer_id)
select customer_id, total_spending, spending_rank
from CustomerSpending
where spending_rank <= 20;

-- Question 8) Calculate the running total of rentals per category, ordered by rental count.
with CategoryRentalCounts AS (
select c.name as category,
count(r.rental_id) AS rental_count,
row_number () over (order by count(r.rental_id) desc ) as rental_rank
from rental r 
inner join inventory i on r.inventory_id = i.inventory_id
inner join film_category fc on i.film_id = fc.film_id
inner join category c on fc.category_id = c.category_id
group by c.name)
select category, rental_count, 
sum(rental_count) over(order by rental_rank) as running_total_rentals
from CategoryRentalCounts
order by rental_rank;

-- Question 9) Find the films that have been rented less than the average rental count for their respective categories.
With FilmRentalCount AS (
select f.film_id, fc.category_id, count(r.rental_id) AS rental_count, avg(count(r.rental_id)) over (partition by fc.category_id) AS avg_rental_count
from film f inner join film_category fc on f.film_id = fc.film_id
left join inventory i on f.film_id = i.film_id
left join rental r on i.inventory_id = r.inventory_id
group by f.film_id, fc.category_id )
select f.film_id, f.title, fc.category_id, frc.rental_count, frc.avg_rental_count
from FilmRentalCount frc
inner join film f on frc.film_id = f.film_id
inner join film_category fc on frc.film_id = fc.film_id
where frc.rental_count < frc.avg_rental_count;

-- Question 10)  Identify the top 5 months with the highest revenue and display the revenue generated in each month.
with MonthlyRevenue as (
select date_format(p.payment_date, '%y-%m') As month,
sum(p.amount) as Revenue,
Rank () over (order by sum(p.amount) desc) as revenue_rank
from payment p 
group by month )
select month, Revenue from MonthlyRevenue
where revenue_rank <= 5
order by Revenue desc;


























