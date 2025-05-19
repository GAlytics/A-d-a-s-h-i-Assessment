-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Question 4: Customer Lifetime Value (CLV) Estimation
-- Goal: Estimate CLV for each customer based on tenure and transaction history
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


WITH txn_summary AS (
    -- Aggregate total transactions and sum of confirmed amounts per customer
    SELECT
        sav.owner_id,
        COUNT(*) AS total_transactions,
        SUM(sav.confirmed_amount) AS total_value_kobo
    FROM savings_savingsaccount sav
    WHERE sav.confirmed_amount > 0
    GROUP BY sav.owner_id
),

user_tenure AS (
    -- Calculate tenure in months and concatenate full customer name
    SELECT
        usr.id AS customer_id,
        CONCAT(usr.first_name, ' ', usr.last_name) AS name,
        TIMESTAMPDIFF(MONTH, usr.date_joined, CURRENT_DATE) AS tenure_months,
        usr.date_joined
    FROM users_customuser usr
),

clv_output AS (
    SELECT
        ten.customer_id,
        ten.name,
        -- Avoid division by zero by setting minimum tenure to 1 month
        GREATEST(ten.tenure_months, 1) AS tenure_months,
        COALESCE(tx.total_transactions, 0) AS total_transactions,

-- Calculate average profit per transaction (0.1% of transaction value in naira)
ROUND(
    (
        COALESCE(tx.total_value_kobo, 0) / 100
    ) * 0.001,
    2
) AS avg_profit_per_transaction_naira,

-- Calculate estimated CLV as annualized profit based on transactions per month
ROUND((
            (COALESCE(tx.total_transactions, 0) / GREATEST(ten.tenure_months, 1))
            * 12
            * ((COALESCE(tx.total_value_kobo, 0) / 100) * 0.001)
        ), 2) AS estimated_clv

    FROM user_tenure ten
    LEFT JOIN txn_summary tx ON ten.customer_id = tx.owner_id
)
-- Final output: customer ID, name, tenure in months, total transactions, and estimated CLV
SELECT
    customer_id,
    name,
    tenure_months,
    total_transactions,
    estimated_clv
FROM clv_output
ORDER BY estimated_clv DESC;