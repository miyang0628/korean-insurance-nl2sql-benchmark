# Korean Insurance Underwriting NL-to-SQL Benchmark

> 생명보험 언더라이팅 AI 평가를 위한 한국어 NL-to-SQL 벤치마크  
> A Korean-language NL-to-SQL Benchmark for Life Insurance Underwriting AI Evaluation

---

> 📄 본 리포지토리는 현재 심사 중인 논문의 실험 재현을 위해 공개되었습니다.  
> This repository accompanies a paper currently under review.

---

## 개요 | Overview

자연어를 SQL로 변환하는 NL-to-SQL 기술은 생명보험 언더라이팅 업무의 AI 기반 질의 시스템 구현을 위한 핵심 기반으로 부상하고 있으나, 국내 보험 규제 체계에 부합하는 한국어 특화 벤치마크는 충분히 구축되지 않은 실정입니다.

본 리포지토리는 생명보험 표준약관 \[별표15\]와 보험업감독규정(금융위원회고시 제2024-54호)을 출처로 하는 **80개 한국어 질문셋(UW001–UW080)**을 최초로 설계·검증하고, **Text-to-SQL**(DDL 직접 노출)과 **Semantic Layer**(비즈니스 개념 기반) 두 접근법을 비교 실험한 코드를 포함합니다.

---

## 데이터 출처 | Regulatory Sources

| 문서 | 질문 수 |
|------|---------|
| 생명보험 표준약관 \[별표15\] (생명보험협회, 현행) | 45개 |
| 보험업감독규정 (금융위원회고시 제2024-54호, 2024) | 35개 |
| **합계** | **80개** |

---

## 벤치마크 구성 | Benchmark Structure

### 카테고리별 분포 (표 1)

| 카테고리 | 질문 수 | 비율 |
|----------|---------|------|
| 보험금지급 | 14 | 17.5% |
| 계약관리 | 13 | 16.3% |
| 계약심사 | 13 | 16.3% |
| 장해리스크 | 13 | 16.3% |
| 보험료산출 | 10 | 12.5% |
| 사기탐지 | 7 | 8.8% |
| 고지의무 | 6 | 7.5% |
| 재무리스크 | 4 | 5.0% |
| **합계** | **80** | **100%** |

### 난이도 및 민감정보 수준별 분포 (표 2)

| 구분 | 분류 | 질문 수 | 비율 |
|------|------|---------|------|
| 난이도 | simple | 14 | 17.5% |
| | moderate | 46 | 57.5% |
| | challenging | 20 | 25.0% |
| 민감정보 수준 | high | 23 | 28.8% |
| | medium | 37 | 46.2% |
| | low | 20 | 25.0% |

> **난이도 기준**: SQL 복잡도(조인 수, 집계 함수, 서브쿼리 중첩) 및 도메인 용어 해석 요구 수준  
> **민감정보 수준 기준**: `high` = 건강정보·개인식별정보·사기·위반정보 포함 / `medium` = 재무정보·계약 메타정보 / `low` = 집계 통계·비식별 정보

---

## 실험 설계 | Experimental Design

- **모델**: GPT-4o-mini (temperature = 0)
- **비교 조건**:
  - `Text-to-SQL (T2S)`: 26개 테이블 DDL 전체를 프롬프트에 직접 제공
  - `Semantic Layer (SL)`: DDL 대신 비즈니스 개념 정의(metric 명칭, 자연어 설명, 계산 로직)를 제공하고 내부 매핑 변환을 거쳐 SQL 생성
- **반복 횟수**: 조건당 3회 반복, 총 API 호출 **480회** (80문항 × 2조건 × 3반복)
- **데이터베이스**: SQLite, 26개 테이블, 샘플 200계약
- **평가 지표**:
  - 실행 정확도(Execution Accuracy, EX): BIRD(Li et al., 2023) 기준
  - 민감정보 노출 수: 스키마 수준 + 쿼리 수준 이원 측정
  - 응답시간(ms)
- **통계 검정**: 카이제곱 검정, McNemar 검정, Cohen's d, 부트스트랩 95% CI (n=1,000)

---

## 주요 결과 | Key Results

### RQ1: 전체 실행 정확도 비교 (표 3)

| 지표 | Text-to-SQL | Semantic Layer | 차이 |
|------|-------------|----------------|------|
| 전체 EX | 23.8% | 29.2% | +5.4%p |
| 95% CI | \[18.3%, 29.2%\] | \[23.3%, 35.0%\] | — |
| χ² (카이제곱) | — | — | 1.542, p=0.214 (n.s.) |
| McNemar χ² | — | — | 1.565, p=0.211 (n.s.) |
| Cohen's d | — | — | 0.123 (negligible) |

> Semantic Layer는 정확도를 통계적으로 동등하게 유지하면서 보안성을 강화함.  
> 반복 안정성: T2S σ=0.0217 → SL σ=0.0072 (약 3분의 1 수준)

### RQ2: 민감정보 노출 비교 (표 7)

| 측정 수준 | Text-to-SQL | Semantic Layer | 감소율 |
|-----------|-------------|----------------|--------|
| 개념 정의 내 원시 컬럼 | 23개 | 0개 | **−100%** |
| 프롬프트 전체 (매핑 포함) | 23개 | 15개 | −34.8% |
| — 건강정보 | 10개 | 6개 | −4개 |
| — 재무정보 | 6개 | 6개 | 0개 |
| — 개인식별정보 | 4개 | 1개 | −3개 |
| — 사기·위반정보 | 3개 | 2개 | −1개 |

### RQ3: 민감정보 수준별 교차 분석 (표 8) — 핵심 결과

| 민감도 | 질문 수 | T2S EX | SL EX | 차이 | p값 |
|--------|---------|--------|-------|------|-----|
| **high** | 23 | 29.0% | 59.4% | **+30.4%p** | **0.0006 ✅** |
| medium | 37 | 19.8% | 18.0% | −1.8%p | 0.864 (n.s.) |
| low | 20 | 25.0% | 15.0% | −10.0%p | 0.254 (n.s.) |

> 민감정보 수준이 **high**인 질문군에서 Semantic Layer의 보안성 강화와 효율성 향상이 **상보적으로 작용** (χ²=11.752, p=0.0006).  
> 이는 Tornatzky & Fleischer(1990)의 TOE 프레임워크에서 논의된 보안-효율성 딜레마가 구조적 추상화 계층 설계를 통해 완화될 수 있음을 시사함.

---

## 폴더 구조 | Repository Structure

```
korean-insurance-nl2sql-benchmark/
├── benchmark/
│   └── metadata.json              # 질문셋 메타데이터 (UW001–UW080)
├── schema/
│   └── schema.sql                 # SQLite DDL (26개 테이블)
├── data/
│   └── sample_data.sql            # 샘플 데이터 (가상 200계약)
├── semantic_layer/
│   ├── schema_context.yaml        # Semantic Layer 비즈니스 개념 정의
│   └── sql_mapping.yaml           # 비즈니스 개념 → 원시 컬럼 매핑
├── prompts/
│   ├── prompt_text2sql.txt        # Text-to-SQL 프롬프트
│   └── prompt_semantic_layer.txt  # Semantic Layer 프롬프트
├── notebooks/
│   ├── 00_setup.ipynb             # DB 초기화 및 환경 검증
│   ├── 01_gold_sql_validation.ipynb   # Gold SQL 전수 실행 검증 (80/80)
│   ├── 02_experiment_text2sql.ipynb   # T2S 실험 (3회 반복)
│   ├── 03_experiment_semantic_layer.ipynb  # SL 실험 (3회 반복)
│   ├── 04_results_analysis.ipynb  # EX 비교 및 통계 검정 (RQ1)
│   ├── 05_sensitivity_analysis.ipynb  # 민감정보 수준별 교차 분석 (RQ2·RQ3)
│   └── 06_paper_figures.ipynb     # 논문 수록 그림 생성
├── results/
│   ├── raw/                       # 실험 원시 결과 (CSV)
│   └── figures/                   # 논문 수록 그림 (fig1–fig8)
├── setup_project.py               # 프로젝트 초기화 스크립트
├── requirements.txt
└── README.md
```

---

## 환경 설정 | Setup

```bash
# 1. 가상환경 생성 및 활성화
conda create -n uw-benchmark python=3.11
conda activate uw-benchmark

# 2. 프로젝트 구조 생성 및 패키지 설치
python setup_project.py

# 3. API 키 설정 (.env)
OPENAI_API_KEY=your_key_here

# 4. Jupyter 실행
jupyter notebook
```

### 주요 의존성 | Dependencies

```
openai>=1.0.0
pandas>=2.0.0
numpy>=1.24.0
scipy>=1.10.0
matplotlib>=3.7.0
seaborn>=0.12.0
pyyaml>=6.0
tqdm>=4.65.0
```

전체 목록: `requirements.txt` 참조

---

## 노트북 실행 순서 | Notebook Execution Order

| 순서 | 파일 | 대응 논문 섹션 |
|------|------|--------------|
| 1 | `00_setup.ipynb` | 3.2 실험 설계 |
| 2 | `01_gold_sql_validation.ipynb` | 3.1 질문셋 설계 |
| 3 | `02_experiment_text2sql.ipynb` | 3.2 실험 설계 |
| 4 | `03_experiment_semantic_layer.ipynb` | 3.2 실험 설계 |
| 5 | `04_results_analysis.ipynb` | 4.1 RQ1 |
| 6 | `05_sensitivity_analysis.ipynb` | 4.2 RQ2 / 4.3 RQ3 |
| 7 | `06_paper_figures.ipynb` | Fig. 1–8 |

---

## 윤리 및 라이선스 | Ethics & License

- 샘플 데이터는 **완전 가상 데이터**이며 실제 계약자 정보를 포함하지 않습니다.
- 규제 문서 인용은 공공저작물 자유이용 범위 내에서 이루어졌습니다.
- 코드: **MIT License**
- 벤치마크 데이터셋: **CC BY 4.0**

---

## 인용 | Citation

게재 확정 후 업데이트될 예정입니다.

```bibtex
@misc{anonymous2026korean,
  title  = {생명보험 언더라이팅 AI 평가를 위한 한국어 NL-to-SQL 벤치마크 설계 및 검증},
  author = {Anonymous},
  year   = {2026},
  note   = {Under review}
}
```

---

## 문의 | Contact

논문 심사 기간 중 저자 정보는 비공개입니다. 게재 확정 후 업데이트될 예정입니다.
