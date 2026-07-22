# Insurance Underwriting NL-to-SQL Benchmark

생명보험 언더라이팅 AI 평가를 위한 한국어 NL-to-SQL 벤치마크 질문셋 및 실험 코드.
Text-to-SQL과 Semantic Layer 두 접근법의 정확도·보안성을 비교합니다.

## 논문

양문일, "생명보험 언더라이팅 AI 평가를 위한 한국어 NL-to-SQL 벤치마크 설계 및 검증: Text-to-SQL과 Semantic Layer의 보안성-효율성 비교," 한국콘텐츠학회논문지.

## 개요

- **질문셋**: 80개 (UW001~UW080), 8개 카테고리
- **출처**: 생명보험 표준약관 [별표15], 보험업감독규정(제2024-54호)
- **DB**: SQLite, 26개 테이블, 샘플 200계약
- **비교 조건**: Text-to-SQL(DDL 직접 노출) vs Semantic Layer(비즈니스 개념 추상화)
- **모델**: GPT-4o-mini (temperature=0, 조건당 3회 반복, 총 480 API 호출)

## 주요 결과

| 지표 | Text-to-SQL | Semantic Layer | 차이 |
|---|---|---|---|
| 전체 실행 정확도(EX) | 23.8% | 29.2% | +5.4%p (n.s., p=0.214) |
| 민감 컬럼 노출(개념 정의 수준) | 23개 | 0개 | −100% |
| 민감 컬럼 노출(프롬프트 전체) | 23개 | 15개 | −34.8% |
| 고민감도(high) 질문군 EX | 29.0% | 59.4% | +30.4%p (p=0.0006) |

- RQ1: SL이 T2S 대비 EX가 소폭 높으나 통계적으로 유의하지 않음 → 정확도 손해 없이 보안 강화 가능
- RQ2: 개념 정의 수준 민감 컬럼 노출 100% 제거, 프롬프트 전체 기준 34.8% 감소
- RQ3: 민감정보 수준이 high인 질문군에서만 SL이 유의하게 우세(χ²=11.752, p=0.0006) → 고민감도 영역에서 보안성-효율성 상보적 관계 시사

## 구조

```
├── benchmark/         # 질문셋 JSON (80개, UW001~UW080)
├── schema/            # SQLite 스키마 DDL (26개 테이블)
├── data/              # 샘플 데이터 (200계약)
├── notebooks/         # 실험 주피터노트북
├── semantic_layer/    # Semantic Layer 정의 (metric/dimension/measure)
├── prompts/           # 실험 프롬프트 (Text-to-SQL / Semantic Layer 조건)
└── results/           # 실험 결과 (EX, 민감정보 노출, 응답시간)
```

## 질문셋 구성

| 카테고리 | 질문 수 | 비율 |
|---|---|---|
| 보험금지급 | 14 | 17.5% |
| 계약관리 | 13 | 16.3% |
| 계약심사 | 13 | 16.3% |
| 장해리스크 | 13 | 16.3% |
| 보험료산출 | 10 | 12.5% |
| 사기탐지 | 7 | 8.8% |
| 고지의무 | 6 | 7.5% |
| 재무리스크 | 4 | 5.0% |

난이도: simple 14개(17.5%) / moderate 46개(57.5%) / challenging 20개(25.0%)
민감정보 수준: high 23개(28.8%) / medium 37개(46.2%) / low 20개(25.0%)

## 환경 설정

```bash
conda create -n uw-benchmark python=3.11
conda activate uw-benchmark
python setup_project.py
```

## 평가 지표

- **실행 정확도(EX)**: BIRD 방법론 준거, gold_sql과 생성 SQL의 실행 결과 집합 동등성 기준 이진 채점
- **민감정보 노출**: 스키마 수준(프롬프트 내 민감 컬럼 수) + 쿼리 수준(생성 SQL 내 민감 토큰 수/쿼리)으로 이원 측정
- **통계 검정**: 카이제곱 검정, 맥니마 검정, Cohen's d, 95% CI(1,000회 부트스트랩)

## 한계

단일 모델(GPT-4o-mini) 의존, 샘플 DB(200계약) 기반 실험으로 실제 운영 규모 미반영, Semantic Layer 매핑은 수동 정의. 자세한 내용은 논문 5절 참조.

## 출처

- 생명보험 표준약관 [별표15]
- 보험업감독규정 (금융위원회고시 제2024-54호)

## 인용

```bibtex
@article{yang2026korean,
  title={생명보험 언더라이팅 AI 평가를 위한 한국어 NL-to-SQL 벤치마크 설계 및 검증: Text-to-SQL과 Semantic Layer의 보안성-효율성 비교},
  author={양문일},
  journal={한국콘텐츠학회논문지},
  year={2026}
}
