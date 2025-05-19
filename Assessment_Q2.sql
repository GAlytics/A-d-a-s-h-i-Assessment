-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Question 2: Transaction Frequency Analysis
-- Goal: Segment customers based on average transaction frequency.
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
WITH savings_txn AS (
    SELECT
        sav.owner_id,
        COUNT(*) AS total_transactions,

-- Calculate active months based on earliest to latest transaction date
PERIOD_DIFF(
            DATE_FORMAT(MAX(sav.created_on), '%Y%m'),
            DATE_FORMAT(MIN(sav.created_on), '%Y%m')
        ) + 1 AS active_months

    FROM savings_savingsaccount sav
    GROUP BY sav.owner_id
),

classified_freq AS (
    SELECT
        tx.owner_id,
        usr.first_name,
        usr.last_name,

-- Average transactions per month
ROUND(
    tx.total_transactions / tx.active_months,
    2
) AS avg_transactions_per_month,

-- Categorize based on frequency tiers
CASE
            WHEN (tx.total_transactions / tx.active_months) >= 10 THEN 'High Frequency'
            WHEN (tx.total_transactions / tx.active_months) BETWEEN 3 AND 9 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category
    FROM savings_txn tx
    JOIN users_customuser usr ON tx.owner_id = usr.id
)

-- Aggregate and report final segmentation statistics.
SELECT
    frequency_category,
    COUNT(*) AS customer_count,
    ROUND(
        AVG(avg_transactions_per_month),
        2
    ) AS avg_transactions_per_month
FROM classified_freq
GROUP BY
    frequency_category
ORDER BY FIELD(
        frequency_category, 'High Frequency', 'Medium Frequency', 'Low Frequency'
    );