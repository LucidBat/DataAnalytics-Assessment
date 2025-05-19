-- Q4: Customer Lifetime Value (CLV) Estimation
-- Objective: Estimate CLV based on account tenure (in months) and transaction volume

SELECT
    u.id AS customer_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,

    -- Calculate the number of months between signup and today
    TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()) AS tenure_months,

    -- Total number of transactions made by the customer
    COUNT(sa.id) AS total_transactions,

    -- Estimated CLV Calculation:
    ROUND(
        (
            (COUNT(sa.id) / NULLIF(TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()), 0)) 
            * 12 * AVG(sa.amount) * 0.001
        ), 2
    ) AS estimated_clv

FROM assigment.users_customuser u

-- Join savings accounts to get transaction history
LEFT JOIN assigment.savings_savingsaccount sa 
    ON u.id = sa.owner_id

-- Group by customer to aggregate values
GROUP BY 
    u.id, 
    u.first_name, 
    u.last_name, 
    u.date_joined

-- Ensure we only include customers with non-zero tenure to avoid division by zero
HAVING tenure_months > 0

-- Rank customers from highest to lowest estimated CLV
ORDER BY estimated_clv DESC;
