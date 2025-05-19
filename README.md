# Question 1: High-Value Customers with Multiple Products

###  Overview
This SQL script identifies high-value customers who have both funded savings and investment plans. This helps the business identify cross-selling opportunities and better understand customer value.

###  Approach

The goal was to identify customers who have:

- At least one funded **regular savings plan**
- At least one funded **investment plan**

Steps:

1. **Filter Savings Plans**:
   - Used `is_regular_savings = 1` to select only regular savings plans.
   - Filtered for funded plans using `confirmed_amount > 0`.

2. **Filter Investment Plans**:
   - Used `is_a_fund = 1` to select investment plans.
   - Again filtered for funded plans only.

3. **Aggregate per Customer**:
   - Counted distinct funded plans per type.
   - Summed the `confirmed_amount` field for total inflows.

4. **Join Subqueries**:
   - Joined both subqueries on `owner_id` to return only customers who have **both** plan types.

5. **Join with User Info**:
   - Pulled user name from `users_customuser`.

6. **Final Calculations**:
   - Added savings and investment inflows.
   - Converted from kobo to naira (divided by 100).
   - Rounded to 2 decimal places.

7. **Sorting**:
   - Sorted by `total_deposits` in descending order to show high-value customers first.

---

###  Challenges and How I Solved Them

### 1. Handling NULLs in Sums
**Challenge**: Aggregated sums were returning NULLs when no matching records were found.  
**Solution**: Used `COALESCE()` to default NULL values to 0.


---

### 2. Filtering Only Funded Plans

**Challenge**: Needed to avoid counting unfunded plans (`confirmed_amount = 0`).
**Solution**: Wrapped the `SUM()` in a `CASE` expression:

---

### 3. Ensuring Customers Have Both Plan Types

**Challenge**: Avoid returning users who have only one type of product.
**Solution**: Used `INNER JOIN` between the savings and investment subqueries to ensure customers exist in **both**.


---

###  Tables Used

* `users_customuser`
* `savings_savingsaccount`
* `plans_plan`



# Question 2: Customer Transaction Frequency Segmentation

##  Overview
This SQL script segments customers into three frequency categories based on how often they perform transactions on average per month. This insight can help tailor communication and product offerings for different user segments.


###  Approach

The objective was to classify customers as:

- **High Frequency**: ≥ 10 transactions/month
- **Medium Frequency**: 3–9 transactions/month
- **Low Frequency**: < 3 transactions/month

Steps followed:

1. **Monthly Transaction Counts**:
   - Grouped transaction records by customer (`owner_id`) and month (`transaction_date`).
   - Counted number of transactions per customer per month.

2. **Average Monthly Transactions per Customer**:
   - Calculated the average number of transactions per month for each customer using the inner result.

3. **Categorization**:
   - Used a `CASE` statement to classify customers based on their average transaction frequency.

4. **Final Aggregation**:
   - Counted the number of customers in each frequency category.
   - Calculated the overall average transactions per month for each category.

5. **Ordering**:
   - Ordered the output logically: High → Medium → Low.

---

###  Challenges and How I Solved Them

### 1. Extracting Monthly Granularity
**Challenge**: Needed to break down transactions by month.  
**Solution**: Used MySQL's `DATE_FORMAT(transaction_date, '%Y-%m')` to group by month.

---

### 2. Frequency Categorization
**Challenge**: Accurately classify based on dynamic average values.  
**Solution**: Wrapped the `AVG(transactions_per_month)` inside a `CASE` for segmentation:
```sql
CASE
    WHEN AVG(transactions_per_month) >= 10 THEN 'High Frequency'
    WHEN AVG(transactions_per_month) BETWEEN 3 AND 9 THEN 'Medium Frequency'
    ELSE 'Low Frequency'
END
````

---

### 3. Logical Ordering of Categories

**Challenge**: Default alphabetical order would not match desired logic.
**Solution**: Used a `CASE` in `ORDER BY` to define custom sequence:

```sql
ORDER BY
    CASE frequency_category
        WHEN 'High Frequency' THEN 1
        WHEN 'Medium Frequency' THEN 2
        WHEN 'Low Frequency' THEN 3
    END;
```

---


###  Tables Used

* `savings_savingsaccount`


#  Question 3: Account Inactivity Alert

###  Overview
The operations team needs to identify all active accounts (either Savings or Investment) that have had **no inflow transactions in the past year (365 days)**. This alert helps proactively follow up on dormant accounts.

###  Approach

The goal is to return a list of all **active accounts** from the `plans_plan` table, categorized as either "Savings" or "Investment", where the last inflow transaction recorded in the `savings_savingsaccount` table was more than 365 days ago — or where **no transaction** has ever occurred.

###  Steps Taken

1. **Join Tables**:
   - `plans_plan` holds the account-level data.
   - `savings_savingsaccount` contains transaction data.
   - A `LEFT JOIN` ensures we still retrieve accounts **with no transactions** (i.e., `NULL` transaction dates).

2. **Filter Active Accounts**:
   - Assumes `status_id = 1` represents **active** accounts.

3. **Classify Plan Types**:
   - Used a `CASE` statement to classify accounts as:
     - `'Savings'` → if `is_regular_savings = 1`
     - `'Investment'` → if `is_a_fund = 1`

4. **Calculate Inactivity**:
   - Used `MAX(sa.transaction_date)` to find the latest transaction per plan.
   - Computed inactivity duration using `DATEDIFF(CURDATE(), last_transaction_date)`.

5. **Final Filtering**:
   - Included only those plans with:
     - No transaction at all (`MAX(transaction_date) IS NULL`)
     - OR last transaction older than 365 days

6. **Ordering**:
   - Sorted results by longest inactivity first using `ORDER BY inactivity_days DESC`.

---

###  Challenges and Resolutions

### 1. Including Plans Without Transactions
**Challenge**: Need to detect accounts that have never had any transaction.  
**Solution**: Used `LEFT JOIN` and filtered `NULL` values in `HAVING`.

---

### 2. Dual Classification of Accounts
**Challenge**: A plan could theoretically have both `is_regular_savings` and `is_a_fund` flags.  
**Solution**: Prioritized classification: Savings → Investment → Other.

---
###  Tables Used

- `plans_plan`
- `savings_savingsaccount`

#  Question 4: Query for Customer Lifetime Value (CLV) Estimation

##  Overview
Marketing wants to identify high-value customers by estimating their **Customer Lifetime Value (CLV)** based on:
- How long they’ve been with the platform (account tenure)
- Their transaction volume and average transaction size

---

###  Approach

To estimate CLV, we use a simplified formula:

> **CLV = (total_transactions / tenure_months) * 12 * avg_transaction_value * profit_margin**

Assumptions:
- `profit_margin = 0.1% = 0.001`
- `amount` fields are stored in **kobo**, so final output reflects **naira values**

---

###  Steps Taken

1. **Join Tables**:
   - Joined `users_customuser` (user info) with `savings_savingsaccount` (transactions) via `owner_id`.

2. **Calculate Tenure**:
   - Used `TIMESTAMPDIFF(MONTH, date_joined, CURDATE())` to determine how long each customer has been active.

3. **Transaction Volume**:
   - Counted total transactions using `COUNT(sa.id)`.

4. **CLV Estimation**:
   - Avoided division by zero using `NULLIF(tenure_months, 0)`.
   - Applied the formula in the `ROUND(..., 2)` function for clarity and format.

5. **Grouping**:
   - Aggregated by each user (grouped by `u.id`, `u.first_name`, `u.last_name`, and `u.date_joined`).

6. **Filtering**:
   - Excluded customers with zero-month tenure (`HAVING tenure_months > 0`).

7. **Ordering**:
   - Sorted customers by **estimated CLV in descending order**.

---

###  Challenges and Resolutions

### 1. Division by Zero for New Customers
**Challenge**: Some users may have `tenure_months = 0`, causing errors.  
**Solution**: Used `NULLIF(..., 0)` in the denominator and applied a `HAVING` clause to filter them out.

---

### 2. Handling Monetary Units (Kobo to Naira)
**Challenge**: All `amount` values were stored in **kobo**, inflating estimates.  
**Solution**: Multiplied final CLV by `0.001` to reflect accurate **naira values**.

---

###  Tables Used

- `users_customuser` (user info)
- `savings_savingsaccount` (transaction history)
