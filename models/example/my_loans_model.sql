
-- This is the model for creating loans
-- This is writen in SQL
-- This server to perform transformation, feature engineering, modification of columns and data
-- Additional columns below to parse date information and convert interest rates to decimal type

-- Derived columns come first so queries on them do not deform all source columns to reach them
select
    to_date("issue_d", 'YY-Mon') as issue_date,
    to_date("last_credit_pull_d", 'YY-Mon') as last_credit_pull_date,
    to_date("last_pymnt_d", 'YY-Mon') as last_pymnt_date,
    replace("int_rate", '%', '')::decimal as interest_rate,
    *
from loans
