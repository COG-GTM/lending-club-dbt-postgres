-- CONTROL DQ-10: sub-grade is internally consistent with grade.
--
-- LC sub-grades are the grade letter followed by a risk notch 1-5 (e.g. B2
-- belongs to grade B). A sub-grade whose letter disagrees with the grade
-- column means the risk band reported to the business is unreliable.
--
-- Returns one row per loan whose sub_grade contradicts its grade.

select
    loan_id,
    grade,
    sub_grade
from {{ ref('my_loans_model') }}
where sub_grade is null
   or left(sub_grade, 1) <> grade
   or right(sub_grade, 1) not in ('1', '2', '3', '4', '5')
