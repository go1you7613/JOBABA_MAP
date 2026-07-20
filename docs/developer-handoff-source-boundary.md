# JOBABA MAP 개발팀 전달 소스 범위

작성일: 2026-07-20

## 1. 적용 원칙

잡아바 운영 원천 채용 데이터와 적재 배치는 개발팀의 현행 운영 구조를 그대로 사용합니다.

- 운영 원천 데이터 적재 방식은 기존 `INSERT`/`UPDATE` 방식을 유지합니다.
- MAP 소스는 운영 원천 테이블을 생성하거나 초기화하지 않습니다.
- MAP 소스는 원천 API를 직접 수집하거나 CSV를 원천 테이블에 적재하지 않습니다.
- MAP 소스는 운영 원천 테이블에 `DROP`, `TRUNCATE`, `DELETE`, `RENAME`을 실행하지 않습니다.
- staging/old 교체는 MAP 소유 파생 테이블인 `v_job_posting`에만 사용합니다.
- 원천 수집 배치 완료 후 `v_job_posting` 동기화를 후속 단계로 실행합니다.

## 2. 개발팀 전달 대상

### 애플리케이션

- 사용자 지도 화면과 정적 리소스
- 지도 REST API
- 지도 조회 Service/DAO/MyBatis Mapper
- 지도 검색·응답 VO

실제 JOBABA 모듈에 반영할 때는 다음 기존 규칙을 유지합니다.

- `fe-web`의 BIZ 호출은 `kr.go.tkjf.httpclient.CustomHttpClient`,
  `ApiUrlEnum.BIZ`, `CommonResVo` 조합을 사용합니다.
- 이 저장소의 `MapBizHttpClient`는 독립 실행·검증용 어댑터이며,
  개발팀 통합 시 기존 `PublicJobController`와 `SearchController`의 호출 패턴으로
  치환합니다.
- Mapper XML은
  `core-domain/src/main/java/kr/go/tkjf/usr/map/dao/sql/MapMapper.xml`에 배치합니다.
- Mapper와 DDL의 DB 객체는 Linux 운영의 대소문자 구분을 고려해
  `jwrki.` + 실제 소문자 테이블명으로 통일합니다.

### MAP 신규 DB 객체

- `tb_empmn_map_coord`: 채용공고 좌표 캐시
- `tb_jobcls_ncs_map`: NCS와 잡아바 직종코드 매핑
- `tb_work24_public_job`: 개발팀 배치가 적재하는 고용24 공공기관 분류 계약
- `db/work24_public_job_contract.sql`: 위 분류 계약의 복합키와 컬럼 정의

### 원천 조회 계약

- `v_job_posting`: 채널별 운영 원천을 MAP 공통 컬럼으로 적재한 인덱스 물리 테이블
- `db/v_job_posting_prod_template.sql`: 검증된 원천 5종을 읽어 staging을 만드는 SQL
- `scripts/sync_v_job_posting.sh`: staging 검증 후 MAP 소유 테이블만 원자 교체하는 단일 후속 스크립트

동기화 스크립트는 DB advisory lock으로 중복 실행을 차단하고, 다음 조건이 모두
충족될 때만 교체합니다.

- 27개 컬럼, 1건 이상, 공고 ID 누락·중복 0건
- `tb_public_job` 활성 건수와 공공데이터포털 통합 건수 일치
- 잡코리아 공공 오분류 0건
- 고용24 활성 공고가 있으면 공공분류 계약과 실제 공공 매칭이 각각 1건 이상

조회 계약에는 다음 원천만 포함합니다.

- `jwrki.tb_empmn_worknet_api`
- `jwrki.tb_public_job`
- `jwrki.tb_empmn_jobkorea_api`
- `jwrki.tb_empmn_jobkorea_etc_api`
- `jedut.tb_recruit_jobkorea_api`

CWMA, KB굿잡, 아이원잡, 잡아바 자체공고는 실제 컬럼과 분류 기준을 확인하기 전까지 제외합니다.

## 3. 전달 대상에서 제거한 항목

- 고용24 OpenAPI 원천 수집기
- 고용24 공공기관 별도 수집기
- Worknet CSV 적재기
- 문서/CSV 기반 로컬 원천 적재기
- `tb_empmn_worknet_api_prev` 등 운영 원천 교체 테이블
- Docker/개인 EC2 전용 동기화 스크립트
- 운영 원천 테이블을 로컬 형태로 재생성하는 DDL

## 4. 운영 반영 시 개발팀이 연결할 항목

실제 운영 컬럼은 동기화된 로컬 JOBABA DB에서 대조했습니다. 개발팀은 운영 반영 시
다음 실행 연결만 확인하면 됩니다.

1. `db/map_schema.sql`과 `db/work24_public_job_contract.sql`의 MAP 신규 객체 반영
2. 기존 고용24 공공기관 목록 배치의 적재 대상을 `jwrki.tb_work24_public_job`로 연결
3. 기존 원천 수집 배치 성공 후 `scripts/sync_v_job_posting.sh` 실행 연결
4. 최초 `v_job_posting` VIEW→물리 테이블 전환은 점검 시간에
   `JOBABA_ALLOW_VIEW_MIGRATION=Y`로 1회 실행
5. 최초 전환도 기존 VIEW를 백업명으로 함께 `RENAME`한 뒤 성공 시 제거
6. 이후 실행은 검증 성공 시에만 MAP 소유 `v_job_posting`을 원자 교체

## 5. 적용 순서

1. 개발팀 제공 소스와 로컬 잡아바 개발환경을 동기화합니다.
2. `db/map_schema.sql`과 `db/work24_public_job_contract.sql`을 적용합니다.
3. 기존 개발팀 배치의 고용24 공공기관 목록 적재 대상을 연결합니다.
4. MAP 신규 객체와 애플리케이션 소스를 잡아바 모듈에 반영합니다.
5. 원천 수집 배치 종료 후 `scripts/sync_v_job_posting.sh`를 실행하도록 후속 단계를 등록합니다.
6. 로컬 잡아바 개발서버에서 공공·민간 채널과 주요 화면을 검증합니다.
7. 검증 결과를 개발팀에 전달한 뒤 잡아바 개발서버 배포 여부를 별도로 결정합니다.

## 6. 배포 제한

이 변경은 GitHub 소스 전달까지만 수행합니다.

- 개인 EC2 서버에 배포하지 않습니다.
- 잡아바 개발서버에도 자동 배포하지 않습니다.
- 잡아바 개발서버 배포는 개발팀 소스 동기화와 로컬 검증이 끝난 후 별도 승인으로 진행합니다.
