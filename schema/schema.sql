-- ============================================================
-- Insurance Underwriting NL-to-SQL Benchmark
-- SQLite Schema DDL
-- 대상: questionset_v2_part1.json (UW001~045)
--       questionset_v2_part2.json (UW046~080)
-- ============================================================

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- ============================================================
-- 1. 보험상품 (products)
-- ============================================================
CREATE TABLE IF NOT EXISTS products (
    product_id                      TEXT PRIMARY KEY,
    product_name                    TEXT NOT NULL,
    product_category                TEXT NOT NULL,   -- protection / savings / annuity / third_insurance / variable
    product_type                    TEXT,            -- actual_loss_medical / interest_linked / foreign_currency / whole_life 등
    product_group                   TEXT,            -- group / travel / individual
    insurance_type                  TEXT,            -- life / non_life
    medical_insurance_subtype       TEXT,            -- basic / elderly / high_risk
    contract_type                   TEXT,            -- main / rider
    insurance_period                TEXT,            -- whole_life / term / 숫자(년)
    insurance_period_years          INTEGER,
    payment_period_years            INTEGER,
    payment_type                    TEXT,            -- full_term / short_term
    payment_cycle                   TEXT,            -- monthly / quarterly / annual
    reference_age                   INTEGER,
    survival_benefit_total          REAL,
    expected_total_premium          REAL,
    min_guaranteed_rate             REAL,
    inpatient_deductible_rate       REAL,
    last_coverage_change_date       TEXT,            -- ISO 8601
    auto_renewal_flag               INTEGER DEFAULT 0,  -- 0/1
    low_surrender_value_type        INTEGER DEFAULT 0,  -- 0/1 (무해약환급금형)
    post_annuity_death_benefit_flag INTEGER DEFAULT 0,  -- 0/1
    contract_conclusion_cost        REAL,
    standard_surrender_charge       REAL,
    contract_cost_index             REAL,
    front_loaded_cost_ratio         REAL,
    contract_cost_distribution_type TEXT,            -- uniform / front_loaded
    created_at                      TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 2. 보험회사 (insurance_companies)
-- ============================================================
CREATE TABLE IF NOT EXISTS insurance_companies (
    company_id                  TEXT PRIMARY KEY,
    company_name                TEXT NOT NULL,
    solvency_ratio              REAL,           -- 지급여력비율 (%)
    solvency_ratio_last_quarter REAL,
    created_at                  TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 3. 피보험자 (insured)
-- ============================================================
CREATE TABLE IF NOT EXISTS insured (
    insured_id      TEXT PRIMARY KEY,
    insured_name    TEXT,
    birth_date      TEXT,
    gender          TEXT CHECK(gender IN ('M', 'F')),
    age_at_entry    INTEGER,
    insured_age     INTEGER,
    death_date      TEXT,
    created_at      TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 4. 모집종사자 (agents)
-- ============================================================
CREATE TABLE IF NOT EXISTS agents (
    agent_id         TEXT PRIMARY KEY,
    agent_name       TEXT NOT NULL,
    agency_name      TEXT,
    commission_plan_id TEXT,
    created_at       TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 5. 수수료 플랜 (commission_plans)
-- ============================================================
CREATE TABLE IF NOT EXISTS commission_plans (
    commission_plan_id TEXT PRIMARY KEY,
    commission_type    TEXT NOT NULL   -- split / standard
);

-- ============================================================
-- 6. 보험계약 (contracts)  ★ 핵심 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS contracts (
    contract_id                     TEXT PRIMARY KEY,
    product_id                      TEXT NOT NULL REFERENCES products(product_id),
    insured_id                      TEXT NOT NULL REFERENCES insured(insured_id),
    company_id                      TEXT REFERENCES insurance_companies(company_id),
    agent_id                        TEXT REFERENCES agents(agent_id),
    policyholder_id                 TEXT,           -- 계약자 ID
    contract_date                   TEXT NOT NULL,  -- 청약일
    coverage_start_date             TEXT,           -- 보장개시일
    termination_date                TEXT,
    annuity_start_date              TEXT,
    contract_status                 TEXT NOT NULL
        CHECK(contract_status IN ('active','terminated','expired','withdrawn','suspended','무효')),
    termination_reason              TEXT,           -- 고지의무위반 / 중대사유 / 납입연체 / 강제집행 / 사기 등
    cancellation_reason             TEXT,
    coverage_type                   TEXT,           -- 사망 / 장해 / 입원 / 연금 등
    contract_type                   TEXT,           -- 진단계약 / 무진단계약
    monthly_premium                 REAL,
    annual_premium                  REAL,
    total_paid_premium              REAL,
    sum_insured                     REAL,           -- 보험가입금액
    death_benefit                   REAL,
    min_death_benefit               REAL,           -- 변액보험 최저사망보험금
    surrender_value                 REAL,           -- 해지환급금
    surrender_value_standard_type   REAL,           -- 표준형 해지환급금
    remaining_coverage_reserve      REAL,           -- 계약자적립액(잔여보장요소)
    policyholder_reserve            REAL,           -- 계약자적립액
    reserve_amount_at_7yr           REAL,
    expected_total_premium_7yr      REAL,
    loan_balance                    REAL DEFAULT 0,
    payment_count                   INTEGER DEFAULT 0,
    payment_year_elapsed            INTEGER DEFAULT 0,
    insured_age_at_contract         INTEGER,
    insurance_age                   INTEGER,
    third_party_death_coverage      INTEGER DEFAULT 0,  -- 0/1
    insured_written_consent         INTEGER DEFAULT 1,  -- 0/1
    health_exam_completed           INTEGER DEFAULT 1,  -- 0/1
    age_correction_applied          INTEGER DEFAULT 0,  -- 0/1
    original_premium                REAL,
    corrected_premium               REAL,
    disability_rate_revised         INTEGER DEFAULT 0,  -- 0/1
    fraud_type                      TEXT,
    causation_proven                INTEGER DEFAULT 0,  -- 0/1
    currency_code                   TEXT DEFAULT 'KRW',
    current_monthly_premium_krw     REAL,
    third_insurance_period_years    INTEGER,
    created_at                      TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 7. 언더라이팅 심사결과 (underwriting_decisions)
-- ============================================================
CREATE TABLE IF NOT EXISTS underwriting_decisions (
    decision_id                 TEXT PRIMARY KEY,
    contract_id                 TEXT NOT NULL REFERENCES contracts(contract_id),
    product_id                  TEXT REFERENCES products(product_id),
    decision_type               TEXT NOT NULL
        CHECK(decision_type IN ('승낙','조건부승낙','거절')),
    condition_type              TEXT,           -- 보험료할증 / 보장제외 / 보험금삭감 / 보험가입금액제한
    premium_surcharge_rate      REAL DEFAULT 0,
    risk_surcharge_rate         REAL DEFAULT 0,
    extra_surcharge_rate        REAL DEFAULT 0,
    risk_premium_before_surcharge REAL,
    decision_date               TEXT,
    created_at                  TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 8. 보험금 청구 (claims)
-- ============================================================
CREATE TABLE IF NOT EXISTS claims (
    claim_id                    TEXT PRIMARY KEY,
    contract_id                 TEXT NOT NULL REFERENCES contracts(contract_id),
    insured_id                  TEXT REFERENCES insured(insured_id),
    claim_type                  TEXT NOT NULL,   -- 사망보험금 / 장해보험금 / 입원보험금 / 만기보험금
    claim_date                  TEXT NOT NULL,
    claim_status                TEXT NOT NULL
        CHECK(claim_status IN ('지급완료','지급거절','심사중','소멸시효완성')),
    paid_amount                 REAL DEFAULT 0,
    due_payment_date            TEXT,
    actual_payment_date         TEXT,
    additional_interest_amount  REAL DEFAULT 0,
    business_days_to_payment    INTEGER,
    payment_method              TEXT DEFAULT '일시지급',   -- 일시지급 / 분할지급
    interest_added_amount       REAL DEFAULT 0,
    provisional_payment_made    INTEGER DEFAULT 0,        -- 0/1
    provisional_payment_amount  REAL DEFAULT 0,
    investigation_consent       INTEGER DEFAULT 1,        -- 0/1
    claim_denial_reason         TEXT,
    denial_detail               TEXT,
    death_cause                 TEXT,
    death_cause_type            TEXT,
    icd_code                    TEXT,
    missing_period_days         INTEGER,
    -- 장해 관련
    disability_type             TEXT,
    disability_subtype          TEXT,
    disability_body_part        TEXT,
    disability_payment_rate     REAL,
    disability_rate_fixed_days  INTEGER,
    cdr_score                   INTEGER,
    primary_diagnosis           TEXT,
    disability_assessment_date  TEXT,
    onset_date                  TEXT,
    -- 연금 관련
    annuity_start_date          TEXT,
    insurance_event_date        TEXT,
    claim_expiry_date           TEXT,
    created_at                  TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 9. 피보험자 건강이력 (medical_history)
-- ============================================================
CREATE TABLE IF NOT EXISTS medical_history (
    history_id          TEXT PRIMARY KEY,
    insured_id          TEXT NOT NULL REFERENCES insured(insured_id),
    contract_id         TEXT REFERENCES contracts(contract_id),
    diagnosis_code      TEXT NOT NULL,
    prior_diagnosis_code TEXT,
    treatment_date      TEXT NOT NULL,
    contract_date       TEXT,
    created_at          TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 10. 보장제외 내역 (contract_exclusions)
-- ============================================================
CREATE TABLE IF NOT EXISTS contract_exclusions (
    exclusion_id    TEXT PRIMARY KEY,
    contract_id     TEXT NOT NULL REFERENCES contracts(contract_id),
    exclusion_type  TEXT NOT NULL,
    created_at      TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 11. 계약 부활 / 갱신 이력 (contract_revivals)
-- ============================================================
CREATE TABLE IF NOT EXISTS contract_revivals (
    revival_id                  TEXT PRIMARY KEY,
    contract_id                 TEXT REFERENCES contracts(contract_id),
    product_id                  TEXT REFERENCES products(product_id),
    renewed_contract_id         TEXT,
    revival_reason              TEXT,           -- 부활 / 특별부활
    original_termination_reason TEXT,
    revival_application_date    TEXT,
    termination_date            TEXT,
    renewal_date                TEXT,
    premium_before_renewal      REAL,
    premium_after_renewal       REAL,
    original_contract_cost      REAL,
    renewal_contract_cost       REAL,
    relative_rate_applied       INTEGER DEFAULT 0,  -- 0/1
    paid_within_notice_period   INTEGER DEFAULT 0,  -- 0/1
    created_at                  TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 12. 청약철회 (contract_withdrawals)
-- ============================================================
CREATE TABLE IF NOT EXISTS contract_withdrawals (
    withdrawal_id       TEXT PRIMARY KEY,
    contract_id         TEXT NOT NULL REFERENCES contracts(contract_id),
    withdrawal_date     TEXT NOT NULL,
    policy_issue_date   TEXT NOT NULL,
    created_at          TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 13. 계약변경 이력 (contract_changes)
-- ============================================================
CREATE TABLE IF NOT EXISTS contract_changes (
    change_id                   TEXT PRIMARY KEY,
    contract_id                 TEXT NOT NULL REFERENCES contracts(contract_id),
    change_type                 TEXT NOT NULL,   -- 보험종목변경 / 보험수익자변경 / 보험가입금액변경
    change_status               TEXT NOT NULL
        CHECK(change_status IN ('승인','거절')),
    change_request_date         TEXT NOT NULL,
    first_premium_payment_date  TEXT,
    created_at                  TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 14. 납입최고 이력 (premium_notices)
-- ============================================================
CREATE TABLE IF NOT EXISTS premium_notices (
    notice_id                   TEXT PRIMARY KEY,
    contract_id                 TEXT NOT NULL REFERENCES contracts(contract_id),
    notice_date                 TEXT NOT NULL,
    arrear_payment_date         TEXT,
    paid_within_notice_period   INTEGER DEFAULT 0,  -- 0/1
    created_at                  TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 15. 보험계약대출 차감 (loan_deductions)
-- ============================================================
CREATE TABLE IF NOT EXISTS loan_deductions (
    deduction_id    TEXT PRIMARY KEY,
    contract_id     TEXT NOT NULL REFERENCES contracts(contract_id),
    deduction_type  TEXT NOT NULL,   -- 해지환급금차감 / 보험금차감
    deduction_date  TEXT NOT NULL,
    deduction_amount REAL NOT NULL,
    created_at      TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 16. 수수료 지급 (commission_payments)
-- ============================================================
CREATE TABLE IF NOT EXISTS commission_payments (
    payment_id          TEXT PRIMARY KEY,
    contract_id         TEXT NOT NULL REFERENCES contracts(contract_id),
    agent_id            TEXT REFERENCES agents(agent_id),
    total_commission_paid REAL NOT NULL,
    payment_date        TEXT,
    created_at          TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 17. 모집채널 (sales_channels)
-- ============================================================
CREATE TABLE IF NOT EXISTS sales_channels (
    channel_id              TEXT PRIMARY KEY,
    contract_id             TEXT NOT NULL REFERENCES contracts(contract_id),
    channel_type            TEXT NOT NULL,   -- telemarketing / bancassurance / agency / direct
    voice_recording_completed INTEGER DEFAULT 1,  -- 0/1
    created_at              TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 18. 품질점검 (quality_checks)
-- ============================================================
CREATE TABLE IF NOT EXISTS quality_checks (
    check_id        TEXT PRIMARY KEY,
    contract_id     TEXT NOT NULL REFERENCES contracts(contract_id),
    check_date      TEXT NOT NULL,
    check_result    TEXT NOT NULL,   -- pass / insufficient_explanation / fail
    created_at      TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 19. 위반이력 (violation_records)
-- ============================================================
CREATE TABLE IF NOT EXISTS violation_records (
    violation_id    TEXT PRIMARY KEY,
    agent_id        TEXT NOT NULL REFERENCES agents(agent_id),
    violation_type  TEXT NOT NULL,   -- principal_guarantee_solicitation / unfair_sale 등
    violation_date  TEXT,
    created_at      TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 20. 모집종사자 판매통계 (agent_sales_stats)
-- ============================================================
CREATE TABLE IF NOT EXISTS agent_sales_stats (
    stat_id             TEXT PRIMARY KEY,
    agent_id            TEXT NOT NULL REFERENCES agents(agent_id),
    reference_year      INTEGER NOT NULL,
    total_contracts     INTEGER DEFAULT 0,
    unfair_sale_count   INTEGER DEFAULT 0,
    created_at          TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 21. 위험액 (risk_capitals)
-- ============================================================
CREATE TABLE IF NOT EXISTS risk_capitals (
    risk_id                 TEXT PRIMARY KEY,
    product_id              TEXT NOT NULL REFERENCES products(product_id),
    quarter                 INTEGER NOT NULL,   -- YYYYQ (예: 20241)
    mortality_risk_amount   REAL DEFAULT 0,    -- 사망위험액
    lapse_risk_amount       REAL DEFAULT 0,    -- 해지위험액
    created_at              TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 22. 자산건전성 분류 (asset_loan_classifications)
-- ============================================================
CREATE TABLE IF NOT EXISTS asset_loan_classifications (
    loan_id                 TEXT PRIMARY KEY,
    contract_id             TEXT REFERENCES contracts(contract_id),
    loan_type               TEXT NOT NULL,   -- household / corporate
    asset_classification    TEXT NOT NULL
        CHECK(asset_classification IN ('normal','precautionary','substandard','doubtful','loss')),
    loan_balance            REAL NOT NULL,
    actual_allowance        REAL DEFAULT 0,
    created_at              TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 23. 계리 검증의견 (actuary_opinions)
-- ============================================================
CREATE TABLE IF NOT EXISTS actuary_opinions (
    opinion_id          TEXT PRIMARY KEY,
    product_id          TEXT REFERENCES products(product_id),
    submission_year     INTEGER NOT NULL,
    verification_item   TEXT NOT NULL,   -- liability_reserve / risk_reserve 등
    opinion_result      TEXT NOT NULL,   -- unqualified / adverse / qualified
    created_at          TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 24. 공시이율 정보 (declared_rate_info)
-- ============================================================
CREATE TABLE IF NOT EXISTS declared_rate_info (
    rate_id                         TEXT PRIMARY KEY,
    product_id                      TEXT REFERENCES products(product_id),
    rate_year                       INTEGER NOT NULL,
    account_type                    TEXT,
    declared_rate_excluding_unrealized REAL,
    declared_rate_including_unrealized REAL,
    created_at                      TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- 25. 환율 이력 (exchange_rate_history)
-- ============================================================
CREATE TABLE IF NOT EXISTS exchange_rate_history (
    rate_id         TEXT PRIMARY KEY,
    currency_code   TEXT NOT NULL,
    rate_date       TEXT NOT NULL,
    rate            REAL NOT NULL,   -- 1외화 = N원
    created_at      TEXT DEFAULT (DATE('now')),
    UNIQUE(currency_code, rate_date)
);

-- ============================================================
-- 26. 계약묶음 (contract_bundles)
-- ============================================================
CREATE TABLE IF NOT EXISTS contract_bundles (
    bundle_id           TEXT PRIMARY KEY,
    main_contract_id    TEXT NOT NULL REFERENCES contracts(contract_id),
    bundled_product_id  TEXT REFERENCES products(product_id),
    created_at          TEXT DEFAULT (DATE('now'))
);

-- ============================================================
-- INDEX (자주 쓰이는 조회 컬럼)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_contracts_status       ON contracts(contract_status);
CREATE INDEX IF NOT EXISTS idx_contracts_product      ON contracts(product_id);
CREATE INDEX IF NOT EXISTS idx_contracts_insured      ON contracts(insured_id);
CREATE INDEX IF NOT EXISTS idx_contracts_agent        ON contracts(agent_id);
CREATE INDEX IF NOT EXISTS idx_contracts_date         ON contracts(contract_date);
CREATE INDEX IF NOT EXISTS idx_contracts_term_reason  ON contracts(termination_reason);

CREATE INDEX IF NOT EXISTS idx_claims_type            ON claims(claim_type);
CREATE INDEX IF NOT EXISTS idx_claims_status          ON claims(claim_status);
CREATE INDEX IF NOT EXISTS idx_claims_contract        ON claims(contract_id);
CREATE INDEX IF NOT EXISTS idx_claims_date            ON claims(claim_date);

CREATE INDEX IF NOT EXISTS idx_uw_contract            ON underwriting_decisions(contract_id);
CREATE INDEX IF NOT EXISTS idx_uw_decision_type       ON underwriting_decisions(decision_type);

CREATE INDEX IF NOT EXISTS idx_medical_insured        ON medical_history(insured_id);
CREATE INDEX IF NOT EXISTS idx_sales_contract         ON sales_channels(contract_id);
CREATE INDEX IF NOT EXISTS idx_violations_agent       ON violation_records(agent_id);
CREATE INDEX IF NOT EXISTS idx_risk_product_quarter   ON risk_capitals(product_id, quarter);
CREATE INDEX IF NOT EXISTS idx_exrate_currency_date   ON exchange_rate_history(currency_code, rate_date);