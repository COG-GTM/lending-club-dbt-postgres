-- CONTROL DQ-07: loan key parity between the raw extract and the model.
--
-- Row-count parity alone (DQ-06) does not prove the same loans came through:
-- a mis-declared or mis-derived key can preserve the count while changing the
-- population. This control fails if any raw loan key is missing from the model
-- or any model loan key is absent from the raw extract.
--
-- Returns one row per unmatched key, with the side it is missing from.

with raw_keys as (

    select nullif(btrim("id"), '')::bigint as loan_id
    from {{ source('lending_club', 'loans') }}

),

model_keys as (

    select loan_id from {{ ref('my_loans_model') }}

)

select
    coalesce(r.loan_id, m.loan_id) as loan_id,
    case
        when m.loan_id is null then 'missing_from_model'
        else 'missing_from_raw'
    end as parity_failure
from raw_keys r
full outer join model_keys m
    on r.loan_id = m.loan_id
where r.loan_id is null or m.loan_id is null
