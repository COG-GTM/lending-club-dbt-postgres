-- CONTROL DQ-26: the loan key agrees with the independent key embedded in the
-- LC listing URL (…/loanDetail.action?loan_id=<key>).
--
-- The URL is populated by a different upstream process than the id column, so
-- it is an independent corroboration that the column selected as the loan key
-- really identifies the loan. This is the control that would have caught the
-- key defect regardless of which column name the semantic layer declared.
--
-- Returns one row per loan whose key disagrees with its own listing URL.

select
    loan_id,
    url,
    nullif(split_part(url, 'loan_id=', 2), '')::bigint as url_loan_id
from {{ ref('my_loans_model') }}
where nullif(split_part(url, 'loan_id=', 2), '')::bigint is distinct from loan_id
