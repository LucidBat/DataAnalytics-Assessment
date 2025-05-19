-- Q3: Account Inactivity Alert
-- Objective: Identify active accounts (Savings or Investments) that have had no inflow transactions in the past 365 days.

SELECT 
    p.id AS plan_id,
    p.owner_id,

    -- Classify plan type as either Savings or Investment
    CASE 
        WHEN p.is_regular_savings = 1 THEN 'Savings'
        WHEN p.is_a_fund = 1 THEN 'Investment'
        ELSE 'Other'
    END AS type,

    -- Most recent transaction date for the plan
    MAX(sa.transaction_date) AS last_transaction_date,

    -- Number of days since the last transaction
    DATEDIFF(CURDATE(), MAX(sa.transaction_date)) AS inactivity_days

FROM assigment.plans_plan p

-- Join savings account table to access transaction details
LEFT JOIN assigment.savings_savingsaccount sa 
    ON p.id = sa.plan_id

-- Filter for active plans only (assuming status_id = 1 means active)
WHERE p.status_id = 1

-- Group by plan and owner to calculate per-plan activity
GROUP BY p.id, p.owner_id, type

-- Filter for plans with either:
-- 1. No transaction at all (NULL date), OR
-- 2. Last transaction was more than 365 days ago
HAVING 
    (MAX(sa.transaction_date) IS NULL 
     OR MAX(sa.transaction_date) < DATE_SUB(CURDATE(), INTERVAL 365 DAY))

-- Show most inactive plans first
ORDER BY inactivity_days DESC;
