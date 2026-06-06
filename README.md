# Korean Insurance Underwriting NL-to-SQL Benchmark

> 생명보험 언더라이팅 AI 평가를 위한 한국어 NL-to-SQL 벤치마크  
> A Korean-language NL-to-SQL benchmark for life insurance underwriting AI evaluation

---

## 개요 | Overview

본 리포지토리는 생명보험 언더라이팅 도메인 특화 한국어 NL-to-SQL 벤치마크(80문항)와 실험 코드를 포함합니다.  
국내 보험 규제 문서를 출처로 하며, Text-to-SQL과 Semantic Layer 두 접근법의 정확도·보안성을 비교합니다.

This repository contains a Korean-language NL-to-SQL benchmark (80 questions) for life insurance underwriting, along with experimental code comparing Text-to-SQL and Semantic Layer approaches in terms of execution accuracy and sensitive information exposure.

> 📄 본 코드는 현재 심사 중인 논문의 재현 실험을 위해 공개되었습니다.  
> This code accompanies a paper currently under review.

---

## 데이터 출처 | Data Sources

| 문서 | 질문 수 |
|------|---------|
| 생명보험 표준약관 \[별표15\] | 45개 |
| 보험업감독규정 (금융위원회고시 제2024-54호) | 35개 |
| **합계** | **80개** |

---

## 벤치마크 구성 | Benchmark Structure

### 카테고리별 분포

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

### 난이도 및 민감정보 수준

| 구분 | 분류 | 질문 수 |
|------|------|---------|
| 난이도 | simple | 14 |
| | moderate | 46 |
| | challenging | 20 |
| 민감정보 수준 | high | 23 |
| | medium | 37 |
| | low | 20 |

---

## 폴더 구조 | Repository Structure

```
korean-insurance-nl2sql-benchmark/
├── benchmark/
│   └── metadata.json          # 질문셋 메타데이터 (80문항)
├── schema/
│   └── schema.sql             # SQLite DDL (26개 테이블)
├── data/
│   └── sample_data.sql        # 샘플 데이터 (200계약)
├── semantic_layer/
│   ├── schema_context.yaml    # Semantic Layer 개념 정의
│   └── sql_mapping.yaml       # 비즈니스 개념 → 컬럼 매핑
├── prompts/
│   ├── prompt_text2sql.txt    # Text-to-SQL 프롬프트
│   └── prompt_semantic_layer.txt  # Semantic Layer 프롬프트
├── notebooks/
│   ├── 00_setup.ipynb
│   ├── 01_gold_sql_validation.ipynb
│   ├── 02_experiment_text2sql.ipynb
│   ├── 03_experiment_semantic_layer.ipynb
│   ├── 04_results_analysis.ipynb
│   ├── 05_sensitivity_analysis.ipynb
│   └── 06_paper_figures.ipynb
├── results/
│   ├── raw/                   # 실험 원시 결과 (CSV)
│   └── figures/               # 논문 수록 그림
├── setup_project.py
├── requirements.txt
└── README.md
```

---

## 실험 설계 | Experimental Design

- **모델**: GPT-4o-mini (temperature=0)
- **비교 조건**: Text-to-SQL (DDL 직접 노출) vs. Semantic Layer (비즈니스 개념 기반)
- **반복 횟수**: 조건당 3회 (총 API 호출 480회)
- **평가 지표**: 실행 정확도(EX), 민감정보 노출 수, 응답시간
- **통계 검정**: 카이제곱 검정, McNemar 검정, Cohen's d, 부트스트랩 신뢰구간(n=1,000)

---

## 주요 결과 | Key Results

| 지표 | Text-to-SQL | Semantic Layer | 차이 |
|------|-------------|----------------|------|
| 전체 EX | 23.8% | 29.2% | +5.4%p (n.s.) |
| 민감 컬럼 노출 (개념 정의 수준) | 23개 | 0개 | −100% |
| High 민감도 EX | 29.0% | 59.4% | +30.4%p ✅ |

> ✅ p=0.0006 (χ²=11.752), 통계적으로 유의

---

## 환경 설정 | Setup

```bash
# 1. 가상환경 생성 및 활성화
conda create -n uw-benchmark python=3.11
conda activate uw-benchmark

# 2. 프로젝트 구조 생성 및 패키지 설치
python setup_project.py

# 3. API 키 설정 (.env 파일)
OPENAI_API_KEY=your_key_here

# 4. Jupyter 실행
jupyter notebook
```

### 주요 의존성

```
openai>=1.0.0
pandas>=2.0.0
scipy>=1.10.0
pyyaml>=6.0
seaborn>=0.12.0
```

전체 목록: `requirements.txt` 참조

---

## 노트북 실행 순서 | Notebook Execution Order

| 순서 | 파일 | 내용 |
|------|------|------|
| 1 | `00_setup.ipynb` | DB 초기화, 환경 검증 |
| 2 | `01_gold_sql_validation.ipynb` | Gold SQL 전수 실행 검증 (80/80) |
| 3 | `02_experiment_text2sql.ipynb` | Text-to-SQL 실험 (3회 반복) |
| 4 | `03_experiment_semantic_layer.ipynb` | Semantic Layer 실험 (3회 반복) |
| 5 | `04_results_analysis.ipynb` | EX 비교, 통계 검정 |
| 6 | `05_sensitivity_analysis.ipynb` | 민감정보 수준별 교차 분석 |
| 7 | `06_paper_figures.ipynb` | 논문 수록 그림 생성 |

---

## 윤리 및 라이선스 | Ethics & License

- 본 벤치마크에 사용된 샘플 데이터는 **완전 가상 데이터**이며 실제 계약자 정보를 포함하지 않습니다.
- 규제 문서 인용은 공공저작물 자유이용 범위 내에서 이루어졌습니다.
- 코드 라이선스: **MIT License**
- 벤치마크 데이터셋 라이선스: **CC BY 4.0**

---

## 인용 | Citation

본 리포지토리를 연구에 활용하실 경우 아래와 같이 인용해 주세요.  
논문 정보는 게재 확정 후 업데이트될 예정입니다.

```bibtex
@misc{anonymous2026korean,
  title     = {생명보험 언더라이팅 AI 평가를 위한 한국어 NL-to-SQL 벤치마크 설계 및 검증},
  author    = {Anonymous},
  year      = {2026},
  note      = {Under review},
  url       = {https://github.com/anonymous/korean-insurance-nl2sql-benchmark}
}
```

---

## 문의 | Contact

논문 심사 기간 중 저자 정보는 비공개입니다.  
게재 확정 후 연락처가 업데이트될 예정입니다.
