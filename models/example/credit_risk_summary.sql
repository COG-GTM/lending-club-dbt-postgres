/*
    Credit Risk Summary Model
    -------------------------
    Aggregates Lending Club loan data by loan grade (A-G) to produce
    a credit-risk overview for risk analysts and portfolio managers.

    Metrics per grade:
      - Total loan count and total funded amount
      - Average interest rate
      - Default rate (loans with status 'Charged Off' or 'Default')
      - Risk classification: A-B = LOW RISK, C-D = MEDIUM RISK, E-G = HIGH RISK

    Source: {{ ref('my_loans_model') }}
*/

with loan_metrics as (

    select
        grade,
        count(*)                                             as total_loan_count,
        sum(loan_amnt)                                       as total_loan_amount,
        avg(interest_rate)                                   as avg_interest_rate,
        sum(
            case
                when loan_status ilike '%Charged Off%'
                  or loan_status ilike '%Default%'
                then 1
                else 0
            end
        )::decimal / nullif(count(*), 0)                     as default_rate
    from {{ ref('my_loans_model') }}
    where grade is not null
    group by grade

)

select
    grade,
    total_loan_count,
    total_loan_amount,
    round(avg_interest_rate, 4)                              as avg_interest_rate,
    round(default_rate, 4)                                   as default_rate,
    case
        when grade in ('A', 'B')           then 'LOW RISK'
        when grade in ('C', 'D')           then 'MEDIUM RISK'
        when grade in ('E', 'F', 'G')      then 'HIGH RISK'
    end                                                      as risk_classification
from loan_metrics
order by grade
