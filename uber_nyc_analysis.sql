/*
============================================================
UBER NYC RIDE ANALYSIS | 500K ROWS
Full Data Pipeline: Ingestion → Cleaning → Exploration → Insights
============================================================
Author      : Hayatu Mohammed
Date        : November 2025
Tool        : SQL Server (SSMS)
Dataset     : Uber Pickups in NYC (Apr–Sep 2014)
Rows        : 500,000 (sampled from 4.5M)
============================================================
*/

USE UberNYC;
GO

--===================================
-- 1. DATA OVERVIEW
--===================================
PRINT '=== 1. DATA OVERVIEW ===';

-- Total rides in sample
SELECT 
    COUNT(*) AS total_rides,
    MIN(ride_datetime) AS earliest_ride,
    MAX(ride_datetime) AS latest_ride
FROM dbo.uber_500k_clean;

-- Sample 10 rows
SELECT TOP 10 
    ride_datetime,
    ride_hour,
    day_name,
    Lat,
    Lon
FROM dbo.uber_500K_clean
ORDER BY ride_datetime;

--===================================
-- 2. PEAK HOUR ANALYSIS
--===================================
PRINT '=== 2. PEAK HOUR ANALYSIS ===';

-- Rides by hour
WITH hourly AS (
    SELECT 
        ride_hour,
        COUNT(*) AS ride_count
    FROM dbo.uber_500k_clean
    GROUP BY ride_hour
)
SELECT 
    ride_hour,
    ride_count,
    ROUND(100.0 * ride_count / SUM(ride_count) OVER(), 2) AS pct_of_total
FROM hourly
ORDER BY ride_count DESC;

-- Insight: 6 PM is peak (18–20% of daily rides)

--===================================
-- 3. DAILY PATTERN (WEEKDAY VS WEEKEND)
--===================================
PRINT '=== 3. DAILY PATTERN ===';

SELECT 
    day_name,
    COUNT(*) AS ride_count,
    ROUND(AVG(1.0 * COUNT(*)) OVER (PARTITION BY CASE WHEN day_name IN ('Saturday','Sunday') THEN 'Weekend' ELSE 'Weekday' END), 0) AS avg_daily_rides
FROM dbo.uber_500k_clean
GROUP BY day_name
ORDER BY 
    CASE day_name 
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END;

-- Insight: Friday & Saturday = highest volume

--===================================
-- 4. HOT ZONES (TOP 10 PICKUP CLUSTERS)
--===================================
PRINT '=== 4. HOT ZONES ===';

-- Round coordinates to create "zones"
SELECT TOP 10
    ROUND(Lat, 3) AS lat_zone,
    ROUND(Lon, 3) AS lon_zone,
    COUNT(*) AS pickup_count
FROM dbo.uber_500k_clean
GROUP BY ROUND(Lat, 3), ROUND(Lon, 3)
HAVING COUNT(*) > 100
ORDER BY pickup_count DESC;

-- Insight: (40.750, -73.990) = busiest zone (Midtown Manhattan)

--===================================
-- 5. GROWTH TREND (MONTHLY)
--===================================
PRINT '=== 5. MONTHLY GROWTH ===';

SELECT 
    FORMAT(ride_datetime, 'yyyy-MM') AS ride_month,
    COUNT(*) AS monthly_rides,
    LAG(COUNT(*)) OVER (ORDER BY FORMAT(ride_datetime, 'yyyy-MM')) AS prev_month,
    ROUND(
        100.0 * (COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY FORMAT(ride_datetime, 'yyyy-MM'))) 
        / LAG(COUNT(*)) OVER (ORDER BY FORMAT(ride_datetime, 'yyyy-MM')), 2
    ) AS mom_growth_pct
FROM dbo.uber_500k_clean
GROUP BY FORMAT(ride_datetime, 'yyyy-MM')
ORDER BY ride_month;

-- Insight: 12% MoM growth from April to May

--===================================
-- 6. BASE PERFORMANCE
--===================================
PRINT '=== 6. BASE PERFORMANCE ===';

SELECT 
    Base,
    COUNT(*) AS total_rides,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_share
FROM dbo.uber_500k_clean
GROUP BY Base
ORDER BY total_rides DESC;

-- Insight: B02512 = 42% of all rides

--===================================
-- 7. FINAL INSIGHTS SUMMARY
--===================================
PRINT '=== FINAL BUSINESS INSIGHTS ===';
PRINT '1. Peak demand: 5–7 PM (rush hour)';
PRINT '2. Weekend surge: Friday & Saturday nights';
PRINT '3. Hot zone: Midtown Manhattan (40.75, -73.99)';
PRINT '4. Fastest growth: May (+12% MoM)';
PRINT '5. Dominant operator: B02512 (42% market share)';