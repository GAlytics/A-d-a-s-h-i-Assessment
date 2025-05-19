-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Question 1: High-Value Customers with Multiple Products
-- Goal: Identify customers with BOTH a funded savings plan and a funded investment plan.
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SELECT cust.id AS owner_id, CONCAT(
        cust.first_name, ' ', cust.last_name
    ) AS name,

-- Number of savings records with confirmed deposits
COALESCE(saver.savings_count, 0) AS savings_count,

-- Number of investment plans per customer
COALESCE(fund.investment_count, 0) AS investment_count,

-- Total deposit amount converted from kobo to Naira
ROUND(
    COALESCE(saver.total_deposits, 0) / 100,
    2
) AS total_deposits
FROM users_customuser cust

-- Subquery 1: Get savings details per user
LEFT JOIN (
    SELECT
        owner_id,
        COUNT(*) AS savings_count,
        SUM(confirmed_amount) AS total_deposits
    FROM savings_savingsaccount
    WHERE
        confirmed_amount > 0 -- Only funded savings
    GROUP BY
        owner_id
) saver ON cust.id = saver.owner_id

-- Subquery 2: Get funded investment plan count per user
LEFT JOIN (
    SELECT owner_id, COUNT(*) AS investment_count
    FROM plans_plan
    WHERE
        is_a_fund = 1 -- Investment plans only
        AND amount > 0 -- Must be funded
    GROUP BY
        owner_id
) fund ON cust.id = fund.owner_id

-- Only include users with both savings and investments
WHERE
    COALESCE(saver.savings_count, 0) > 0
    AND COALESCE(fund.investment_count, 0) > 0
ORDER BY total_deposits DESC;