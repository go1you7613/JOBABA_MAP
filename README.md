# JOBABA MAP

잡아바 웹 서비스에 통합하기 위한 지도 기반 채용공고 탐색 기능입니다.

이 저장소는 개발팀 인계를 위한 소스 코드와 개발 관련 문서만 포함합니다. 기획, 디자인, 퍼블리싱 산출물과 원천 데이터 파일은 배포 대상에서 제외했습니다.

## 구성

- `backend/`: Spring Boot 2.7, Java 11 기반 멀티모듈
- `backend/fe-web/`: JSP 화면 채널, CSS/JavaScript 정적 리소스, 화면 Controller
- `backend/be-biz/`: REST API, Service, DAO, DB 접근
- `backend/core-domain/`: MyBatis SQL XML 등 도메인 리소스
- `backend/core-domain/src/main/java/kr/go/tkjf/usr/map/dao/sql/MapMapper.xml`: JOBABA 배치 규칙에 맞춘 MyBatis 조회 SQL
- `db/map_schema.sql`: MAP 신규 테이블 전용 DDL
- `db/work24_public_job_contract.sql`: 고용24 공공기관 분류 목록 계약
- `db/v_job_posting_prod_template.sql`: 검증된 운영 원천 5종을 통합하는 조회 계약
- `scripts/sync_v_job_posting.sh`: 원천 배치 성공 후 MAP 파생 테이블을 검증·교체하는 후속 스크립트
- `docs/developer-handoff-source-boundary.md`: 개발팀 전달 범위와 운영 원천 보호 기준
- `docs/SECURITY/`: 보안 개발 가이드

독립 실행본의 `MapBizHttpClient`는 로컬 검증용입니다. 실제 JOBABA `fe-web`에
병합할 때는 기존 공통 통신 규격인 `CustomHttpClient + ApiUrlEnum.BIZ +
CommonResVo`로 연결합니다.

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
export JOBABA_DB_URL='jdbc:mysql://127.0.0.1:3307/jwrki?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Seoul'
export JOBABA_DB_USERNAME='jobaba'
export JOBABA_DB_PASSWORD='<local-password>'
export JOBABA_MAP_KAKAO_JS_KEY='<kakao-javascript-key>'
```

## DB 인계 기준

GitHub 전달본은 잡아바 운영 원천 데이터 적재 로직을 포함하지 않습니다.

- 포함: MAP 좌표/NCS 매핑 DDL, 고용24 공공분류 계약, 운영 원천 5종 조회 계약
- 제외: 원천 API 수집기, CSV 적재기, 운영 원천 테이블 생성 SQL, 운영 데이터 덤프
- 금지: 운영 원천 테이블에 대한 `INSERT`, `UPDATE`, `DELETE`, `DROP`, `TRUNCATE`, `RENAME`

`db/map_schema.sql`은 MAP 서비스가 새로 사용하는 테이블만 생성합니다.
`db/v_job_posting_prod_template.sql`은 동기화된 JOBABA DB에서 실제 컬럼을 검증한
원천 5종만 읽고, MAP 소유 파생 객체 `v_job_posting`만 갱신합니다.

원천 데이터는 잡아바의 기존 운영 배치가 현재 방식대로 `INSERT`/`UPDATE`합니다. MAP 서비스는 별도 원천 수집 또는 재적재를 수행하지 않습니다.

공공/민간 분류 기준은 다음과 같습니다.

- `jwrki.tb_public_job`: `공공데이터포털` / `공공`
- 고용24: `tb_work24_public_job` 복합키 일치 시 `공공`, 미일치 시 `민간`
- 잡코리아 일반·ETC·인턴: 모두 `민간`

동기화 스크립트는 중복 실행을 DB advisory lock으로 막습니다. 고용24 활성 공고가
있는데 공공분류 계약 또는 실제 공공 매칭이 0건이면 기존 `v_job_posting`을 보존하고
실패합니다.

## 배포 제한

이 브랜치는 개발팀 전달 및 잡아바 개발서버 반영 검토용입니다. 잡아바 개발서버 반영 전에는 개인 EC2를 포함한 어떤 서버에도 배포하지 않습니다.

## 검증

```bash
cd backend
./gradlew test
cd ..
node --test backend/fe-web/src/test/js/*.test.js
scripts/verify_source_boundary.sh
```
