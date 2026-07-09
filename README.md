# JOBABA MAP

잡아바 웹 서비스에 통합하기 위한 지도 기반 채용공고 탐색 기능입니다.

이 저장소는 개발팀 인계를 위한 소스 코드와 개발 관련 문서만 포함합니다. 기획, 디자인, 퍼블리싱 산출물과 원천 데이터 파일은 배포 대상에서 제외했습니다.

## 구성

- `backend/`: Spring Boot 2.7, Java 11 기반 멀티모듈
- `backend/fe-web/`: JSP 화면 채널, CSS/JavaScript 정적 리소스, 화면 Controller
- `backend/be-biz/`: REST API, Service, DAO, DB 접근
- `backend/core-domain/`: MyBatis SQL XML 등 도메인 리소스
- `backend/core-domain/src/main/resources/kr/go/tkjf/usr/map/dao/sql/MapMapper.xml`: MyBatis 조회 SQL
- `db/map_schema.sql`: 데이터 없는 스키마 전용 DDL
- `db/v_job_posting_prod_template.sql`: 운영 DB 전환용 조회 객체 템플릿
- `db/v_job_posting_local.sql`: 로컬 개발용 조회 객체
- `docs/operation-handoff-map-service.md`: 개발팀 운영 전환 가이드
- `docs/data/db-structure-map-service.md`: DB 구조 및 개발 가이드
- `docs/SECURITY/`: 보안 개발 가이드

## 로컬 실행

Java 11 환경에서 실행합니다. 로컬 기본 포트는 `fe-web` 8080, `be-biz` 8081입니다.

```bash
cd backend
./gradlew :be-biz:bootRun
./gradlew :fe-web:bootRun
```

기본 URL은 다음과 같습니다.

```text
http://localhost:8080/map
```

DB 접속 정보는 환경변수로 주입합니다.

```bash
export JOBABA_DB_URL='jdbc:mysql://127.0.0.1:3306/jobaba_map?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Seoul'
export JOBABA_DB_USERNAME='jobaba'
export JOBABA_DB_PASSWORD='<local-password>'
```

## DB 인계 기준

GitHub 배포본에는 스키마 정보만 포함합니다.

- 포함: 테이블 DDL, 조회 객체 템플릿
- 제외: 원천 CSV, 데모 데이터, 백필 데이터, 운영 데이터 덤프

로컬 단독 개발이 필요하면 `db/map_schema.sql`을 먼저 적용한 뒤 `db/v_job_posting_local.sql`을 적용합니다. 운영 통합 시에는 `db/v_job_posting_prod_template.sql`을 기준으로 개발/운영 DB 스키마명과 코드 매핑을 확정해야 합니다.

## 검증

```bash
cd backend
./gradlew test
```
