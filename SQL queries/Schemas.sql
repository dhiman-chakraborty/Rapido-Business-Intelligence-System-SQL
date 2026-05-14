CREATE TABLE customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(100),
    gender VARCHAR(10),
    age INT,
    city VARCHAR(50),
    signup_date DATE,
    total_rides INT,
    loyalty_level VARCHAR(20)
);

CREATE TABLE drivers(
      driver_id VARCHAR(50) PRIMARY KEY,
      driver_name VARCHAR(100),
      vehicle_type VARCHAR(20),
      city VARCHAR(20),
      joining_date DATE,
      avg_rating NUMERIC(2,1),
      total_trips INT,
      monthly_earnings INT,
      onlive_hours INT
)

CREATE TABLE trips(
     trip_id VARCHAR(50) PRIMARY KEY,
	 customer_id VARCHAR(50) REFERENCES customers(customer_id),
	 driver_id VARCHAR(50) REFERENCES drivers(driver_id),
	 booking_time TIMESTAMP,
	 city VARCHAR(50),
	 pickup_area VARCHAR(50),
	 drop_area VARCHAR(50),
	 ride_type VARCHAR(20),
	 distance_km NUMERIC(3,1),
	 duration_min INT,
	 fare_amount NUMERIC(5,1),
     surge_multiplier NUMERIC(3,1),
     weather VARCHAR(20),
	 trip_status VARCHAR(20),
	 payment_method VARCHAR(20),
     rating NUMERIC(2,1)
)

--ADDing booking date column
ALTER TABLE trips 
ADD COLUMN booking_date DATE

--UPDATE booking date column
UPDATE trips
SET booking_date = booking_time::DATE

CREATE TABLE payments(
     payment_id VARCHAR(50) PRIMARY KEY,	
	 trip_id VARCHAR(50) REFERENCES trips(trip_id),	
	 payment_time TIMESTAMP,	
	 amount	NUMERIC(6,1),
	 payment_status	VARCHAR(50),
	 gateway VARCHAR(20),	
	 coupon_used VARCHAR(30),	
	 cashback INT
)

CREATE TABLE complaints(
     complaint_id VARCHAR(50) PRIMARY KEY,	
	 trip_id VARCHAR(50) REFERENCES trips(trip_id),	
	 issue_type VARCHAR(100),	
	 raised_by VARCHAR(50),	
	 resolution_time_hr	INT,
	 refund_amount NUMERIC(5,2),	
	 support_rating NUMERIC(3,1)
)

CREATE TABLE weather_traffic(
     date DATE,
	 city VARCHAR(50),	
	 weather VARCHAR(20),	
	 traffic_level VARCHAR(20),	
	 avg_surge NUMERIC(3,1),	
	 avg_trip_time INT
)








 

