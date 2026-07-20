# JOBABA MAP

잡아바 웹 서비스에 통합하기 위한 지도 기반 채용공고 탐색 기능입니다.

이 저장소는 개발팀 인계를 위한 소스 코드와 개발 관련 문서만 포함합니다. 기획, 디자인, 퍼블리싱 산출물과 원천 데이터 파일은 배포 대상에서 제외했습니다.

## 구성

- `backend/`: Spring Boot 2.7, Java 11 기반 멀티모듈
- `backend/fe-web/`: JSP 화면 채널, CSS/JavaScript 정적 리소스, 화면 Controller
- `backend/be-biz/`: REST API, Service, DAO, DB 접근
- `backend/core-domain/`: MyBatis SQL XML 등 도메인 리소스
- `backend/core-domain/src/main/resources/kr/go/tkjf/usr/map/dao/sql/MapMapper.xml`: MyBatis 조회 SQL
- `db/map_schema.sql`: MAP 신규 테이블 전용 DDL
- `db/v_job_posting_prod_template.sql`: 운영 원천 테이블을 읽기만 하는 조회 계약 템플릿
- `docs/developer-handoff-source-boundary.md`: 개발팀 전달 범위와 운영 원천 보호 기준
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

GitHub 전달본은 잡아바 운영 원천 데이터 적재 로직을 포함하지 않습니다.

- 포함: MAP 좌표/NCS 매핑 테이블 DDL, 읽기 전용 조회 계약 템플릿
- 제외: 원천 API 수집기, CSV 적재기, 원천 테이블 생성 SQL, 전체 삭제/교체 배치, 운영 데이터 덤프
- 금지: 운영 원천 테이블에 대한 `DROP`, `TRUNCATE`, `DELETE`, `RENAME`

`db/map_schema.sql`은 MAP 서비스가 새로 사용하는 테이블만 생성합니다. `db/v_job_posting_prod_template.sql`은 기존 운영 원천 테이블을 변경하지 않는 조회 객체 예시이며, 실제 적용 전 개발팀이 운영 스키마명·컬럼·공공/민간 분류 기준을 확정해야 합니다.

원천 데이터는 잡아바의 기존 운영 배치가 현재 방식대로 `INSERT`/`UPDATE`합니다. MAP 서비스는 별도 원천 수집 또는 재적재를 수행하지 않습니다.

## 배포 제한

이 브랜치는 개발팀 전달 및 잡아바 개발서버 반영 검토용입니다. 잡아바 개발서버 반영 전에는 개인 EC2를 포함한 어떤 서버에도 배포하지 않습니다.

## 검증

```bash
cd backend
./gradlew test
```
