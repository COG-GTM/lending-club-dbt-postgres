# Loan-level data-quality control evidence

Scope: the Lending Club loan extract (`dataset/loan.csv`, 39,717 rows, 111
columns) as landed in Postgres (`public.loans`) and as transformed by
`models/example/my_loans_model.sql`.

Every control below is implemented as a named dbt test and is executed by
`dbt build`. Nothing in this document is asserted by hand: each row names the
test that enforces it and the SQL an auditor can re-run directly against
Postgres to reproduce the result.

How to reproduce the whole run:

```bash
psql -h localhost -U postgres -d postgres -f scripts/create_loans_table.sql
python scripts/load_db_data.py          # loads dataset/loan.csv
dbt deps   --profiles-dir .
dbt build  --profiles-dir .             # builds the model and runs all controls
```

Execution status of this document: **all controls were executed** against a
local Postgres 15 instance loaded with the full 39,717-row extract. Result of
the final run: `PASS=45 WARN=0 ERROR=0 SKIP=0 TOTAL=45` (1 model + 44 tests).

---

## 1. Defect: the loan key control was pointed at a column that does not exist

### What happened

Commit `3addfa7` ("Data quality check update", 2026-03-24) changed one line in
`models/example/schema.yml`:

```diff
-      - name: id
+      - name: loan_id_broken
         description: A unique LC assigned ID for the loan listing.
         tests:
           - unique
           - not_null
```

`loan_id_broken` is not a column of `dataset/loan.csv`, of the raw `loans`
table, or of `my_loans_model` (which was `select *` over `loans` plus four
derived columns). The two controls that were supposed to prove the loan key was
unique and complete were therefore bound to a phantom column.

### Concrete counts

| Observation | Value |
| --- | --- |
| Rows in raw extract / model | 39,717 |
| Occurrences of `loan_id_broken` in the raw extract | 0 columns, 0 rows |
| Occurrences of `loan_id_broken` in the warehouse (`information_schema.columns`) | 0 |
| True key `id`: rows / distinct / null | 39,717 / 39,717 / 0 |
| `id` values that disagree with the loan id embedded in the listing URL | 0 |
| Loans covered by an executing key control before the fix | 0 of 39,717 |

Auditor SQL:

```sql
-- the declared key does not exist anywhere in the warehouse
select table_name, column_name
from information_schema.columns
where column_name = 'loan_id_broken';                       -- 0 rows

-- the real key is clean, so the defect is the control, not the data
select count(*)            as rows,
       count(distinct id)  as distinct_ids,
       count(*) filter (where id is null or btrim(id) = '') as null_ids
from loans;                                                 -- 39717 | 39717 | 0

-- independent corroboration of the key from the listing URL
select count(*) from loans
where id::bigint <> split_part(url, 'loan_id=', 2)::bigint; -- 0
```

### Classification

Not a corrupted key in the data: the raw key `id` is unique, complete and
format-clean, and it agrees with the independent loan id embedded in every
listing URL. The corruption is in the **control layer** — schema drift between
the semantic layer and the physical model. The failure mode is the dangerous
one for an audit: the control appeared in the repository and in the dbt
documentation, but could never execute, so the loan key was uncontrolled for
39,717 loans.

### Evidence: the failing test on the pre-fix code

`dbt build` on the code as it stood before this change (raw data unchanged):

```
3 of 3 ERROR unique_my_loans_model_loan_id_broken ......... [ERROR in 0.07s]
[ERROR]: Database Error in test not_null_my_loans_model_loan_id_broken
  column "loan_id_broken" does not exist
[ERROR]: Database Error in test unique_my_loans_model_loan_id_broken
  column "loan_id_broken" does not exist
Done. PASS=1 WARN=0 ERROR=2 SKIP=0 TOTAL=3
```

Running the **new** control set against the **old** model (same raw data) is
the red/green proof for the fix:

| Run | Model | Result |
| --- | --- | --- |
| Before the model fix | pre-fix `select *` model | `PASS=22 ERROR=23 FAIL(rows) on 3 tests, TOTAL=45` |
| After the model fix | fixed model | `PASS=45 WARN=0 ERROR=0 SKIP=0 TOTAL=45` |

The 23 errors are the key and typing controls reporting `column "loan_id" does
not exist`, `column "term_months" does not exist` and
`function ... text` type errors — i.e. the pre-fix model exposed no loan key at
all and exposed every amount as text, so no numeric control could be evaluated.

### The fix

`models/example/my_loans_model.sql` now:

1. emits `id` as `loan_id`, the canonical key, tested by DQ-01 / DQ-02;
2. keeps `loan_id_broken` **visible but quarantined** — the column is still
   emitted and still documented in `schema.yml`, but it is forced to
   `cast(null as bigint)`, hidden from the BI layer, and asserted 100% NULL by
   DQ-03, so the defect stays in lineage and any consumer still joining on it
   fails loudly instead of silently returning a cartesian result;
3. resolves the `'NA'` string sentinel to `NULL` and casts each column to its
   profiled type, which is what makes the numeric and range controls
   executable at all.

`scripts/load_db_data.py` ingestion logic is unchanged.

---

## 2. Column profile (raw extract, 39,717 rows)

Full per-column profile is reproducible with the query at the end of this
section. Summary of the columns that carry controls:

| Column | Record type | Null rate | Cardinality | Role |
| --- | --- | --- | --- | --- |
| `id` → `loan_id` | integer (text in raw) | 0.00% | 39,717 | **Key** |
| `member_id` | integer (text in raw) | 0.00% | 39,717 | Key (borrower) |
| `loan_amnt` | integer | 0.00% | 885 | Numeric measure |
| `funded_amnt` | integer | 0.00% | 1,041 | Numeric measure |
| `funded_amnt_inv` | numeric | 0.00% | 8,205 | Numeric measure |
| `installment` | numeric | 0.00% | 15,383 | Numeric measure |
| `int_rate` → `interest_rate` | percentage string → numeric | 0.00% | 371 | Numeric measure |
| `term` → `term_months` | string → integer | 0.00% | 2 | Categorical |
| `grade` | string | 0.00% | 7 | Categorical |
| `sub_grade` | string | 0.00% | 35 | Categorical |
| `loan_status` | string | 0.00% | 3 | Categorical |
| `home_ownership` | string | 0.00% | 5 | Categorical |
| `verification_status` | string | 0.00% | 3 | Categorical |
| `purpose` | string | 0.00% | 14 | Categorical |
| `annual_inc` | numeric (some values in `1.00E+05` notation) | 0.00% | 5,318 | Numeric measure |
| `dti` | numeric | 0.00% | 2,868 | Numeric measure |
| `revol_util` → `revol_util_pct` | percentage string → numeric | 0.13% | 1,089 | Numeric measure |
| `total_pymnt` | numeric | 0.00% | 37,850 | Numeric measure |
| `total_rec_prncp` | numeric | 0.00% | 7,976 | Numeric measure |
| `total_rec_int` | numeric | 0.00% | 35,148 | Numeric measure |
| `recoveries` | numeric | 0.00% | 4,040 | Numeric measure |
| `out_prncp` | numeric | 0.00% | 1,137 | Numeric measure |
| `issue_d` → `issue_date` | `YY-Mon` string → date | 0.00% | 55 | Date |
| `emp_title` | string | 6.18% | 28,822 | Descriptive |
| `desc` → `description` | string | 32.58% | 26,528 | Descriptive |
| `mths_since_last_delinq` | integer | 64.66% | 95 | Numeric (sparse) |
| `mths_since_last_record` | integer | 92.99% | 111 | Numeric (sparse) |
| `next_pymnt_d` | string | 97.13% | 2 | Date (sparse) |

Additional profile findings, all reflected in the model or the controls:

* **`'NA'` is a string, not a NULL.** The extract encodes missing values as the
  literal text `NA`, so an un-typed model reports a 0% null rate on columns
  that are in fact empty. 54 of the 111 columns are 100% `'NA'`
  (`tot_coll_amt`, `tot_cur_bal`, `open_acc_6m`, all `num_*`, `mo_sin_*`,
  `mths_since_recent_*`, `total_bal_ex_mort`, …) — they carry no information in
  this extract and no control is placed on them.
* **Whitespace drift on `term`.** Both raw values carry a leading space
  (`' 36 months'` = 29,096 rows, `' 60 months'` = 10,621 rows). DQ-13 catches
  this: it reported `FAIL 2` on the pre-fix model and passes after the model
  trims the value and derives `term_months`.
* **Text typing defeats numeric controls.** On the pre-fix (all-text) model,
  `funded_amnt <= loan_amnt` returned 376 violations and
  `funded_amnt_inv <= funded_amnt` returned 2,538 — both are lexicographic
  string comparisons, not real breaches. Cast to numeric, the true counts are
  39,717 / 39,717 conforming rows (0 violations).
* `pymnt_plan`, `initial_list_status`, `application_type`, `policy_code`,
  `acc_now_delinq`, `delinq_amnt`, `collections_12_mths_ex_med` and
  `chargeoff_within_12_mths` have cardinality 1 in this extract.

Auditor SQL for the profile (per column; substitute the column name):

```sql
select count(*)                                            as rows,
       count(*) filter (where nullif(nullif(btrim(<col>), ''), 'NA') is null) as nulls,
       count(distinct nullif(nullif(btrim(<col>), ''), 'NA')) as cardinality
from loans;
```

---

## 3. Control register

All tests are executed by `dbt build`. Individual controls can be re-run with
`dbt test --profiles-dir . --select <test_name>`.

| Control | What it asserts | dbt test | Auditor SQL (must return 0 rows / the stated value) | Before | After |
| --- | --- | --- | --- | --- | --- |
| DQ-01 | The loan key is unique — no loan can be double-counted. | `dq_01_loan_key_is_unique` (`unique` on `my_loans_model.loan_id`) | `select loan_id from my_loans_model group by 1 having count(*) > 1;` | ERROR — column did not exist | PASS, 0 duplicate keys over 39,717 rows |
| DQ-02 | The loan key is complete — every row is identifiable. | `dq_02_loan_key_is_not_null` (`not_null`) | `select count(*) from my_loans_model where loan_id is null;` | ERROR — column did not exist | PASS, 0 nulls |
| DQ-03 | The quarantined legacy key is inert: present for lineage, 100% NULL, hidden from BI, unusable as a join key. | `dq_03_quarantined_key_is_inert` (`dbt_utils.expression_is_true`, `is null`) | `select count(*) from my_loans_model where loan_id_broken is not null;` | ERROR — column did not exist | PASS, 39,717 of 39,717 rows NULL |
| DQ-04 | The raw loan key is unique and complete **at source**, separating source defects from transformation defects. | `dq_04_raw_loan_key_is_unique`, `dq_04_raw_loan_key_is_not_null` (on `source lending_club.loans.id`) | `select count(*), count(distinct id), count(*) filter (where id is null) from loans;` | PASS (39,717 / 39,717 / 0) | PASS |
| DQ-05 | The raw borrower key is unique and complete. | `dq_05_raw_member_key_is_unique`, `dq_05_raw_member_key_is_not_null` | `select count(*), count(distinct member_id) from loans;` | PASS | PASS |
| DQ-06 | Row-count parity raw → model: the transformation neither drops nor duplicates loans. | `dq_06_row_count_parity_raw_vs_model` (`dbt_utils.equal_rowcount`) | `select (select count(*) from loans) - (select count(*) from my_loans_model);` → `0` | PASS | PASS, 39,717 = 39,717 |
| DQ-07 | Key parity raw → model: the same loan population came through, not merely the same count. | `dq_07_loan_key_parity_raw_vs_model` (singular test) | `select coalesce(r.id::bigint, m.loan_id) from (select id from loans) r full outer join my_loans_model m on r.id::bigint = m.loan_id where r.id is null or m.loan_id is null;` | ERROR — no key in model | PASS, 0 unmatched keys |
| DQ-08 | `loan_status` is one of the recognised lifecycle states — an unknown state would misstate the loss provision. | `dq_08_loan_status_is_a_known_state`, `dq_08_loan_status_is_not_null` (`accepted_values`) | `select distinct loan_status from my_loans_model;` → `Current`, `Fully Paid`, `Charged Off` | PASS | PASS, 0 violations |
| DQ-09 | `grade` is on the published A–G scale. | `dq_09_grade_is_on_published_scale`, `dq_09_grade_is_not_null` | `select grade, count(*) from my_loans_model group by 1 order by 1;` → 7 grades | PASS | PASS, 0 violations |
| DQ-10 | `sub_grade` is internally consistent with `grade` (letter matches, notch in 1–5). | `dq_10_sub_grade_is_consistent_with_grade` (singular test) | `select count(*) from my_loans_model where left(sub_grade,1) <> grade or right(sub_grade,1) not in ('1','2','3','4','5');` | ERROR — no key in model | PASS, 0 of 39,717 inconsistent |
| DQ-11 | `home_ownership` is a known category. | `dq_11_home_ownership_is_a_known_category` | `select distinct home_ownership from my_loans_model;` → RENT, OWN, MORTGAGE, OTHER, NONE | PASS | PASS |
| DQ-12 | `verification_status` is a known category. | `dq_12_verification_status_is_a_known_category` | `select distinct verification_status from my_loans_model;` → 3 values | PASS | PASS |
| DQ-13 | Term is one of the two contractual products (36 / 60 months), raw string and parsed integer. | `dq_13_term_is_a_valid_product`, `dq_13_term_months_is_36_or_60`, `dq_13_term_months_is_not_null` | `select term_months, count(*) from my_loans_model group by 1;` → 36: 29,096; 60: 10,621 | **FAIL 2** (leading whitespace in raw values) | PASS, 0 violations |
| DQ-14 | `purpose` is one of the 14 known categories. | `dq_14_purpose_is_a_known_category` | `select distinct purpose from my_loans_model;` → 14 values | PASS | PASS |
| DQ-15 | Principal is present, non-negative and plausible ($500–$40,000). | `dq_15_loan_amount_is_not_null`, `dq_15_loan_amount_in_plausible_range` | `select min(loan_amnt), max(loan_amnt) from my_loans_model;` → 500 / 35,000 | ERROR — column was text | PASS, 0 out of range |
| DQ-16 | Funded amount is non-negative and never exceeds the amount applied for. | `dq_16_funded_amount_is_not_null`, `dq_16_funded_amount_is_non_negative`, `dq_16_funded_amount_not_above_loan_amount` | `select count(*) from my_loans_model where funded_amnt > loan_amnt or funded_amnt < 0;` | **FAIL 376** (text comparison on pre-fix model) | PASS, 0 of 39,717 |
| DQ-17 | Investor-funded portion is non-negative and never exceeds the funded amount. | `dq_17_investor_funded_amount_is_non_negative`, `dq_17_investor_funded_not_above_funded_amount` | `select count(*) from my_loans_model where funded_amnt_inv > funded_amnt;` | **FAIL 2,538** (text comparison on pre-fix model) | PASS, 0 of 39,717 |
| DQ-18 | The monthly instalment is strictly positive and below a plausible ceiling ($2,000). | `dq_18_installment_is_not_null`, `dq_18_installment_in_plausible_range` | `select min(installment), max(installment) from my_loans_model;` → 15.69 / 1,305.19 | ERROR — column was text | PASS, 0 out of range |
| DQ-19 | The priced interest rate is present and inside 0–40%. | `dq_19_interest_rate_is_not_null`, `dq_19_interest_rate_in_plausible_range` | `select min(interest_rate), max(interest_rate) from my_loans_model;` → 5.42 / 24.59 | PASS (rate was already derived) | PASS, 0 out of range |
| DQ-20 | Self-reported annual income is non-negative and below a plausible ceiling ($10m). | `dq_20_annual_income_in_plausible_range` | `select min(annual_inc), max(annual_inc) from my_loans_model;` → 4,000 / 6,000,000 | ERROR — column was text | PASS, 0 out of range |
| DQ-21 | Debt-to-income is a valid percentage (0–100). | `dq_21_dti_is_a_valid_percentage` | `select min(dti), max(dti) from my_loans_model;` → 0 / 29.99 | ERROR — column was text | PASS, 0 out of range |
| DQ-22 | Revolving utilisation is a plausible percentage (0–200). | `dq_22_revolving_utilisation_in_plausible_range` | `select min(revol_util_pct), max(revol_util_pct) from my_loans_model;` → 0 / 99.90 | ERROR — column did not exist | PASS, 0 out of range (50 NULLs, 0.13%) |
| DQ-23 | Cash amounts received and outstanding principal are never negative (`total_pymnt`, `total_rec_prncp`, `total_rec_int`, `recoveries`, `out_prncp`). | `dq_23_total_payment_is_non_negative`, `dq_23_principal_received_is_non_negative`, `dq_23_interest_received_is_non_negative`, `dq_23_recoveries_are_non_negative`, `dq_23_outstanding_principal_is_non_negative` | `select count(*) from my_loans_model where least(total_pymnt, total_rec_prncp, total_rec_int, recoveries, out_prncp) < 0;` | ERROR — columns were text | PASS, 0 negative amounts |
| DQ-24 | The borrower key is unique and complete in the model. | `dq_24_member_key_is_unique`, `dq_24_member_key_is_not_null` | `select count(*), count(distinct member_id) from my_loans_model;` → 39,717 / 39,717 | PASS | PASS |
| DQ-25 | Every loan has a parseable issue date inside the extract window (issued 2007-06 to 2011-12). | `dq_25_issue_date_parses_for_every_loan`, `dq_25_issue_date_in_extract_window` | `select min(issue_date), max(issue_date), count(*) filter (where issue_date is null) from my_loans_model;` | PASS | PASS, 0 unparsed |
| DQ-26 | The loan key agrees with the independent loan id embedded in the LC listing URL. | `dq_26_loan_key_matches_listing_url` (singular test) | `select count(*) from my_loans_model where split_part(url,'loan_id=',2)::bigint is distinct from loan_id;` | ERROR — no key in model | PASS, 0 of 39,717 disagree |

Coverage: 26 controls, implemented by 44 dbt tests across
`models/example/schema.yml` (column and model level),
`models/example/sources.yml` (raw layer) and `tests/` (singular tests). Every
control in this register maps to a named dbt test, and every dbt test in the
project maps to a control ID.

---

## 4. Residual risk / not covered

* Controls run on demand (`dbt build`) and in CI
  (`.github/workflows/dbt-qc.yml`); there is no scheduled execution against a
  production warehouse, because this project has no orchestration layer.
* The 54 columns that are 100% `'NA'` in this extract are typed but not
  controlled — there is no data to assert against. If a future extract
  populates them, controls must be added before they reach BI.
* Range bounds (DQ-15, DQ-18, DQ-20, DQ-21, DQ-22) are plausibility bounds set
  from the observed distribution plus headroom, not product limits confirmed by
  the business. They should be ratified by the loan product owner.
* DQ-26 corroborates the key against the listing URL, which is populated by the
  same upstream export; it is strong evidence of key integrity but not an
  independent system of record reconciliation.
