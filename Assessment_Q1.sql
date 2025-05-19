-- Q1: High-Value Customers with Multiple Products
-- This query identifies customers who have at least one funded savings plan
-- and at least one funded investment plan, and calculates their total deposits.

SELECT 
    u.id AS owner_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    s.savings_count,
    i.investment_count,
    -- Divide by 100.0 to convert kobo to naira, and round to 2 decimal places
    ROUND((COALESCE(s.total_savings_inflow, 0) + COALESCE(i.total_investment_inflow, 0)) / 100.0, 2) AS total_deposits
FROM assigment.users_customuser u
-- Subquery to get funded savings plans
JOIN (
    SELECT 
        sa.owner_id,
        COUNT(DISTINCT sa.plan_id) AS savings_count,
        SUM(CASE WHEN sa.confirmed_amount > 0 THEN sa.confirmed_amount ELSE 0 END) AS total_savings_inflow
    FROM assigment.savings_savingsaccount sa
    JOIN assigment.plans_plan p ON sa.plan_id = p.id
    WHERE p.is_regular_savings = 1
    GROUP BY sa.owner_id
) s ON u.id = s.owner_id
-- Subquery to get funded investment plans
JOIN (
    SELECT 
        sa.owner_id,
        COUNT(DISTINCT sa.plan_id) AS investment_count,
        SUM(CASE WHEN sa.confirmed_amount > 0 THEN sa.confirmed_amount ELSE 0 END) AS total_investment_inflow
    FROM assigment.savings_savingsaccount sa
    JOIN assigment.plans_plan p ON sa.plan_id = p.id
    WHERE p.is_a_fund = 1
    GROUP BY sa.owner_id
) i ON u.id = i.owner_id
-- Sort by highest total deposits
ORDER BY total_deposits DESC;



SELECT 
    u.id AS owner_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    s.savings_count,
    i.investment_count,
    ROUND((COALESCE(s.total_savings_inflow, 0) + COALESCE(i.total_investment_inflow, 0)) / 100.0, 2) AS total_deposits
FROM assigment.users_customuser u
JOIN (
    SELECT 
        sa.owner_id,
        COUNT(DISTINCT sa.plan_id) AS savings_count,
        SUM(CASE WHEN sa.confirmed_amount > 0 THEN sa.confirmed_amount ELSE 0 END) AS total_savings_inflow
    FROM assigment.savings_savingsaccount sa
    JOIN assigment.plans_plan p ON sa.plan_id = p.id
    WHERE p.is_regular_savings = 1
    GROUP BY sa.owner_id
) s ON u.id = s.owner_id
JOIN (
    SELECT 
        sa.owner_id,
        COUNT(DISTINCT sa.plan_id) AS investment_count,
        SUM(CASE WHEN sa.confirmed_amount > 0 THEN sa.confirmed_amount ELSE 0 END) AS total_investment_inflow
    FROM assigment.savings_savingsaccount sa
    JOIN assigment.plans_plan p ON sa.plan_id = p.id
    WHERE p.is_a_fund = 1
    GROUP BY sa.owner_id
) i ON u.id = i.owner_id
ORDER BY total_deposits DESC;







