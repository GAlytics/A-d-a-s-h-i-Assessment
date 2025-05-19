-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Question 3: Account Inactivity Alert
-- Goal: Identify active savings or investment accounts
--       with no inflow in the last 365 days.
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- 1. Savings accounts with last deposit date older than 365 days
SELECT
    sav.id AS plan_id,
    sav.owner_id,
    'Savings' AS type,
    MAX(sav.created_on) AS last_transaction_date,
    DATEDIFF(
        CURRENT_DATE,
        MAX(sav.created_on)
    ) AS inactivity_days
FROM savings_savingsaccount sav
WHERE
    sav.confirmed_amount > 0
GROUP BY
    sav.id,
    sav.owner_id
HAVING
    DATEDIFF(
        CURRENT_DATE,
        MAX(sav.created_on)
    ) > 365
UNION

-- 2. Funded investment plans inactive for over 365 days
SELECT
    inv.id AS plan_id,
    inv.owner_id,
    'Investment' AS type,
    inv.created_on AS last_transaction_date,
    DATEDIFF(CURRENT_DATE, inv.created_on) AS inactivity_days
FROM plans_plan inv
WHERE
    inv.is_a_fund = 1
    AND inv.amount > 0
    AND DATEDIFF(CURRENT_DATE, inv.created_on) > 365
ORDER BY inactivity_days DESC;