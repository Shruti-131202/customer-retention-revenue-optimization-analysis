-- PROJECT: Customer Retention & Revenue Optimization
-- Objective: Analyze customer behavior, identify high-value segments, and evaluate retention patterns

-- STEP 1 - Load raw Data
-- Objective: Import raw CSV data without transformations to preserve original structure for cleaning
-- Creating staging table with all columns as TEXT to avoid data type issues during import
SHOW VARIABLES LIKE 'secure_file_priv';
CREATE TABLE online_retail_staging (
    InvoiceNo TEXT,
    StockCode TEXT,
    Description TEXT,
    Quantity TEXT,
    InvoiceDate TEXT,
    UnitPrice TEXT,
    CustomerID TEXT,
    Country TEXT
);

-- Loading CSV data into staging table

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Online Retail Data Set.csv'
INTO TABLE online_retail_staging
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- STEP 2 - Clean and convert datatypes
-- Objective: Standardize data types and handle missing CustomerIDs for accurate analysis

CREATE TABLE online_retail_clean (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description TEXT,
    Quantity INT,
    InvoiceDate DATETIME,
    UnitPrice DECIMAL(10,2),
    CustomerID INT,
    Country VARCHAR(50)
);

-- Converting text fields into proper datatypes and handling blank CustomerID values
INSERT INTO online_retail_clean (
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country
)
SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CAST(NULLIF(CustomerID, '') AS UNSIGNED), -- converting empty strings to NULL
    Country
FROM online_retail_staging;

-- Validating row count after transformation
select count(*) from online_retail_clean;

-- STEP 3 - Create business-ready dataset
-- Objective: Remove invalid transactions (returns, negative values) to ensure accurate revenue calculation

CREATE TABLE retail_final AS
SELECT *
FROM online_retail_clean
WHERE Quantity > 0 
  AND UnitPrice > 0;
select count(*) from retail_final;

-- Adding primary key for uniqueness

ALTER TABLE retail_final 
ADD id INT AUTO_INCREMENT PRIMARY KEY;

-- Creating and updating REVENUE COLUMN (Quantity * UnitPrice)

ALTER TABLE retail_final ADD Revenue DECIMAL(12,2);
UPDATE retail_final
SET 
    Quantity = IFNULL(Quantity, 0),
    UnitPrice = IFNULL(UnitPrice, 0);
UPDATE retail_final
SET Revenue = IFNULL(Quantity,0) * IFNULL(UnitPrice,0);
-- describe table
describe retail_final;
-- checking any null value in revenue column 
SELECT *
FROM retail_final
WHERE Revenue IS NULL;
select count(*) from retail_final;

-- STEP 4 - Customer-level filtering
-- Objective: Remove transactions without CustomerID for customer-level analysis 

CREATE TABLE retail_customer AS
SELECT *
FROM retail_final
WHERE CustomerID IS NOT NULL;
select count(*) from retail_customer;

-- STEP 5- Business KPIs
-- Objective: Calculate key metrics for revenue, customer behavior, and retention

-- total customer
SELECT COUNT(DISTINCT CustomerID) AS total_customers from retail_customer;
-- total orders
select COUNT(DISTINCT InvoiceNo) AS total_orders from retail_final;
-- total revenue
select SUM(Revenue) AS total_revenue from retail_final;
-- Aov
select ROUND(SUM(Revenue) / COUNT(DISTINCT InvoiceNo), 2) AS AOV from retail_final;
-- Puchase frequency
select ROUND(COUNT(DISTINCT InvoiceNo) / COUNT(DISTINCT CustomerID), 2) AS purchase_frequency from retail_final;
-- Revenue per customer
select ROUND(SUM(Revenue) / COUNT(DISTINCT CustomerID), 2) AS revenue_per_customer from retail_customer;

-- Insight: These KPIs help evaluate revenue efficiency, customer engagement, and repeat purchase behavior

-- Repeat customer
SELECT 
    COUNT(*) AS repeat_customers
FROM (
    SELECT CustomerID
    FROM retail_customer
    GROUP BY CustomerID
    HAVING COUNT(DISTINCT InvoiceNo) > 1
) t;
-- Repeat Purchase Rate
SELECT 
    COUNT(*) AS repeat_customers,
    (SELECT COUNT(DISTINCT CustomerID) FROM retail_customer) AS total_customers,
    ROUND(
        COUNT(*) * 100.0 / 
        (SELECT COUNT(DISTINCT CustomerID) FROM retail_customer),
    2) AS repeat_purchase_rate
FROM (
    SELECT CustomerID
    FROM retail_customer
    GROUP BY CustomerID
    HAVING COUNT(DISTINCT InvoiceNo) > 1
) t;
-- customer level purchase frequency 
SELECT 
    ROUND(
        COUNT(DISTINCT InvoiceNo) * 1.0 / COUNT(DISTINCT CustomerID),
    2) AS customer_level_purchase_frequency 
FROM retail_customer;
-- Revenue loss due to null customer id 
SELECT 
    SUM(CASE WHEN CustomerID IS NULL THEN Revenue ELSE 0 END) AS unattributed_revenue,
    SUM(Revenue) AS total_revenue,
    ROUND(
        SUM(CASE WHEN CustomerID IS NULL THEN Revenue ELSE 0 END) * 100.0 / SUM(Revenue),
    2) AS percent_unattributed;
-- Country revenue 
SELECT 
    Country,
    COUNT(DISTINCT CustomerID) AS customers,
    SUM(Revenue) AS revenue,
    ROUND(SUM(Revenue) / COUNT(DISTINCT CustomerID),
            2) AS revenue_per_customer
FROM
    retail_final
GROUP BY Country
ORDER BY revenue DESC;
-- Business Insight:
-- Identifies top-performing geographies
-- Helps detect revenue concentration and market dependency risk

-- STEP 6- RFM Segmentation
-- Objective: Segment customers based on Recency, Frequency, and Monetary value to identify high-value and at-risk customers

-- recenent date in dataset
SELECT MAX(InvoiceDate) AS max_date
FROM retail_customer;

-- creating rfm base table
CREATE TABLE rfm_base AS
SELECT 
    CustomerID,
    MAX(InvoiceDate) AS last_purchase_date,
    COUNT(DISTINCT InvoiceNo) AS frequency,
    SUM(Revenue) AS monetary
FROM retail_customer
GROUP BY CustomerID;
-- Creating recency column
ALTER TABLE rfm_base ADD COLUMN recency INT;
-- Calculating recency (days since last purchase)

UPDATE rfm_base
SET recency = DATEDIFF(
    DATE('2011-12-09 12:50:00'),
    DATE(last_purchase_date)
);
--
SELECT 
    MIN(recency),
    MAX(recency),
    AVG(recency)
FROM rfm_base;
-- Creating RFM scores using NTILE for segmentation
CREATE TABLE rfm_final AS
SELECT 
    CustomerID,
    recency,
    frequency,
    monetary,

    NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency) AS f_score,
    NTILE(5) OVER (ORDER BY monetary) AS m_score

FROM rfm_base;
--
select * from rfm_final;
Alter table rfm_final add column rfm_score varchar(10);
update rfm_final set rfm_score = concat(r_score, f_score, m_score);
-- Assigning customer segments
-- Objective: Classify customers into actionable groups for marketing and retention strategies
CREATE TABLE rfm_segment AS
SELECT *,
CASE 
    WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
    WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
    WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
    WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
    WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernating'
    ELSE 'Others'
END AS segment
FROM rfm_final;

SELECT segment, COUNT(*) 
FROM rfm_segment
GROUP BY segment;

SELECT 
    segment,
    COUNT(*) AS customers,
    SUM(monetary) AS revenue,
    ROUND(AVG(monetary),2) AS avg_spend
FROM rfm_segment
GROUP BY segment
ORDER BY revenue DESC;
-- Business Insight:
-- Helps identify high-value customers (Champions, Loyal)
-- Enables targeted marketing for retention and reactivation
-- At-risk and hibernating customers indicate churn risk

-- STEP 7 - cohort analysis
-- Objective: Analyze customer retention over time by grouping customers based on first purchase month

-- Identifying cohort month (first purchase)
CREATE TABLE cohort_base AS
SELECT 
    CustomerID,
    MIN(DATE_FORMAT(InvoiceDate, '%Y-%m-01')) AS cohort_month
FROM retail_customer
GROUP BY CustomerID;
--
select * from cohort_base limit 10;
-- Calculating cohort index (months since first purchase)
CREATE TABLE cohort_index AS
SELECT 
    rc.CustomerID,
    cb.cohort_month,
    DATE_FORMAT(rc.InvoiceDate, '%Y-%m-01') AS order_month,

    PERIOD_DIFF(
        DATE_FORMAT(rc.InvoiceDate, '%Y%m'),
        DATE_FORMAT(cb.cohort_month, '%Y%m')
    ) AS cohort_index

FROM retail_customer rc
JOIN cohort_base cb 
ON rc.CustomerID = cb.CustomerID;
--
CREATE TABLE cohort_retention AS
SELECT 
    cohort_month,
    cohort_index,
    COUNT(DISTINCT CustomerID) AS customers
FROM cohort_index
GROUP BY cohort_month, cohort_index;
--
SELECT * FROM cohort_retention ORDER BY cohort_month, cohort_index;
--
SELECT 
    cr.cohort_month,
    cr.cohort_index,
    cr.customers,

    FIRST_VALUE(cr.customers) OVER (
        PARTITION BY cr.cohort_month 
        ORDER BY cr.cohort_index
    ) AS cohort_size,

    ROUND(
        cr.customers * 100.0 /
        FIRST_VALUE(cr.customers) OVER (
            PARTITION BY cr.cohort_month 
            ORDER BY cr.cohort_index
        ), 2
    ) AS retention_rate

FROM cohort_retention cr;

ALTER TABLE cohort_retention 
ADD COLUMN cohort_size INT,
ADD COLUMN retention_rate DECIMAL(5,2);
-- Calculating retention metrics
-- Objective: Measure how many customers return over time

UPDATE cohort_retention cr
JOIN (
    SELECT 
        cohort_month,
        customers AS cohort_size
    FROM cohort_retention
    WHERE cohort_index = 0
) base
ON cr.cohort_month = base.cohort_month
SET cr.cohort_size = base.cohort_size;
--
UPDATE cohort_retention
SET retention_rate = ROUND(
    customers * 100.0 / cohort_size,
    2
);
-- Business Insight:
-- Cohort analysis tracks customer retention over time
-- Helps identify when customers drop off (early vs long-term churn)
-- Useful for improving onboarding and lifecycle engagement strategies

-- FINAL INSIGHTS SUMMARY:
-- 1. Revenue is driven by repeat customers, indicating strong retention
-- 2. High-value segments contribute majority of revenue (RFM analysis)
-- 3. Significant drop in retention after Month 1 highlights onboarding issues
-- 4. Revenue is concentrated in specific geographies (country-level analysis)



