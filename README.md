# Insurance Underwriting NL-to-SQL Benchmark

생명보험 언더라이팅 AI 평가를 위한 한국어 NL-to-SQL 벤치마크 질문셋

## 구조
- `benchmark/` : 질문셋 JSON (80개)
- `schema/`    : SQLite 스키마 DDL
- `data/`      : 샘플 데이터
- `notebooks/` : 실험 주피터노트북
- `semantic_layer/` : Semantic Layer 정의
- `prompts/`   : 실험 프롬프트
- `results/`   : 실험 결과

## 환경 설정
```bash
conda create -n uw-benchmark python=3.11
conda activate uw-benchmark
python setup_project.py
```

## 출처
- 생명보험 표준약관 [별표15]
- 보험업감독규정 (금융위원회고시 제2024-54호)
