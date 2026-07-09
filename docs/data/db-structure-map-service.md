# 일자리 맵 서비스 — DB 구성 분석 및 개발 가이드

> **작성 기준**: 25NIA-DE5059-01_물리 데이터 요소 정의서_(잡아바)_v1.0.xlsx  
> **참조 코드**: MOEF_NKOD_DB_05_코드 정의서_v1.2 [배포용].pdf  
> **최초 작성**: 2026-06-12 / **최종 수정**: 2026-06-27  
> **구현 상태**: 방안 A 완료 · 방안 B 완료 (`v_job_posting` 배치/동기화 테이블 방식)  
> **목적**: 지도 기반 채용공고 검색 서비스(일자리 맵) 백엔드 개발자 인수인계용

---

## 목차

1. [채널별 채용공고 테이블 현황](#1-채널별-채용공고-테이블-현황)
2. [지도 서비스 핵심 컬럼 구조](#2-지도-서비스-핵심-컬럼-구조)
3. [공통코드 정의 (R코드)](#3-공통코드-정의-r코드)
4. [공통코드 테이블 활용 방안](#4-공통코드-테이블-활용-방안)
5. [`v_job_posting` 배치/동기화 테이블 아키텍처](#5-v_job_posting-배치동기화-테이블-아키텍처)
6. [구현 전략 (방안 A → B)](#6-구현-전략-방안-a--b)
7. [좌표 캐시 테이블](#7-좌표-캐시-테이블)
8. [필터 모달 ↔ DB 컬럼 매핑](#8-필터-모달--db-컬럼-매핑)
9. [운영 전환 가이드](#9-운영-전환-가이드)
10. [공공데이터포털 API 검토 결과](#10-공공데이터포털-api-검토-결과)
11. [참고 파일](#11-참고-파일)

---

## 1. 채널별 채용공고 테이블 현황

> 조회 기준: `jlnkm.tb_app_sys_comm_code` (GRP_CD = 'TABLE_ID')  
> 마감일 기준 마감/진행중 구분 — USE_YN='N' 또는 DEL_YN='Y' 공고는 마감 처리

| CMN_CD | 채널명 | 테이블 (스키마.테이블명) | 전체 | 마감 | 진행중 |
|--------|--------|------------------------|-----:|-----:|------:|
| 1 | IBK 기업은행(i-ONE JOB) | `jwrki.tb_empmn_ionejob_api` | 14,189 | 8,601 | 5,588 |
| 2 | 잡코리아 | `jwrki.tb_empmn_jobkorea_api` | 347,281 | 346,786 | 495 |
| 3 | 신성장사업·참 괜찮은 중소기업·LG전자 | `jwrki.tb_empmn_jobkorea_etc_api` | 433,194 | 427,784 | 5,410 |
| 4 | 건설공제회 채용관 | `jwrki.tb_empmn_cwma_api` | 1,575 | 1,575 | 0 |
| 5 | 잡아바 채용정보 | `jmmbi.tb_ent_untact_empmn` | 14,638 | 14,465 | 173 |
| 6 | 워크넷 | `jwrki.tb_empmn_worknet_api` | 1,392,928 | 1,338,901 | 54,027 |
| 7 | KB굿잡 | `jwrki.tb_empmn_kb_goobjob_api` | 7,519 | 4,279 | 3,240 |
| 8 | 공공일자리 채용정보 | `jwrki.tb_public_job` | 73,799 | 72,767 | 1,032 |
| 9 | 잡코리아_기간재채용관 | `jedut.tb_recruit_jobkorea_api` | 11,186 | 11,085 | 101 |
| 15 | WORLDJOB_해외취업채용관 | `jedut.tb_recruit_world_api` | 32,505 | 32,057 | 448 |
| | **합계** | | **2,328,814** | **2,258,300** | **70,514** |

---

## 2. 지도 서비스 핵심 컬럼 구조

### 2-1. `jwrki.tb_empmn_worknet_api` — 워크넷 (46컬럼)

| 컬럼명 | 타입 | KEY | 설명 | 지도 서비스 용도 |
|--------|------|-----|------|----------------|
| WANTED_AUTH_NO | varchar | PK | 채용공고 고유번호 | 공고 ID |
| COMPANY | varchar | | 기업명 | 목록/상세 |
| TITLE | longtext | | 공고 제목 | 목록/상세 |
| JOBS_NM | text | | 직종명 | 상세 |
| CAREER | varchar | | 경력 텍스트 | 상세 |
| CAREER_CD | varchar | | 경력 원천코드 | 원천 필터 |
| EMP_TP_NM | varchar | | 고용형태 텍스트 | 상세 |
| EMP_TP_CD | varchar | | 고용형태 원천코드 | 원천 필터 |
| SAL_TP_NM | varchar | | 급여 유형명 | 상세 |
| SAL_AMT | varchar | | 급여액 | 상세 |
| REGION | text | | 근무지역 텍스트 | 상세 |
| REGION_CD | varchar | | 근무지역 코드 | 원천 필터 |
| MIN_EDUBG | varchar | | 최소학력 텍스트 | 상세 |
| MIN_EDUBG_CD | varchar | | 최소학력 원천코드 | 원천 필터 |
| CLOSE_DT | varchar | | 마감일 | 마감일/D-day |
| WANTED_REG_DT | varchar | | 공고 등록일 | 목록 정렬 |
| WANTED_INFO_URL | text | | 채용공고 URL | 상세 링크 |
| **BASIC_ADDR** | text | | **기본주소** | **지오코딩** |
| **DETAIL_ADDR** | text | | **상세주소** | **지오코딩** |
| BIZ_NO | varchar | MUL | 사업자번호 | 기업 JOIN |
| **JOB_CAREER_CD** | varchar | | **통합 경력코드 (R2000)** | **통합 필터** |
| **JOBS_CD** | varchar | | **직종코드 (NCS R6000)** | **통합 필터** |
| **JOB_AREA_CD** | varchar | | **통합 지역코드 (R3000)** | **통합 필터** |
| **JOB_ACDMCR_CD** | varchar | | **통합 학력코드 (R7000)** | **통합 필터** |
| **JOB_EMP_TP_CD** | varchar | | **통합 고용형태코드 (R1000)** | **통합 필터** |
| USE_YN | char | | 사용여부 | 조회 조건 |
| DEL_YN | char | MUL | 삭제여부 | 조회 조건 |

### 2-2. `jwrki.tb_empmn_jobkorea_api` (로컬: `tb_empmn_jobkorea_api`) — 잡코리아 (50컬럼)

> ⚠️ **로컬 개발 환경 주의**: 운영 DB에서 추출한 CSV를 로컬 `jobaba_map` 스키마에 적재  
> `jwrki.tb_empmn_jobkorea_api` (운영) ↔ `tb_empmn_jobkorea_api` (로컬) — 스키마명 차이만 존재

| 컬럼명 | 타입 | KEY | 설명 | 지도 서비스 용도 |
|--------|------|-----|------|----------------|
| GI_NO | varchar | PK | 공고 고유번호 | 공고 ID (`v_job_posting`에서 `CONCAT('JK-',GI_NO)` 로 사용) |
| COM_NAME | varchar | | 기업명 | 목록/상세 |
| GI_SUBJECT | varchar | | 공고 제목 | 목록/상세 |
| PART_NO_INFO | varchar | | 직무명 | 상세 |
| GI_PART_NO_CD | varchar | | 직무코드 | JOBS_CD 대응 |
| CAREER_INFO | varchar | | 경력명 텍스트 | 상세 |
| GI_CAREER_CD | varchar | | 경력 원천코드 | jedut.tb_code 매핑 후 R2000 변환 예정 |
| PASS_TYPE_INFO | varchar | | 고용형태명 텍스트 | 상세 |
| GI_PASS_TYPE_CD | varchar | | 고용형태 원천코드 | jedut.tb_code 매핑 후 R1000 변환 예정 |
| EDU_CUTLINE_INFO | varchar | | 학력명 텍스트 | 상세 |
| GI_EDU_CUTLINE_CD | varchar | | 학력 원천코드 | jedut.tb_code 매핑 후 R7000 변환 예정 |
| PAY_INFO | varchar | | 급여 텍스트 | SAL_AMT 대응 |
| AREA_INFO | varchar | | 지역명 텍스트 | REGION 대응 |
| AREA_CD | varchar | | 지역 원천코드 | |
| GI_END_DATE | varchar | | 마감일 (`YYYYMMDD` 형식) | CLOSE_DT 대응 (동기화 SQL에서 `YYYY-MM-DD` 변환) |
| JK_URL | varchar | | 채용공고 URL | WANTED_INFO_URL 대응 |
| BIZ_NO | varchar | MUL | 사업자번호 | 기업 JOIN |
| **JOB_CAREER_CD** | varchar | | **경력코드 (현재 원천코드, R코드 아님)** | jedut.tb_code 확보 후 R2000 교체 |
| **JOB_AREA_CD** | varchar | | **지역코드 (현재 원천코드)** | jedut.tb_code 확보 후 R3000 교체 |
| **JOB_EMP_TP_CD** | varchar | | **고용형태코드 (현재 원천코드)** | jedut.tb_code 확보 후 R1000 교체 |
| **JOB_ACDMCR_CD** | varchar | | **학력코드 (현재 원천코드)** | jedut.tb_code 확보 후 R7000 교체 |
| USE_YN | char | | 사용여부 | 조회 조건 |
| DEL_YN | char | MUL | 삭제여부 | 조회 조건 |

> ⚠️ **JOB_ 컬럼 = 원천코드** — 현재 R코드가 아니므로 필터 적용 시 잡코리아 공고 미노출 (정상 동작)  
> ⚠️ **주소 컬럼 없음** — 좌표는 JOB_AREA_CD 기준 대표 좌표 사용  
> ✅ **jedut.tb_code 데이터 확보 후 표준 조회 객체 동기화 SQL 업데이트로 필터 지원 추가 가능**

### 2-3. `jwrki.tb_empmn_jobkorea_etc_api` — 잡코리아 ETC (42컬럼)

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| GI_NO | varchar PK | 공고 고유번호 |
| COMPANY_TYPE | varchar PK | 기업 유형 (복합PK) |
| COMPANY_NAME | varchar | 기업명 |
| GI_SUBJECT | varchar | 공고 제목 |
| GI_CAREER_CD | varchar | 경력 원천코드 |
| GI_EDU_CUTLINE_CD | varchar | 학력 원천코드 |
| GI_JOB_TYPE_CD | varchar | 고용형태 원천코드 |
| AREA_CD | varchar | 지역 원천코드 |
| AREA_NM | varchar | 지역 텍스트 |
| GI_END_DATE | varchar | 마감일 |
| JK_URL | varchar | 채용공고 URL |

> ⚠️ **통합 JOB_ 컬럼 없음** — `jedut.tb_code` 코드 매핑 확인 후 동기화 SQL에 CASE WHEN 추가 필요

### 2-4. `jwrki.tb_empmn_cwma_api` — 건설공제회 (37컬럼)

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| GI_NO | varchar PK | 공고 ID |
| COMPANY_TYPE | varchar PK | 기업유형 (복합PK) |
| COMPANY_NAME | varchar | 기업명 |
| GI_SUBJECT | varchar | 공고 제목 |
| GI_CAREER_CD / GI_CAREER_NM | varchar | 경력 코드/명 |
| GI_EDU_CUTLINE_CD / NM | varchar | 학력 코드/명 |
| GI_JOB_TYPE_CD / NM | varchar | 고용형태 코드/명 |
| AREA_NM / AREA_DETAIL_NM | varchar | 지역명 (텍스트) |
| GI_END_DATE | varchar | 마감일 |
| JK_URL | varchar | 채용공고 URL |

> ⚠️ **통합 JOB_ 컬럼 없음**, 주소는 AREA_NM 텍스트만 존재

### 2-5. `jmmbi.tb_ent_untact_empmn` — 잡아바 채용정보 (80컬럼)

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| SEQ | bigint PK | 공고 ID |
| BIZRNO | varchar | 사업자번호 |
| TITLE | longtext | 공고 제목 |
| CAREER_CD | varchar | 경력코드 *(통합코드 아닌 자체코드)* |
| ACDMCR_CD | varchar | 학력코드 *(자체코드)* |
| EMP_TP_CD | varchar | 고용형태코드 *(자체코드)* |
| JOB_AREA_CD | varchar | 지역코드 |
| RQT_END_DE | varchar | 모집 마감일 |
| PAY_MIN_PRICE / PAY_MAX_PRICE | bigint | 급여 최소/최대 |
| USE_YN / DEL_YN | char | 사용/삭제 여부 |

> ⚠️ 컬럼명이 다름(CAREER_CD ≠ JOB_CAREER_CD) — 표준 조회 객체 동기화 SQL에서 ALIAS 처리 필요  
> ⚠️ 주소 없음 — BIZRNO로 기업 테이블 JOIN 필요

### 2-6. `jwrki.tb_empmn_kb_goobjob_api` — KB굿잡 (26컬럼)

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| GI_NO | varchar PK | 공고 ID |
| COMPANY_NAME | varchar | 기업명 |
| GI_SUBJECT | varchar | 공고 제목 |
| GI_CAREER_NM | varchar | 경력명 (코드값 없음) |
| GI_EDU_CUTLINE_NM | varchar | 학력명 (코드값 없음) |
| GI_JOB_TYPE_NM | varchar | 고용형태명 (코드값 없음) |
| AREA_NM | varchar | 지역명 (텍스트) |
| HIRE_RCV_END_YMD | varchar | 마감일 |
| JK_URL / JK_URL_MOBILE | varchar | 채용공고 URL |

> ⚠️ **코드값 없고 텍스트(NM) 컬럼만 존재** — `jedut.tb_code`에 텍스트→코드 역매핑 등록 필요

### 2-7. `jwrki.tb_empmn_ionejob_api` — IBK 아이원잡 (24컬럼)

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| HIRE_SN | varchar PK | 공고 ID |
| CMP_NM | varchar | 기업명 |
| HIRE_TITLE | varchar | 공고 제목 |
| JOB_CAREERINFO | varchar | 경력 텍스트 |
| JOB_EDU | varchar | 학력 텍스트 |
| JOB_TYPECOND | varchar | 고용형태 텍스트 |
| JOB_LOCATION | varchar | 근무지 텍스트 |
| HIRE_RCV_END_YMD | varchar | 마감일 |
| JOB_URL / JOB_MOBILE_URL | varchar | URL |

> ⚠️ **코드값 컬럼 없음** — 텍스트 LIKE 검색만 가능, 정확도 낮음

### 2-8. `jwrki.tb_public_job` — 공공일자리 (26컬럼)

> **[2026-06-12 확인]** 공공데이터포털 원천 API 파라미터 분석 결과 R코드 동일 체계 확인

| 컬럼명 | 타입 | 설명 | 공통코드 그룹 |
|--------|------|------|-------------|
| SEQ | bigint PK | 공고 ID | — |
| INST_NM | varchar | 기관명 | — |
| TITLE | text | 공고 제목 | — |
| BGN_DT / END_DT | datetime | 시작/마감일 | — |
| DTL_URL | text | 채용공고 URL | — |
| **WORK_RGN_CDS** | varchar | 근무지역 코드 | **R3000** |
| **EMP_FR_CDS** | varchar | 고용형태 코드 | **R1000** |
| **RCRUT_SE_CDS** | varchar | 채용구분 코드 | **R2000** |
| **ACBG_COND_CDS** | varchar | 학력 코드 | **R7000** |
| USE_YN / DEL_YN | varchar | 사용/삭제 여부 | — |

> ✅ **R코드 직접 사용 확인** — UNION 시 컬럼명 ALIAS만으로 즉시 필터 지원 가능

### 2-9. `jedut.tb_recruit_jobkorea_api` — 잡코리아 기간재채용관 (22컬럼)

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| GI_NO | varchar PK | 공고 ID |
| C_NAME | varchar | 기업명 |
| GI_SUBJECT | varchar | 공고 제목 |
| GI_EDU_CUTLINE | varchar | 학력 텍스트 |
| GI_JOB_TYPE | varchar | 고용형태 텍스트 |
| AREACODE | varchar | 지역코드 |
| GI_END_DATE | varchar | 마감일 |
| JK_URL | varchar | URL |

> ⚠️ 코드값 없음, 텍스트 컬럼만 존재

### 2-10. `jedut.tb_recruit_world_api` — 해외취업 (16컬럼)

> ⚠️ 해외취업 전용 — 국내 지도 서비스 범위 밖, **별도 뷰로 분리 권장**

---

## 3. 공통코드 정의 (R코드)

> 출처: MOEF_NKOD_DB_05_코드 정의서_v1.2  
> **저장 테이블**: `jedut.tb_code` (구조 확인 예정 — 이하 코드값은 정의서 기준)  
> ※ 기존 가정(`jlnkm.tb_app_sys_comm_code`)은 실서버 확인 결과 `jedut.tb_code`로 수정됨

### R1000 — 고용형태

| CMN_CD | 코드명 |
|--------|--------|
| R1010 | 정규직 |
| R1020 | 계약직 |
| R1030 | 무기계약직 |
| R1040 | 비정규직 |
| R1050 | 청년인턴 |
| R1060 | 청년인턴(체험형) |
| R1070 | 청년인턴(채용형) |

### R2000 — 채용구분(경력)

| CMN_CD | 코드명 |
|--------|--------|
| R2010 | 신입 |
| R2020 | 경력 |
| R2030 | 신입+경력 |
| R2040 | 외국인전형 |

### R3000 — 근무지(시도)

| CMN_CD | 코드명 | CMN_CD | 코드명 |
|--------|--------|--------|--------|
| R3010 | 서울 | R3019 | 충남 |
| R3011 | 인천 | R3020 | 충북 |
| R3012 | 대전 | R3021 | 경북 |
| R3013 | 대구 | R3022 | 경남 |
| R3014 | 부산 | R3023 | 전남 |
| R3015 | 광주 | R3024 | 전북 |
| R3016 | 울산 | R3025 | 제주 |
| R3017 | 경기 | R3026 | 세종 |
| R3018 | 강원 | R3030 | 해외 |

### R6000 — NCS분류(직종)

| CMN_CD | 코드명 | CMN_CD | 코드명 |
|--------|--------|--------|--------|
| R600001 | 사업관리 | R600014 | 건설 |
| R600002 | 경영·회계·사무 | R600015 | 기계 |
| R600003 | 금융·보험 | R600016 | 재료 |
| R600004 | 교육·자연·사회과학 | R600017 | 화학 |
| R600005 | 법률·경찰·소방·교도·국방 | R600018 | 섬유·의복 |
| R600006 | 보건·의료 | R600019 | 전기·전자 |
| R600007 | 사회복지·종교 | R600020 | 정보통신 |
| R600008 | 문화·예술·디자인·방송 | R600021 | 식품가공 |
| R600009 | 운전·운송 | R600022 | 인쇄·목재·가구·공예 |
| R600010 | 영업판매 | R600023 | 환경·에너지·안전 |
| R600011 | 경비·청소 | R600024 | 농림어업 |
| R600012 | 이용·숙박·여행·오락·스포츠 | R600025 | 연구 |
| R600013 | 음식서비스 | | |

### R7000 — 학력정보

| CMN_CD | 코드명 |
|--------|--------|
| R7010 | 학력무관 |
| R7020 | 중졸이하 |
| R7030 | 고졸 |
| R7040 | 대졸(2~3년) |
| R7050 | 대졸(4년) |
| R7060 | 석사 |
| R7070 | 박사 |

---

## 4. 공통코드 테이블 활용 방안

### 공통코드 테이블 (`jedut.tb_code`)

> ⚠️ 테이블 구조 미확인 — 실서버 조회 후 아래 항목 채워 넣어야 함

```sql
-- jedut.tb_code 컬럼 구조 확인 (실서버에서 실행)
SHOW COLUMNS FROM jedut.tb_code;

-- 코드 그룹 목록 확인
SELECT DISTINCT 그룹코드컬럼, COUNT(*) AS cnt
FROM jedut.tb_code
GROUP BY 그룹코드컬럼
ORDER BY 그룹코드컬럼;
```

### 코드 매핑 데이터가 필요한 이유

방안 B에서 잡코리아(`tb_empmn_jobkorea_api`)의 `JOB_CAREER_CD` 등 컬럼은 현재 원천코드 상태입니다.  
`jedut.tb_code`에서 원천코드 → R코드 매핑 데이터를 확인하면 `v_job_posting` 표준 조회 객체의 동기화 SQL을 업데이트하여 필터 지원이 가능합니다.

### 동기화 SQL 업데이트 패턴 (jedut.tb_code 확보 후)

```sql
-- jedut.tb_code 구조 확인 후 아래 CASE WHEN 패턴으로 동기화 SQL 수정
-- tb_empmn_jobkorea_api 의 JOB_CAREER_CD 원천코드를 R코드로 변환 예시
CASE t.JOB_CAREER_CD
    WHEN '원천신입코드' THEN 'R2010'
    WHEN '원천경력코드' THEN 'R2020'
    WHEN '원천신입경력코드' THEN 'R2030'
    ELSE NULL
END AS JOB_CAREER_CD

-- 또는 jedut.tb_code JOIN 방식
LEFT JOIN jedut.tb_code tc
    ON tc.원천코드컬럼 = t.JOB_CAREER_CD
    AND tc.그룹코드 = 'R2000'
```

---

## 5. `v_job_posting` 배치/동기화 테이블 아키텍처

> 핵심 설계 원칙: **앱 코드(MapMapper.xml)는 항상 최종 `v_job_posting`만 참조**  
> 환경 전환(로컬→운영) = 동기화 SQL 교체만으로 완료, 앱 코드 변경 불필요

### 환경별 동기화 테이블 구성

```
로컬 개발 (jobaba_map 스키마)     운영 서버 (실제 DB 스키마)
──────────────────────────────    ─────────────────────────────────────
v_job_posting                     v_job_posting  ← 조회 대상 이름 동일
  ├─ tb_empmn_worknet_api    →       ├─ jwrki.tb_empmn_worknet_api
  └─ tb_empmn_jobkorea_api   →       ├─ jwrki.tb_empmn_jobkorea_etc_api
  (공공기관 465건 + 잡코리아 433건)   ├─ jwrki.tb_empmn_cwma_api
                                     ├─ jwrki.tb_empmn_kb_goobjob_api
                                     ├─ jwrki.tb_empmn_ionejob_api
                                     ├─ jedut.tb_recruit_jobkorea_api
                                     └─ jmmbi.tb_ent_untact_empmn

원천 데이터 갱신 배치(일 1회)
  → v_job_posting_staging 생성
  → 인덱스 생성
  → RENAME TABLE로 v_job_posting 교체
```

### 표준 컬럼 정의

`v_job_posting`은 모든 채널 테이블을 동일한 컬럼명으로 맞춘 최종 조회용 `BASE TABLE`입니다.

| 컬럼명 | 타입 | 설명 | 비고 |
|--------|------|------|------|
| WANTED_AUTH_NO | varchar | 공고 식별자 | worknet: `PUB-xxx` / jobkorea: `JK-xxx` / 운영 시 채널별 접두사 부여 |
| SOURCE | varchar | 채널명 | 공공기관, 잡코리아, 워크넷, … |
| SOURCE_TYPE | varchar | 채널 구분 | `공공` / `민간` |
| COMPANY | varchar | 기업명 | |
| TITLE | varchar | 공고 제목 | |
| JOBS_NM | varchar | 직무명 | |
| JOBS_CD | varchar | 직종코드 (R6000) | |
| EMP_TP_NM | varchar | 고용형태 텍스트 | |
| CAREER | varchar | 경력 텍스트 | |
| MIN_EDUBG | varchar | 학력 텍스트 | |
| SAL_AMT | varchar | 급여 | |
| SAL_TP_NM | varchar | 급여유형 | |
| REGION | varchar | 지역 텍스트 | |
| CLOSE_DT | varchar | 마감일 (`YYYY-MM-DD`) | 원천 포맷이 `YYYYMMDD`인 경우 동기화 SQL에서 변환 |
| WANTED_INFO_URL | varchar | 지원 URL | |
| BASIC_ADDR | varchar | 기본주소 | 없는 테이블은 NULL |
| DETAIL_ADDR | varchar | 상세주소 | 없는 테이블은 NULL |
| INFO_SVC | varchar | 서비스 구분 | |
| JOB_CAREER_CD | varchar | 통합 경력코드 (R2000) | jedut.tb_code 확보 전: 원천코드 상태 |
| JOB_ACDMCR_CD | varchar | 통합 학력코드 (R7000) | 위와 동일 |
| JOB_EMP_TP_CD | varchar | 통합 고용형태코드 (R1000) | 위와 동일 |
| JOB_AREA_CD | varchar | 통합 지역코드 (R3000) | 위와 동일 |
| REG_DT | datetime | 등록일시 (ORDER BY 용) | |
| USE_YN | char | 사용여부 | 동기화 SQL에서 필터링 완료 |
| DEL_YN | char | 삭제여부 | 동기화 SQL에서 필터링 완료 |

### 공공/민간 분류 기준

신규 API를 `v_job_posting`에 연결할 때 앱 코드는 `PUB`/`PRV`를 직접 판단하지 않습니다. 모든 원천 API는 동기화 SQL에서 `SOURCE_TYPE`을 반드시 `공공` 또는 `민간`으로 표준화하고, 지도 조회 API는 기존처럼 `sourceType=PUB|PRV`만 받습니다.

고용24는 공식 OpenAPI의 `coTp=04`(기업형태: 공공기관) 응답만 공공기관 기준으로 사용합니다. 고용24 화면에는 외부 API에 포함되지 않는 자체 공고가 더 많이 노출될 수 있으므로, 화면 공고 수와 API 기반 분류 결과는 다를 수 있습니다.

분류 우선순위는 다음 순서로 적용합니다.

| 우선순위 | 기준 | `SOURCE_TYPE` | 적용 예 |
|---:|---|---|---|
| 1 | 고용24 `WANTED_AUTH_NO + INFO_SVC`가 `tb_work24_public_job.WANTED_AUTH_NO + INFO_TYPE_CD`와 매칭되고 `INFO_TYPE_GROUP='tb_workinfoworknet'`, `INST_TYPE='P'` | 복합 식별자 기준 | 매칭=공공 |
| 2 | 고용24 복합 식별자 미매칭 | 복합 식별자 기준 | 민간 |
| 3 | 원천 테이블 자체가 특정 채널 성격으로 고정됨 | 채널 기준 | `tb_public_job` = 공공, `tb_empmn_jobkorea_api` = 민간 |
| 4 | 원천 API가 공공/민간 구분 코드를 제공하고 코드 정의가 확인됨 | 코드값 기준 | 신규 API별 정의 확인 후 적용 |
| 5 | API 제공기관/업무 정의서에서 공공 또는 민간 전용 채널임이 명시됨 | 문서 기준 | 공공기관 채용공시 API = 공공 |

신규 API 연결 시 금지 기준:

- 코드 정의가 확인되지 않은 값을 임의로 `공공` 또는 `민간`으로 추정하지 않습니다.
- 고용24는 명시 정책에 따라 `tb_work24_public_job` 복합 식별자 매칭이 아니면 `민간`으로 분류합니다.
- 고용24 공공/민간 분류에는 `tb_app_hire_info.CO_PM`, 기관명 정규화, 부분검색, 사업자번호 매칭, 사업자번호 유형코드 `83`을 사용하지 않습니다.
- 그 외 신규 API에서는 `ELSE '민간'` 같은 묵시적 기본값을 두지 않습니다.
- 분류가 불명확한 공고는 운영 반영 전에 원천 코드 정의 또는 기관 매칭 기준을 확정해야 합니다.
- `SOURCE_TYPE`은 화면 표시, 필터, 마커 색상에 직접 영향을 주므로 신규 채널 추가 PR/배포 전 샘플 건수 검증을 필수로 합니다.

신규 API 동기화 SQL 추가 전 확인 항목:

| 확인 항목 | 기준 |
|---|---|
| 원천 식별자 | 채널 접두사를 붙여 `WANTED_AUTH_NO` 충돌 방지 |
| 분류 근거 | `SOURCE_TYPE` 산출 근거를 SQL 주석 또는 운영 문서에 남김 |
| 코드 변환 | 공공 R코드 또는 민간 원천코드 중 어느 체계인지 명시 |
| 주소/좌표 | `BASIC_ADDR` 확보 방식 또는 좌표 fallback 기준 명시 |
| 검증 | `SOURCE_TYPE` NULL/기타값 없음, 채널별 건수 확인 |

운영 반영 전 검증 SQL:

```sql
SELECT SOURCE, SOURCE_TYPE, COUNT(*) AS cnt
FROM v_job_posting
GROUP BY SOURCE, SOURCE_TYPE
ORDER BY SOURCE, SOURCE_TYPE;

SELECT COUNT(*) AS invalid_source_type_cnt
FROM v_job_posting
WHERE SOURCE_TYPE NOT IN ('공공', '민간')
   OR SOURCE_TYPE IS NULL;
```

고용24 공공기관 공고 목록 적재 기준:

- 고용24 공공기관 공고 목록은 `scripts/load_work24_public_jobs.py`로 `tb_work24_public_job`에 적재합니다.
- 스크립트는 `WORK24_AUTH_KEY`로 공식 OpenAPI의 기업형태 파라미터 `coTp=04`를 호출해 공공기관 공고만 적재합니다.
- HTML 화면 파싱은 사용하지 않습니다.
- 고용24 원천 공고는 `scripts/load_work24_source_api.py`로 `tb_empmn_worknet_api`에 적재합니다. 같은 `WORK24_AUTH_KEY`로 채용정보 OpenAPI 목록(`callTp=L`)을 수집하고 staging 교체 방식으로 갱신합니다.
- 테이블 컬럼은 `WANTED_AUTH_NO`(공고번호), `INFO_TYPE_CD`(정보제공처 코드), `INFO_TYPE_GROUP`(정보제공처 그룹), `INST_NM`(기관명), `INST_TYPE`(기관유형, 공공=`P`)입니다.
- 고용24 원천 `tb_empmn_worknet_api.WANTED_AUTH_NO + INFO_SVC`가 이 테이블의 `WANTED_AUTH_NO + INFO_TYPE_CD`와 매칭되면 공공, 아니면 민간입니다. 현재 원천 API가 `tb_workinfoworknet/VALIDATION`만 제공하므로 원천과의 자동 매칭은 `INFO_TYPE_GROUP='tb_workinfoworknet'` 대상으로 제한합니다.
- 매칭율 검증은 `scripts/verify_work24_public_match_rate.sh`로 실행합니다. 검증 SQL은 읽기 전용이며 `db/verify_work24_public_match_rate.sql`에 있습니다.

2026-06-30 로컬 검증 결과:

| 구분 | 건수 | 비율 |
|---|---:|---:|
| 공공 | 40 | 0.06% |
| 민간 | 63,059 | 99.94% |
| 합계 | 63,099 | 100.00% |

검증 당시 원천 API 응답 총건수는 63,122건이고, 중복 제거 후 적재 건수는 63,099건입니다. `coTp=04` 공공기관 API 응답과 적재 건수는 40건입니다.

### 공고 식별자 접두사 규칙

| 채널 | 접두사 | 예시 |
|------|--------|------|
| 워크넷 / 공공기관(API 수집) | `PUB-` | `PUB-240001234` |
| 잡코리아(민간) | `JK-` | `JK-51057935` |
| 건설공제회 | `CWMA-` | `CWMA-10023` |
| KB굿잡 | `KB-` | `KB-98765` |
| IBK 아이원잡 | `IBK-` | `IBK-A12345` |
| 잡코리아 기간제 | `JKR-` | `JKR-20011` |
| 잡아바 자체 | `UNT-` | `UNT-300001` |

> 접두사 없이 GI_NO를 그대로 사용하면 채널 간 충돌 가능성 있음 — **반드시 접두사 부여**  
> `tb_empmn_map_coord.WANTED_AUTH_NO` 도 동일 접두사로 좌표 저장 필요

### 관련 DDL 파일

| 파일 | 용도 |
|------|------|
| `db/v_job_posting_local.sql` | 로컬 개발용 동기화 SQL (worknet + jobkorea) |
| `db/v_job_posting_prod_template.sql` | 운영 전환용 동기화 SQL 템플릿 (7개 채널, jedut.tb_code TODO 포함) |

---

## 6. 구현 전략 (방안 A → B)

### 방안 A — 완료 ✅

**목표**: 워크넷(공공) + 잡코리아(민간) 통합 조회  
**로컬 시연 데이터**: 공공기관 465건 + 잡코리아 433건 = **898건**

**완료된 작업:**

| 파일 | 변경 내용 |
|------|---------|
| `MapSearchVO.java` | 구 필터 필드 제거, 통합 JOB_ 필드 추가 (`jobCareerCd`, `jobAcdmcrCd`, `jobEmpTpCd`, `jobNcsCd`) |
| `MapMapper.xml` | `v_job_posting` 조회, `SOURCE` / `SOURCE_TYPE` SELECT 추가, JOB_ 컬럼 기반 WHERE 조건 |
| `JobPostingVO.java` | `source`, `sourceType` 필드 추가 |
| `MapServiceImpl.java` | `balancePublicAndPrivate()` — 공공/민간 균형 노출 로직 추가 |

**`MapServiceImpl.balancePublicAndPrivate()` 동작 원리:**
- `getJobListByViewport()` 호출 시 요청 size의 5배(최대 2,000건)를 DB에서 가져옴
- 가져온 후보군을 공공/민간 교대 배치하여 최종 `size` 건 반환
- 필터 적용 시(R코드 조건) 잡코리아는 미노출 — jedut.tb_code 매핑 완료 후 해소됨

### 방안 B — 완료 ✅

**목표**: `v_job_posting` 배치/동기화 테이블 방식으로 다채널 통합, 운영 전환 대비 구조 확립  
**핵심**: 앱 코드 무변경 — 동기화 SQL만 교체하면 운영 채널 반영

**방안 B 단계별 필터 지원 확장 (운영 전환 후):**

| 우선순위 | 채널 | 현재 상태 | 전제 조건 |
|---------|------|---------|---------|
| 1 | `tb_empmn_jobkorea_etc_api` | 동기화 SQL에 채널 추가 필요 | 없음 |
| 2 | `tb_ent_untact_empmn` | 동기화 SQL에 채널 추가 필요 (컬럼명 ALIAS 처리) | 없음 |
| 3 | `jwrki.tb_public_job` | 동기화 SQL에 채널 추가 필요 (R코드 직접 호환 확인 완료) | 없음 |
| 4 | `tb_empmn_cwma_api` | 동기화 SQL에 jedut.tb_code JOIN 추가 | jedut.tb_code 데이터 확보 |
| 5 | `jedut.tb_recruit_jobkorea_api` | 동기화 SQL에 채널 추가 필요 (텍스트만) | 없음 |
| 6 | `tb_empmn_ionejob_api` | 동기화 SQL에 채널 추가 필요 (텍스트만) | 없음 |
| 7 | `tb_empmn_kb_goobjob_api` | 텍스트→코드 역매핑 필요 | jedut.tb_code 데이터 확보 |

---

## 7. 좌표 캐시 테이블

### `tb_empmn_map_coord` (좌표 캐시)

```sql
CREATE TABLE tb_empmn_map_coord (
    WANTED_AUTH_NO  VARCHAR(50)   NOT NULL PRIMARY KEY  COMMENT '공고 식별자 (접두사 포함)',
    LAT             DECIMAL(18,15) NULL                 COMMENT '위도',
    LNG             DECIMAL(18,15) NULL                 COMMENT '경도',
    GEOCODE_YN      CHAR(1)       NOT NULL DEFAULT 'N'  COMMENT '좌표변환완료여부',
    REG_DT          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX IX_EMPMN_MAP_COORD_VIEWPORT (GEOCODE_YN, LAT, LNG, WANTED_AUTH_NO)
);
```

> ⚠️ `WANTED_AUTH_NO`는 반드시 채널 접두사(JK-, CWMA- 등) 포함 — `v_job_posting`과 동일한 형식

**로컬 개발 현황 (2026-06-12 기준):**

| 출처 | WANTED_AUTH_NO 접두사 | 건수 |
|------|----------------------|-----:|
| 공공기관 채용공시 API | PUB- | 465 |
| 잡코리아 (운영DB 추출) | JK- | 433 |
| **합계** | | **898** |

**지오코딩 우선순위 (운영 반영 시):**
1. `BASIC_ADDR + DETAIL_ADDR` (워크넷 — 직접 사용 가능)
2. `AREA_NM + AREA_DETAIL_NM` (건설공제회 — 시/군 수준)
3. `BIZ_NO` → 기업 테이블 JOIN → 기업 주소 (잡코리아, 잡아바)
4. `AREA_CD` / `WORK_RGN_CDS` → R3000 대표 좌표 fallback

### 좌표 생성 운영 정책 (2026-06-26 결정)

초기 운영 단계에서는 별도 좌표 저장 API나 서버 REST 지오코딩 배치를 만들지 않는다.  
사용자 수가 많지 않은 전제에서는 브라우저에서 카카오맵 JS SDK의 Geocoder를 사용하여 주소를 좌표로 변환하고, 화면 표출에 사용한다.

**초기 방식:**
1. 지도 데이터 조회 시 좌표가 있는 공고는 `tb_empmn_map_coord` 값을 사용한다.
2. 좌표가 없고 주소가 있는 공고는 프론트엔드에서 Kakao Maps JS Geocoder로 주소를 좌표 변환한다.
3. 변환 결과는 우선 브라우저 화면 표출용으로만 사용한다.
4. 좌표 저장 API는 초기 범위에서 제외한다.

**주소 확보 기준:**
1. 고용24는 원천의 근무지 주소를 사용한다.
2. 공공데이터포털 API처럼 사업자번호가 없는 데이터는 기관명으로 `TB_ENT_EXCLNC`를 정확 매칭한 뒤 사업자번호를 보강하고, 사업자번호 기준으로 주소를 조회한다.
3. 공공데이터포털 수동, 잡코리아, 아이원잡, KB굿잡은 사업자번호로 `TB_ENT_EXCLNC` 주소를 조회한다.

**확장 검토 조건:**
- 사용자 접속 전에 좌표가 미리 생성되어야 하는 경우
- 브라우저 지오코딩 호출량이나 지도 로딩 시간이 문제가 되는 경우
- 지오코딩 실패/재시도/처리 로그 관리가 필요한 경우
- 매일 자동 수집되는 공고의 좌표를 운영자가 화면을 열지 않아도 생성해야 하는 경우

위 조건이 발생하면 다음 중 하나를 선택한다.

| 확장안 | 내용 | 전제 |
|--------|------|------|
| 좌표 저장 API | 프론트엔드 JS Geocoder 결과를 서버로 전송해 `tb_empmn_map_coord`에 저장 | 기존 카카오 JS 키 사용 가능 |
| 서버 REST 배치 | 서버에서 Kakao Local REST API로 주소를 좌표 변환 후 저장 | 카카오 REST API 키 필요 |

따라서 현재 기준의 확정 방향은 **프론트엔드 JS Geocoder 우선**, **좌표 저장 API/서버 REST 배치는 확장 시점에 재검토**이다.

---

## 8. 필터 모달 ↔ DB 컬럼 매핑

### API 응답 주요 필드

| VO 필드명 | API 응답 키 | 설명 |
|---------|-----------|------|
| `source` | `source` | 채널명 (공공기관, 잡코리아, …) |
| `sourceType` | `sourceType` | 공공 / 민간 |
| `wantedAuthNo` | `wantedAuthNo` | 공고 식별자 |
| `company` | `company` | 기업명 |
| `title` | `title` | 공고 제목 |
| `closeDt` | `closeDt` | 마감일 (`YYYY-MM-DD`) |
| `jobCareerCd` | `jobCareerCd` | 통합 경력코드 (R2000) |
| `jobAcdmcrCd` | `jobAcdmcrCd` | 통합 학력코드 (R7000) |
| `jobEmpTpCd` | `jobEmpTpCd` | 통합 고용형태코드 (R1000) |
| `jobAreaCd` | `jobAreaCd` | 통합 지역코드 (R3000) |
| `lat` / `lng` | `lat` / `lng` | 좌표 |

### 필터 파라미터 ↔ DB 컬럼

| 필터 항목 | API 파라미터 | DB 컬럼 | 코드 그룹 | 현재 지원 채널 |
|---------|------------|---------|---------|-------------|
| 직종 | `jobNcsCd` | `JOBS_CD` | R6000 | 공공기관(워크넷) |
| 경력 | `jobCareerCd` | `JOB_CAREER_CD` | R2000 | 공공기관(워크넷) |
| 학력 | `jobAcdmcrCd` | `JOB_ACDMCR_CD` | R7000 | 공공기관(워크넷) |
| 고용형태 | `jobEmpTpCd` | `JOB_EMP_TP_CD` | R1000 | 공공기관(워크넷) |
| 희망임금 | — | — | — | 코드체계 없음 **→ 필터 제거** |
| 기업형태 | — | — | — | 매핑 컬럼 없음 **→ 필터 제거** |
| 장애인희망채용 | — | — | — | 매핑 컬럼 없음 **→ 필터 제거** |

> 잡코리아 필터 미지원 이유: JOB_ 컬럼에 R코드가 아닌 원천코드 저장  
> jedut.tb_code 데이터 확보 후 표준 조회 객체 동기화 SQL 업데이트 시 `현재 지원 채널` 확장 가능

---

## 9. 운영 전환 가이드

### 전환 절차

```
① jedut.tb_code 데이터 구조 확인
      ↓
② v_job_posting_prod_template.sql 의 TODO 주석 채우기
   (원천코드 → R코드 CASE WHEN 또는 jedut.tb_code JOIN 방식)
      ↓
③ 원천 데이터 갱신 후 v_job_posting 동기화 SQL 실행
   v_job_posting_staging 생성 → 인덱스 생성 → RENAME TABLE 교체
   최종 v_job_posting 객체는 실시간 VIEW가 아니라 BASE TABLE
   (db/v_job_posting_prod_template.sql 기반)
      ↓
④ 운영 DB에 tb_empmn_map_coord 테이블 생성 (또는 기존 테이블 확인)
   접두사 기준 좌표 배치 실행
      ↓
⑤ 앱 코드 변경 없이 배포 → 앱은 계속 v_job_posting만 조회
```

### 전환 시 주의사항

| 항목 | 주의 내용 |
|------|---------|
| 스키마명 명시 | `jwrki.`, `jedut.`, `jmmbi.` 등 반드시 스키마명 포함 |
| WANTED_AUTH_NO 중복 | 채널 간 GI_NO 중복 가능 — 접두사(JK-, CWMA- 등) 반드시 부여 |
| 마감일 포맷 통일 | 원천 `YYYYMMDD` → `YYYY-MM-DD` 동기화 SQL에서 CASE WHEN 변환 처리 |
| 좌표 키 일치 | `v_job_posting.WANTED_AUTH_NO` = `tb_empmn_map_coord.WANTED_AUTH_NO` 접두사 동일 |
| tb_code 미확보 채널 | JOB_ 컬럼 NULL 처리 → 해당 채널 필터 미지원 (지도 표시는 가능) |
| 해외취업 테이블 | `jedut.tb_recruit_world_api` 는 별도 표준 조회 객체 또는 서비스로 분리 권장 |

### 배치/동기화 테이블 운영 기준

- `v_job_posting`은 이름만 기존 연동 계약을 유지하고, 실제 객체는 `BASE TABLE`로 운영합니다.
- 원천 채용 데이터 수집 배치는 하루 1회 실행되는 것으로 확정합니다.
- `v_job_posting` 동기화 SQL도 원천 채용 데이터 수집 배치가 끝난 뒤 하루 1회 실행합니다.
- 동기화 SQL은 `v_job_posting_staging`을 먼저 생성하고, 인덱스를 모두 만든 후 `RENAME TABLE`로 기존 테이블과 교체합니다.
- 요청 시점에는 `UNION ALL`, 코드 변환, 사업자번호 정규화 조인을 수행하지 않습니다.
- 앱과 MyBatis mapper는 원천 테이블을 직접 조회하지 않고 최종 `v_job_posting`만 조회합니다.
- 일자리맵 Spring 앱에는 별도 스케줄러, Spring Batch, Quartz 배치 개발을 추가하지 않습니다.
- 대신 `v_job_posting` 동기화 SQL을 실행하는 배치 단계는 필요합니다.
- 로컬/일반 DB 실행 스크립트는 `scripts/sync_v_job_posting.sh`입니다.
- Docker Compose 개발서버 실행 스크립트는 `scripts/sync_v_job_posting_docker.sh`입니다.
- 운영 배치 수정 범위는 기존 원천 데이터 일 1회 갱신 작업의 후속 단계로 위 스크립트 또는 동일 SQL 실행을 추가하는 것입니다.

### 추가/운영 DB 객체 목록

| 객체 | 유형 | 운영 유지 여부 | 용도 |
|---|---|---:|---|
| `tb_empmn_map_coord` | 테이블 | 유지 | 채용공고 좌표 캐시 |
| `tb_jobcls_ncs_map` | 테이블 | 유지 | NCS 코드와 잡아바 직종 3차 코드 매핑 |
| `v_job_posting` | 테이블 | 유지 | 앱이 조회하는 최종 표준 채용공고 테이블 |
| `v_job_posting_staging` | 테이블 | 임시 | 동기화 배치 중 새 `v_job_posting`을 만들기 위한 교체 준비 테이블 |
| `v_job_posting_old` | 테이블 | 임시 | `RENAME TABLE` 교체 중 기존 테이블을 잠시 보관하는 백업명 |

운영 점검 기준:

- `v_job_posting`은 `information_schema.TABLES.TABLE_TYPE = 'BASE TABLE'`이어야 합니다.
- `v_job_posting_staging`, `v_job_posting_old`는 정상 동기화 완료 후 남아 있으면 안 됩니다.
- 앱과 MyBatis mapper는 `v_job_posting`만 조회하며 staging/old 테이블을 직접 조회하지 않습니다.

### 로컬 개발 환경 서버 기동

```bash
# Java 경로 설정 후 Gradle bootRun
JAVA_HOME=/opt/homebrew/Cellar/openjdk@11/11.0.31/libexec/openjdk.jdk/Contents/Home \
./gradlew bootRun

# API 엔드포인트
GET http://localhost:8080/api/v1/map/jobs?swLat=34.0&swLng=125.0&neLat=38.5&neLng=130.0
GET http://localhost:8080/api/v1/map/jobs/{wantedAuthNo}
```

---

## 10. 공공데이터포털 API 검토 결과

> **검토일**: 2026-06-12  
> **End Point**: `https://apis.data.go.kr/1051000/recruitment`  
> **데이터 성격**: 공공기관 채용공시 (→ `jwrki.tb_public_job` 원천 데이터)

### API 기본 정보

| 항목 | 내용 |
|------|------|
| End Point | `https://apis.data.go.kr/1051000/recruitment` |
| 기능 | `/list` 목록조회, `/detail` 상세조회 |
| **일일 트래픽 한도** | **1,000건 / 기능** |
| 데이터 포맷 | JSON + XML |
| 인증방식 | 일반 인증키 (공공데이터포털 발급) |

### 요청 파라미터 ↔ 잡아바 공통코드 매핑 확인

| API 파라미터 | 샘플값 | 잡아바 공통코드 | 확인 결과 |
|------------|--------|---------------|---------|
| `acbgCondLst` | R7010, R7050 | R7000 학력 | ✅ 동일 |
| `hireTypeLst` | R1010 | R1000 고용형태 | ✅ 동일 |
| `ncsCdLst` | R600006 | R6000 NCS분류 | ✅ 동일 |
| `recrutSe` | R2030 | R2000 채용구분 | ✅ 동일 |
| `workRgnLst` | R3013 | R3000 근무지역 | ✅ 동일 |

### 올바른 활용 구조

```
[공공데이터포털 API]
        │
        │  배치 수집 (일 1회)
        │  최신 공고 갱신
        ▼
[jwrki.tb_public_job]  ──→  [v_job_posting 동기화 테이블]  ──→  [지도 서비스 조회 API]
  로컬 DB 직접 조회                                                실시간 빠른 응답
```

API는 **데이터 수집 배치 전용**으로 사용하고, 지도 서비스는 로컬 DB의 최종 `v_job_posting` 테이블만 조회한다.  
지도 idle 이벤트마다 외부 API 직접 호출 시 일일 한도(1,000건) 즉시 소진 위험.

---

## 11. 참고 파일

### 기획/설계 문서

| 파일명 | 용도 |
|--------|------|
| `25NIA-DE5059-01_물리 데이터 요소 정의서_(잡아바)_v1.0.xlsx` | 전체 테이블/컬럼 정의 |
| `MOEF_NKOD_DB_05_코드 정의서_v1.2 [배포용].pdf` | R1000~R7000 공통코드 정의 |
| `25NIA-DE5056-01_데이터 아키텍처 설계서_v1.0.pdf` | 전체 DB 아키텍처 |

### DB 스크립트

| 파일명 | 용도 |
|--------|------|
| `db/schema.sql` | 로컬 개발용 기본 스키마 |
| `db/v_job_posting_local.sql` | **로컬 동기화 SQL** — worknet(공공) + jobkorea(민간) UNION 후 `BASE TABLE` 교체 |
| `db/v_job_posting_prod_template.sql` | **운영 전환 동기화 SQL 템플릿** — 7개 채널, jedut.tb_code TODO 포함 |
| `db/demo_data.sql` | 공공기관 채용공시 465건 (공공데이터포털 API 수집) |
| `db/jobkorea_demo_data.sql` | 잡코리아 500건 (운영DB 추출 → 로컬 적재) |
| `db/collect_demo_data.py` | 공공기관 채용공시 수집 스크립트 |

### 백엔드 소스

| 파일명 | 용도 |
|--------|------|
| `src/.../vo/MapSearchVO.java` | 검색 조건 VO — `jobCareerCd`, `jobAcdmcrCd`, `jobEmpTpCd`, `jobNcsCd` |
| `src/.../vo/JobPostingVO.java` | 공고 응답 VO — `source`, `sourceType`, JOB_ 통합 필드 포함 |
| `src/.../dao/sql/MapMapper.xml` | MyBatis 쿼리 — 최종 `v_job_posting` 조회 |
| `src/.../service/impl/MapServiceImpl.java` | 서비스 — `balancePublicAndPrivate()` 공공/민간 균형 노출 |
