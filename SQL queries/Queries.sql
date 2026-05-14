select * from customers
select * from drivers
select * from trips
select * from payments
select * from complaints
select * from weather_traffic

--1.Total Revenue Per City
SELECT city,SUM(fare_amount*surge_multiplier) AS revenue
FROM trips
WHERE trip_status = 'Completed'
GROUP BY 1
ORDER BY 2 DESC;

--2.Top 10 Highest Earning Drivers
SELECT d.driver_id,d.driver_name,d.vehicle_type,d.city,d.avg_rating,
       sum(t.fare_amount*surge_multiplier) AS total_earning
FROM drivers d 
LEFT JOIN trips t USING (driver_id)
WHERE t.trip_status = 'Completed'
GROUP BY 1,2,3,4,5
ORDER BY 6 DESC
LIMIT 10;

--3.Average Fare By Ride Type
SELECT ride_type,ROUND(AVG(fare_amount*surge_multiplier),2) AS avg_fare
FROM trips
WHERE trip_status = 'Completed'
GROUP BY 1;

--4.Peak Booking Hours by cities
SELECT city,EXTRACT(HOUR FROM booking_time) AS booking_hour,
       COUNT(*) AS no_of_booking
FROM trips
GROUP BY 1,2
ORDER BY 1,3 DESC;

--5.Cancellation Rate by City
WITH can AS(
SELECT city, COUNT(*) FILTER(WHERE trip_status = 'Cancelled') AS cancelled_rides
FROM trips
GROUP BY 1),
tot AS(
SELECT city, COUNT(*)  AS total_rides
FROM trips
GROUP BY 1)
SELECT c.city,c.cancelled_rides,t.total_rides,
       ROUND((c.cancelled_rides::NUMERIC/t.total_rides::NUMERIC)*100,2) AS cancellation_pct
FROM can c
JOIN tot t USING (city)
GROUP BY 1,2,3;

--6.Monthly Revenue Trend
SELECT TO_CHAR(booking_time,'FMmonth')||' '||EXTRACT(YEAR FROM booking_time) AS month_year,
       SUM(fare_amount*surge_multiplier) AS revenue
FROM trips
GROUP BY 1
ORDER BY 2 DESC;

--7.Drivers With Rating Above Average with complaints
SELECT d.driver_id,d.driver_name,d.avg_rating,COUNT(*) AS no_of_complaints
FROM drivers d
LEFT JOIN trips USING (driver_id)
LEFT JOIN complaints USING (trip_id)
WHERE d.avg_rating>(
     SELECT AVG(avg_rating)
	 FROM drivers
)
GROUP BY 1,2,3;

--8.Most Frequently Used Payment Method
SELECT gateway,
       COUNT(*) AS no_of_payments,
       DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS ranking
FROM payments
WHERE payment_status = 'Success'
GROUP BY 1;

--9.Daily Ride Count
SELECT booking_date,COUNT(*) AS total_bookings
FROM trips
GROUP BY 1
ORDER BY 1;

--10.Revenue Lost Due to Cancellations
SELECT SUM(fare_amount*surge_multiplier) AS cancellation_revenue
FROM trips
WHERE trip_status = 'Cancelled';


--11.Weather Impact on Ride Demand
SELECT w.date,w.city,w.weather,
       COUNT(t.*) AS total_bookings,
	   SUM(t.fare_amount*surge_multiplier) AS total_revenue
FROM weather_traffic w
LEFT JOIN trips t ON w.date = t.booking_date
WHERE t.trip_status = 'Completed'
GROUP BY 1,2,3
ORDER BY 1;

--12.Highest Surge Pricing Days
SELECT booking_date,MAX(surge_multiplier) AS max_surge
FROM trips
GROUP BY 1
ORDER BY 2 DESC LIMIT 10;

--13.Customer Lifetime Value
SELECT c.customer_id,c.customer_name,c.city,
       COUNT(t.*) AS no_of_bookings,
	   COUNT(t.*) FILTER(WHERE t.trip_status='Cancelled') AS no_of_cancellation,
       COALESCE(SUM(t.fare_amount*t.surge_multiplier) FILTER(WHERE t.trip_status='Completed'),0) AS total_spent_amount
FROM customers c
LEFT JOIN trips t USING (customer_id)
GROUP BY 1,2,3
ORDER BY 1;

--14.Repeat Customers
SELECT c.customer_id,c.customer_name
FROM customers c
LEFT JOIN trips t USING (customer_id)
WHERE t.trip_status = 'Completed'
GROUP BY 1,2
HAVING COUNT(t.*)>=2
ORDER BY 1;

--15.Average Trip Duration by City(ride type)
SELECT city,ride_type,
       ROUND(AVG(duration_min),2)||' '||'min' AS avg_trip_duration
FROM trips
GROUP BY 1,2
ORDER BY 1,2;

--16.Weekend vs Weekday Revenue
SELECT CASE
       WHEN EXTRACT(DOW FROM booking_date) IN (0,5) THEN 'Weekday'
	   ELSE 'Weekend'
	   END AS day_type,
	   COUNT(*) AS no_of_trips,
	   SUM(fare_amount*surge_multiplier) AS trip_amount
FROM trips
WHERE trip_status = 'Completed'
GROUP BY 1;

--17.Most Active Drivers from each city(Top 5)
WITH driver_rank AS(
SELECT d.city,d.driver_id,d.driver_name,d.vehicle_type,
       COUNT(t.*) AS no_of_trips,
	   SUM(t.fare_amount*t.surge_multiplier) AS total_income,
	   ROW_NUMBER() OVER(PARTITION BY d.city ORDER BY SUM(t.fare_amount*t.surge_multiplier) DESC) AS ranking
FROM drivers d
JOIN trips t USING (driver_id)
WHERE trip_status = 'Completed'
GROUP BY 1,2,3,4)
SELECT *
FROM driver_rank
WHERE ranking<=5;

--18.Top Revenue Generating Dates
SELECT booking_date,
       SUM(fare_amount * surge_multiplier) AS gross_revenue
FROM trips
WHERE trip_status = 'Completed'
GROUP BY 1
ORDER BY 2 DESC LIMIT 10;

--19.Payment Failure Rate by Payments Gateways
WITH pt AS(
SELECT gateway,
       COUNT(*) FILTER(WHERE payment_status = 'Failed') AS failed_payment,
	   COUNT(*) AS total_payment
FROM payments
GROUP BY 1)
SELECT gateway,failed_payment,total_payment,
       ROUND((failed_payment::NUMERIC/total_payment)*100,2) AS payment_faliure_rate
FROM pt
GROUP BY 1,2,3;

--20.Running Revenue Total
SELECT booking_date,
       SUM(fare_amount * surge_multiplier) AS day_revenue,
	   SUM(SUM(fare_amount * surge_multiplier)) OVER(ORDER BY booking_date) AS cumsum_revenue
FROM trips
GROUP BY 1;

--21.Revenue by Weather
SELECT w.weather,
       SUM(t.fare_amount * t.surge_multiplier) AS revenue
FROM weather_traffic w
JOIN trips t ON w.date = t.booking_date
GROUP BY 1
ORDER BY 2 DESC;

--22.Most Common Complaint Type last month
SELECT c.issue_type,
       COUNT(c.*) AS no_of_complaints
FROM complaints c
JOIN trips t USING(trip_id)
WHERE t.booking_date < DATE_TRUNC('month',CURRENT_DATE) AND t.booking_date > DATE_TRUNC('month',CURRENT_DATE) - INTERVAL'30 days'
GROUP BY 1;

--23.Dynamic Surge Impact on Revenue
SELECT CASE
       WHEN surge_multiplier<=1.5 THEN 'low surge'
	   WHEN surge_multiplier<=2.5 THEN 'medium surge'
	   ELSE 'high surge' END AS surge_type,
	   COUNT(*) AS no_of_order,
	   SUM(fare_amount*surge_multiplier) AS revenue,
	   ROUND(AVG(fare_amount*surge_multiplier),2) AS avg_fare
FROM trips
WHERE trip_status = 'Completed'
GROUP BY 1
ORDER BY 2 DESC;

--24.Customer Churn Prediction Candidates(Customers inactive for last 60 days.)
WITH lb AS(
SELECT c.customer_id,c.customer_name,
       MAX(t.booking_date) AS last_booking
FROM customers c
LEFT JOIN trips t USING (customer_id)
GROUP BY 1)
SELECT customer_id,customer_name,last_booking,
       CURRENT_DATE - last_booking AS inactive_days
FROM lb
WHERE last_booking < CURRENT_DATE-INTERVAL'60 days'
ORDER BY 4 DESC;

--25.Rain vs Non-Rain Profitability city-wise
WITH rd AS(
SELECT w.city,
       CASE
	   WHEN w.weather IN ('Rain','Heavy Rain') THEN 'Rainy Day'
	   ELSE 'Non-Rainy Day' END AS weather_daytype,
       COUNT(t.*) AS no_of_trips,
	   SUM(t.fare_amount*t.surge_multiplier) AS revenue,
	   ROUND(AVG(t.fare_amount*t.surge_multiplier),2) AS avg_fare,
	   ROUND(AVG(t.surge_multiplier),2) AS avg_surge
FROM weather_traffic w
JOIN trips t ON w.date=t.booking_date
GROUP BY 1,2
ORDER BY 1,2 ASC,4 DESC),
pv AS(
SELECT city,weather_daytype,no_of_trips,revenue,avg_fare,avg_surge,
       LAG(revenue) OVER(ORDER BY city) AS pv_value
FROM rd)
SELECT city,weather_daytype,no_of_trips,revenue,avg_fare,avg_surge,pv_value,
       ROUND(((pv_value-revenue)/pv_value)*100,2) AS pct_impact
FROM pv;	 


--26.Driver Efficiency Score(Combines ratings, trips, and earnings.)
SELECT d.driver_id,d.driver_name,d.city,d.vehicle_type,
       ROUND(
             AVG(t.rating)*0.3+
			 COUNT(t.*)*0.2+
			 SUM(t.fare_amount*t.surge_multiplier)/1000*0.4,2
	   ) AS efficiency_score
FROM drivers d
LEFT JOIN trips t USING (driver_id)
WHERE t.trip_status = 'Completed'
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

--27.Identify Fraudulent Cancellation Patterns(Drivers with abnormal cancellations.)
WITH cn AS(
SELECT d.driver_id,d.driver_name,d.vehicle_type,d.city,
       COUNT(t.*) FILTER(WHERE t.trip_status='Cancelled') AS cancelled_trips,
	   COUNT(*) AS total_trips
FROM drivers d
LEFT JOIN trips t USING(driver_id)
GROUP BY 1,2,3,4),
can AS(
SELECT driver_id,driver_name,vehicle_type,city,cancelled_trips,total_trips,
       ROUND((cancelled_trips::NUMERIC/total_trips)*100,2) AS cancellation_rate
FROM cn)
SELECT driver_id,driver_name,vehicle_type,city,cancelled_trips,total_trips,cancellation_rate
FROM can
WHERE cancellation_rate>30
ORDER BY 7 DESC;

--28.City Demand Forecasting Base Query(Moving average demand estimation)
WITH ct AS(
SELECT city,
       EXTRACT(MONTH FROM booking_time) AS months,
	   COUNT(*) AS total_rides
FROM trips
WHERE trip_status='Completed' AND EXTRACT(YEAR FROM booking_time)=2026
GROUP BY 1,2
ORDER BY 1,2),
gr AS(
SELECT city,months,total_rides,
       ROUND(
	         (total_rides - LAG(total_rides) OVER(PARTITION BY city ORDER BY months))::NUMERIC
			 /(LAG(total_rides) OVER(PARTITION BY city ORDER BY months))*100,2) AS growth_rate_pct
FROM ct
GROUP BY 1,2,3
ORDER BY 1,2)
SELECT city,months,total_rides,ROUND(total_rides*(100+AVG(growth_rate_pct))/100,2) AS next_month_ride_prediction
FROM gr
WHERE months=5
GROUP BY 1,2,3;

--29.MTD Growth
WITH mtd AS(
SELECT EXTRACT(MONTH FROM booking_time) AS months,
       EXTRACT(YEAR FROM booking_time) AS years,
       TO_CHAR(booking_time,'FMmonth')||' '||EXTRACT(YEAR FROM booking_time) AS month_year,
       SUM(fare_amount*surge_multiplier) AS gross_revenue
FROM trips
GROUP BY 1,2,3
ORDER BY 2,1)
SELECT months,years,month_year,gross_revenue,
       ROUND(
	   (gross_revenue-(LAG(gross_revenue) OVER(ORDER BY years,months)))/
	   (LAG(gross_revenue) OVER(ORDER BY years,months))*100,2)||'%' AS growth_rate
FROM mtd;

--30.Most Profitable Route Pairs(top 5)
WITH pr AS(
SELECT city,pickup_area,drop_area,
       ROUND(AVG(distance_km),2) AS distance,
	   SUM(fare_amount*surge_multiplier) AS revenue,
	   ROUND(AVG(fare_amount*surge_multiplier),2) AS avg_fare,
	   ROUND((AVG(fare_amount*surge_multiplier)/AVG(distance_km)),2) AS fare_km
FROM trips
GROUP BY 1,2,3
ORDER BY 1 ASC,5 DESC),
rn AS(
SELECT *,
       ROW_NUMBER() OVER(PARTITION BY city ORDER BY revenue DESC) AS ranking
FROM pr)
SELECT city,pickup_area,drop_area,distance,revenue,avg_fare,fare_km
FROM rn
WHERE ranking BETWEEN 1 AND 5;

