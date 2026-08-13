-- Loan-level analytical model for the Lending Club extract.
--
-- Data-quality control layer: every column below is declared in
-- models/example/schema.yml with the dbt tests that assert it. The auditable
-- control set and its evidence live in docs/loan-data-qc-evidence.md.
--
-- The raw landing table stores every column as text (the extract encodes
-- missing values as the literal string 'NA'), so this model is where the
-- sentinel is resolved to NULL and columns are cast to their true types.

with raw_loans as (

    select * from {{ source('lending_club', 'loans') }}

)

select
    -- CONTROL DQ-01: canonical loan key. The extract names it "id"; the
    -- semantic layer previously pointed its uniqueness/not-null controls at
    -- "loan_id_broken", a column that does not exist in the warehouse.
    nullif(btrim("id"), '')::bigint as loan_id,

    -- CONTROL DQ-03: "loan_id_broken" is quarantined, not dropped. It is kept
    -- visible in the model and in the semantic layer so the defect stays in
    -- lineage, but it is forced to NULL and hidden from BI so that no
    -- downstream consumer can join or aggregate on it. DQ-03 asserts it is
    -- 100% NULL; DQ-01/DQ-02 assert loan_id is the key that replaced it.
    cast(null as bigint) as loan_id_broken,

    nullif(nullif(btrim("member_id"), ''), 'NA') as member_id,
    nullif(nullif(btrim("loan_amnt"), ''), 'NA')::bigint as loan_amnt,
    nullif(nullif(btrim("funded_amnt"), ''), 'NA')::bigint as funded_amnt,
    nullif(nullif(btrim("funded_amnt_inv"), ''), 'NA')::numeric as funded_amnt_inv,
    nullif(nullif(btrim("term"), ''), 'NA') as term,
    nullif(nullif(btrim("int_rate"), ''), 'NA') as int_rate,
    nullif(nullif(btrim("installment"), ''), 'NA')::numeric as installment,
    nullif(nullif(btrim("grade"), ''), 'NA') as grade,
    nullif(nullif(btrim("sub_grade"), ''), 'NA') as sub_grade,
    nullif(nullif(btrim("emp_title"), ''), 'NA') as emp_title,
    nullif(nullif(btrim("emp_length"), ''), 'NA') as emp_length,
    nullif(nullif(btrim("home_ownership"), ''), 'NA') as home_ownership,
    nullif(nullif(btrim("annual_inc"), ''), 'NA')::numeric as annual_inc,
    nullif(nullif(btrim("verification_status"), ''), 'NA') as verification_status,
    nullif(nullif(btrim("issue_d"), ''), 'NA') as issue_d,
    nullif(nullif(btrim("loan_status"), ''), 'NA') as loan_status,
    nullif(nullif(btrim("pymnt_plan"), ''), 'NA') as pymnt_plan,
    nullif(nullif(btrim("url"), ''), 'NA') as url,
    nullif(nullif(btrim("desc"), ''), 'NA') as description,
    nullif(nullif(btrim("purpose"), ''), 'NA') as purpose,
    nullif(nullif(btrim("title"), ''), 'NA') as title,
    nullif(nullif(btrim("zip_code"), ''), 'NA') as zip_code,
    nullif(nullif(btrim("addr_state"), ''), 'NA') as addr_state,
    nullif(nullif(btrim("dti"), ''), 'NA')::numeric as dti,
    nullif(nullif(btrim("delinq_2yrs"), ''), 'NA')::bigint as delinq_2yrs,
    nullif(nullif(btrim("earliest_cr_line"), ''), 'NA') as earliest_cr_line,
    nullif(nullif(btrim("inq_last_6mths"), ''), 'NA')::bigint as inq_last_6mths,
    nullif(nullif(btrim("mths_since_last_delinq"), ''), 'NA')::bigint as mths_since_last_delinq,
    nullif(nullif(btrim("mths_since_last_record"), ''), 'NA')::bigint as mths_since_last_record,
    nullif(nullif(btrim("open_acc"), ''), 'NA')::bigint as open_acc,
    nullif(nullif(btrim("pub_rec"), ''), 'NA')::bigint as pub_rec,
    nullif(nullif(btrim("revol_bal"), ''), 'NA')::bigint as revol_bal,
    nullif(nullif(btrim("revol_util"), ''), 'NA') as revol_util,
    nullif(nullif(btrim("total_acc"), ''), 'NA')::bigint as total_acc,
    nullif(nullif(btrim("initial_list_status"), ''), 'NA') as initial_list_status,
    nullif(nullif(btrim("out_prncp"), ''), 'NA')::numeric as out_prncp,
    nullif(nullif(btrim("out_prncp_inv"), ''), 'NA')::numeric as out_prncp_inv,
    nullif(nullif(btrim("total_pymnt"), ''), 'NA')::numeric as total_pymnt,
    nullif(nullif(btrim("total_pymnt_inv"), ''), 'NA')::numeric as total_pymnt_inv,
    nullif(nullif(btrim("total_rec_prncp"), ''), 'NA')::numeric as total_rec_prncp,
    nullif(nullif(btrim("total_rec_int"), ''), 'NA')::numeric as total_rec_int,
    nullif(nullif(btrim("total_rec_late_fee"), ''), 'NA')::numeric as total_rec_late_fee,
    nullif(nullif(btrim("recoveries"), ''), 'NA')::numeric as recoveries,
    nullif(nullif(btrim("collection_recovery_fee"), ''), 'NA')::numeric as collection_recovery_fee,
    nullif(nullif(btrim("last_pymnt_d"), ''), 'NA') as last_pymnt_d,
    nullif(nullif(btrim("last_pymnt_amnt"), ''), 'NA')::numeric as last_pymnt_amnt,
    nullif(nullif(btrim("next_pymnt_d"), ''), 'NA') as next_pymnt_d,
    nullif(nullif(btrim("last_credit_pull_d"), ''), 'NA') as last_credit_pull_d,
    nullif(nullif(btrim("collections_12_mths_ex_med"), ''), 'NA')::bigint as collections_12_mths_ex_med,
    nullif(nullif(btrim("mths_since_last_major_derog"), ''), 'NA')::numeric as mths_since_last_major_derog,
    nullif(nullif(btrim("policy_code"), ''), 'NA')::bigint as policy_code,
    nullif(nullif(btrim("application_type"), ''), 'NA') as application_type,
    nullif(nullif(btrim("annual_inc_joint"), ''), 'NA')::numeric as annual_inc_joint,
    nullif(nullif(btrim("dti_joint"), ''), 'NA')::numeric as dti_joint,
    nullif(nullif(btrim("verification_status_joint"), ''), 'NA') as verification_status_joint,
    nullif(nullif(btrim("acc_now_delinq"), ''), 'NA')::bigint as acc_now_delinq,
    nullif(nullif(btrim("tot_coll_amt"), ''), 'NA')::numeric as tot_coll_amt,
    nullif(nullif(btrim("tot_cur_bal"), ''), 'NA')::numeric as tot_cur_bal,
    nullif(nullif(btrim("open_acc_6m"), ''), 'NA')::numeric as open_acc_6m,
    nullif(nullif(btrim("open_il_6m"), ''), 'NA')::numeric as open_il_6m,
    nullif(nullif(btrim("open_il_12m"), ''), 'NA')::numeric as open_il_12m,
    nullif(nullif(btrim("open_il_24m"), ''), 'NA')::numeric as open_il_24m,
    nullif(nullif(btrim("mths_since_rcnt_il"), ''), 'NA')::numeric as mths_since_rcnt_il,
    nullif(nullif(btrim("total_bal_il"), ''), 'NA')::numeric as total_bal_il,
    nullif(nullif(btrim("il_util"), ''), 'NA')::numeric as il_util,
    nullif(nullif(btrim("open_rv_12m"), ''), 'NA')::numeric as open_rv_12m,
    nullif(nullif(btrim("open_rv_24m"), ''), 'NA')::numeric as open_rv_24m,
    nullif(nullif(btrim("max_bal_bc"), ''), 'NA')::numeric as max_bal_bc,
    nullif(nullif(btrim("all_util"), ''), 'NA')::numeric as all_util,
    nullif(nullif(btrim("total_rev_hi_lim"), ''), 'NA')::numeric as total_rev_hi_lim,
    nullif(nullif(btrim("inq_fi"), ''), 'NA')::numeric as inq_fi,
    nullif(nullif(btrim("total_cu_tl"), ''), 'NA')::numeric as total_cu_tl,
    nullif(nullif(btrim("inq_last_12m"), ''), 'NA')::numeric as inq_last_12m,
    nullif(nullif(btrim("acc_open_past_24mths"), ''), 'NA')::numeric as acc_open_past_24mths,
    nullif(nullif(btrim("avg_cur_bal"), ''), 'NA')::numeric as avg_cur_bal,
    nullif(nullif(btrim("bc_open_to_buy"), ''), 'NA')::numeric as bc_open_to_buy,
    nullif(nullif(btrim("bc_util"), ''), 'NA')::numeric as bc_util,
    nullif(nullif(btrim("chargeoff_within_12_mths"), ''), 'NA')::bigint as chargeoff_within_12_mths,
    nullif(nullif(btrim("delinq_amnt"), ''), 'NA')::bigint as delinq_amnt,
    nullif(nullif(btrim("mo_sin_old_il_acct"), ''), 'NA')::numeric as mo_sin_old_il_acct,
    nullif(nullif(btrim("mo_sin_old_rev_tl_op"), ''), 'NA')::numeric as mo_sin_old_rev_tl_op,
    nullif(nullif(btrim("mo_sin_rcnt_rev_tl_op"), ''), 'NA')::numeric as mo_sin_rcnt_rev_tl_op,
    nullif(nullif(btrim("mo_sin_rcnt_tl"), ''), 'NA')::numeric as mo_sin_rcnt_tl,
    nullif(nullif(btrim("mort_acc"), ''), 'NA')::numeric as mort_acc,
    nullif(nullif(btrim("mths_since_recent_bc"), ''), 'NA')::numeric as mths_since_recent_bc,
    nullif(nullif(btrim("mths_since_recent_bc_dlq"), ''), 'NA')::numeric as mths_since_recent_bc_dlq,
    nullif(nullif(btrim("mths_since_recent_inq"), ''), 'NA')::numeric as mths_since_recent_inq,
    nullif(nullif(btrim("mths_since_recent_revol_delinq"), ''), 'NA')::numeric as mths_since_recent_revol_delinq,
    nullif(nullif(btrim("num_accts_ever_120_pd"), ''), 'NA')::numeric as num_accts_ever_120_pd,
    nullif(nullif(btrim("num_actv_bc_tl"), ''), 'NA')::numeric as num_actv_bc_tl,
    nullif(nullif(btrim("num_actv_rev_tl"), ''), 'NA')::numeric as num_actv_rev_tl,
    nullif(nullif(btrim("num_bc_sats"), ''), 'NA')::numeric as num_bc_sats,
    nullif(nullif(btrim("num_bc_tl"), ''), 'NA')::numeric as num_bc_tl,
    nullif(nullif(btrim("num_il_tl"), ''), 'NA')::numeric as num_il_tl,
    nullif(nullif(btrim("num_op_rev_tl"), ''), 'NA')::numeric as num_op_rev_tl,
    nullif(nullif(btrim("num_rev_accts"), ''), 'NA')::numeric as num_rev_accts,
    nullif(nullif(btrim("num_rev_tl_bal_gt_0"), ''), 'NA')::numeric as num_rev_tl_bal_gt_0,
    nullif(nullif(btrim("num_sats"), ''), 'NA')::numeric as num_sats,
    nullif(nullif(btrim("num_tl_120dpd_2m"), ''), 'NA')::numeric as num_tl_120dpd_2m,
    nullif(nullif(btrim("num_tl_30dpd"), ''), 'NA')::numeric as num_tl_30dpd,
    nullif(nullif(btrim("num_tl_90g_dpd_24m"), ''), 'NA')::numeric as num_tl_90g_dpd_24m,
    nullif(nullif(btrim("num_tl_op_past_12m"), ''), 'NA')::numeric as num_tl_op_past_12m,
    nullif(nullif(btrim("pct_tl_nvr_dlq"), ''), 'NA')::numeric as pct_tl_nvr_dlq,
    nullif(nullif(btrim("percent_bc_gt_75"), ''), 'NA')::numeric as percent_bc_gt_75,
    nullif(nullif(btrim("pub_rec_bankruptcies"), ''), 'NA')::bigint as pub_rec_bankruptcies,
    nullif(nullif(btrim("tax_liens"), ''), 'NA')::bigint as tax_liens,
    nullif(nullif(btrim("tot_hi_cred_lim"), ''), 'NA')::numeric as tot_hi_cred_lim,
    nullif(nullif(btrim("total_bal_ex_mort"), ''), 'NA')::numeric as total_bal_ex_mort,
    nullif(nullif(btrim("total_bc_limit"), ''), 'NA')::numeric as total_bc_limit,
    nullif(nullif(btrim("total_il_high_credit_limit"), ''), 'NA')::numeric as total_il_high_credit_limit,

    -- Derived columns: parsed dates and numeric interest rate.
    to_date(nullif(btrim("issue_d"), ''), 'YY-Mon') as issue_date,
    to_date(nullif(btrim("last_credit_pull_d"), ''), 'YY-Mon') as last_credit_pull_date,
    to_date(nullif(btrim("last_pymnt_d"), ''), 'YY-Mon') as last_pymnt_date,
    replace(nullif(btrim("int_rate"), ''), '%', '')::numeric as interest_rate,
    replace(nullif(nullif(btrim("revol_util"), ''), 'NA'), '%', '')::numeric as revol_util_pct,
    btrim(replace(nullif(btrim("term"), ''), 'months', ''))::int as term_months

from raw_loans
