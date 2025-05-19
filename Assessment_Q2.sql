-- Q2: Customer Transaction Frequency Segmentation
-- Objective: Classify customers as High, Medium, or Low frequency based on average transactions per month.
SELECT
    frequency_category,
    COUNT(owner_id) AS customer_count,
    ROUND(AVG(avg_transactions_per_month), 2) AS avg_transactions_per_month
-- Step 2: For each customer, calculate average monthly transactions
FROM (
    SELECT
        owner_id,
        AVG(transactions_per_month) AS avg_transactions_per_month,
	-- Categorize based on average transactions
        CASE
            WHEN AVG(transactions_per_month) >= 10 THEN 'High Frequency'
            WHEN AVG(transactions_per_month) BETWEEN 3 AND 9 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category
    -- Calculate number of transactions per month per customer
    FROM (
        SELECT
            sa.owner_id,
            COUNT(*) AS transactions_per_month,
            DATE_FORMAT(sa.transaction_date, '%Y-%m') AS transaction_year_month
        FROM assigment.savings_savingsaccount sa
        GROUP BY
            sa.owner_id,
            DATE_FORMAT(sa.transaction_date, '%Y-%m')
    ) AS monthly_transactions
    GROUP BY owner_id
) AS categorized_customers
GROUP BY frequency_category
-- Order categories logically
ORDER BY
    CASE frequency_category
        WHEN 'High Frequency' THEN 1
        WHEN 'Medium Frequency' THEN 2
        WHEN 'Low Frequency' THEN 3
    END;
