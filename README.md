## README.md

### Candidate Name: Goodness Andrew<br>
### Date: 19th May, 2025<br>

# DataAnalytics-Assessment - COWRYWISE

**Database file** - `https://drive.google.com/file/d/1__51EvatOK1ubG4oi0Im_VW2UWUChMHu/view?usp=drive_link`

Here is my submission for the SQL Proficiency Assessment. This project includes a detailed SQL solutions to solve business data problems, focused on customers' savings and investments plan.

# Question 1: High-Value Customers with Multiple Products

## Objective

To identify customers who have both a funded savings account and a funded investment plan. Sort by total deposit amount.

### Approach

1. I used two separate aggregation subqueries:
    - One to count and sum deposits from `savings_savingsaccount` (`confirmed_amount > 0`)
    - One to count funded investments from `plans_plan` (`is_a_fund = 1 AND amount > 0`)
2. I joined them with the `users_customuser` table.
3. I used `COALESCE` to replace NULLs for count and sum fields.
4. I converted monetary values from kobo to naira using division by
5. I sorted results by `total_deposits` in descending order.

#### Challenges

**1. Dealing with NULLs from users without savings or investments**
One delicate challenge I encountered was ensuring that users with no savings or investment activity still appeared in the join results without causing NULL errors. If that is not resolved, customers without matching savings or investment data would return `NULL` in the count and deposit fields. If NULLs from users without savings or investments aren't dealt with, it may cause the filtering condition (`> 0`) to fail, even though the there were no such instance, but for efficiency and scalabiliy, I decided to solve that gap.

To solve this, I used the `COALESCE` function to convert NULLs into default zero values (`0` for counts, `0.00` for totals). This ensured consistency and accurate filtering for customers who truly had both product types.

**2. Verifying unit scale of currency fields**
Even though the instructions stated that amount fields were in kobo, the resulting values initially appeared abnormally large. A manual spot-check and calculations was done, which confirms the need to divide by 100 to present values in naira.

# Question 2: Transaction Frequency Analysts

## Objective

Segment customers based on how frequently they transact monthly: High (≥10), Medium (3–9), or Low (≤2).

### Approach

*1- I grouped transactions in the `savings_savingsaccount` table by `owner_id` to get a transaction history for each customer.
*2- To figure out how long each customer had been actively transacting, I calculated the difference in months between their first and last transaction using `PERIOD_DIFF(MAX(created_on),    MIN(created_on))`.
*3- I then computed their average transactions per month by dividing their total count by that active duration.
*4- Based on the result, I used a `CASE` statement to categorize each customer as either High, Medium, or Low frequency.
\*5- Finally, I aggregated the number of customers in each frequency category to get a clean, summarized view of transaction behaviors.

#### Challenges

- One thing I quickly realized was that customers transact at very different rates ; some are active almost every day, while others might only show up once in a while. If I had just used the total transaction count without accounting for the time span, the categories would’ve been misleading. To fix that, I calculated how many months each user had been active and based the frequency on that average instead.

- Another issue was with how `PERIOD_DIFF` calculates months ; if a user had two transactions at the end of one month and the start of the next, it would still count as a full month apart. That slightly inflated some of the durations. To make it more accurate, I added `+1` to the result to make sure both start and end months were included. This gave more realistic averages, especially for users with short histories.

- I also ran into a divide-by-zero problem for users who only had one transaction or transacted within the same month. The `PERIOD_DIFF` in those cases returned zero, which obviously caused errors when dividing. I handled that by using `GREATEST(months_active, 1)` so that we’d never divide by zero, and those edge cases wouldn’t break the flow.

# Question 3: Account Inactivity Alert

## Objective

Identify all active accounts (savings or investments) with no inflow in the last 365 days.

### Approach

*1- For `savings_savingsaccount`: I founded the last deposit date using `MAX(created_on)`
*2- For `plans_plan`: I used `created_on` date for funded investment plans (`is_a_fund = 1 AND amount > 0`)
*3- I calculated `DATEDIFF(CURRENT_DATE, last_transaction_date)`
*4- I finally filtered only accounts with inactivity > 365 days and combined savings + investments with `UNION`

#### Challenges

- One thing I wasn’t sure about at first was whether to exclude plans that were marked as `archived` or `deleted`. Just because a plan is archived doesn’t always mean it’s inactive — it might just be hidden in the UI or no longer promoted. Since the instructions didn’t mention filtering those out, I chose to keep them in the results for now to avoid accidentally missing real customers. If the business later defines what “inactive” truly means in this context, that can be updated.

- Another small snag was the way dates are handled across the tables. The `savings_savingsaccount` table tracks individual transactions, so I could use `MAX(created_on)` to find the last deposit. But for investments, the `plans_plan` table only has one date — the plan’s creation date. Since there’s no ongoing transaction log, I just treated that date as the last inflow for the purpose of inactivity. It’s not perfect, but it fits the structure and the instructions.

# Question 4: Customer Lifetime Value (CLV) Estimation

## Objective

Estimate CLV per customer using tenure (in months) and total transaction value. Formula:

`CLV = (total_transactions / tenure_months) * 12 * avg_profit_per_transaction`

Where `profit_per_transaction = 0.1%` of total transaction value.

### Approach

*1- I used `users_customuser.date_joined` to compute tenure with `TIMESTAMPDIFF(MONTH, date_joined, CURRENT_DATE)`
*2- I summed `confirmed_amount` from `savings_savingsaccount` (in kobo) and converted to naira
_3- I computed average profit as `total_value _ 0.001`*4- I used`GREATEST(tenure, 1)` to avoid division by zero

#### Challenges

- At first, I misunderstood the phrase “0.1% profit per transaction.” I thought it meant I should calculate 0.1% of each individual transaction and then average that. But after reading the question more carefully, I realized it actually meant 0.1% of the total transaction volume per customer. Once I made that adjustment and applied the profit rate after summing the confirmed amounts, the CLV numbers started to look more realistic.

- I noticed that some new users who had only just signed up were showing surprisingly high CLVs. Turns out, they had made a lot of transactions in a short time, which caused their monthly average to spike. To keep things fair and avoid divide-by-zero issues, I added a `GREATEST(tenure, 1)` so even users with less than a month of tenure wouldn’t throw off the calculations.

- I also ran into a scaling issue earlier on. My CLV values were way too high. After double-checking the data, I realized I had forgotten to convert `confirmed_amount` from kobo to naira. Once I added the `/ 100` conversion and validated a few examples manually, the results made a lot more sense and matched expected business ranges.
