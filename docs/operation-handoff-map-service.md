# JOBABA MAP 운영 전환 개발팀 전달 문서

작성일: 2026-06-27

## 1. 전환 전제

일자리맵은 잡아바 기존 시스템에 통합해 운영합니다.

- 별도 독립 메뉴에 종속하지 않습니다.
- 도메인은 잡아바 도메인을 사용합니다.
- 서비스 URL은 하위폴더 방식으로 운영합니다.
  - 예: `https://job.gg.go.kr/jobaba_map`
- 개발팀 적용 흐름은 다음 순서입니다.
  1. 개발팀 잡아바 로컬 개발환경에 소스/DB 반영
  2. 로컬 기능 확인
  3. 개발서버 배포
  4. 개발서버 최종 확인
  5. 운영서버 배포

현재 이 저장소는 독립 Spring Boot 형태로 개발되어 있습니다. 개발팀은 아래 소스, 정적 리소스, MyBatis mapper, DB 객체를 잡아바 기존 프로젝트 구조에 맞게 이식해야 합니다.

## 2. 기능 스펙 요약

기능정의 기준 일자리맵의 핵심 스펙은 다음과 같습니다.

| 구분 | 내용 |
|---|---|
| 목적 | 잡아바 웹 서비스 내 지도 기반 일자리 탐색 기능 제공 |
| 운영 URL | 잡아바 도메인의 하위폴더 방식, 예: `/jobaba_map/` |
| 지도 | Kakao Maps JavaScript API |
| 데이터 | 운영 DB 원천 채용 테이블을 일 1회 배치/동기화되는 `v_job_posting` 표준 조회 테이블로 통합 |
| 지도 노출 기준 | 좌표 캐시 `tb_empmn_map_coord`에 `GEOCODE_YN='Y'` 좌표가 있는 공고 |
| 좌표 생성 | 주소가 있는 미좌표 공고를 브라우저 Kakao Geocoder로 변환 후 저장 |
| 공공/민간 구분 | `SOURCE_TYPE` 기준 |
| 공공 NCS 필터 | NCS 선택값 `R6000xx`를 `tb_jobcls_ncs_map`으로 잡아바 `CMMN_276`과 매핑 |
| 민간 직종 필터 | 잡아바 `CMMN_274` 대분류 기준 |
| 검색 범위 | 현재 지도 뷰포트의 남서/북동 좌표 기준 |

주요 사용자 기능:

- 지도 기반 채용공고 마커 표시
- 공공/민간 구분 표시와 탭 필터
- 키워드 검색
- 공공 필터: NCS, 고용형태, 경력, 학력
- 민간 필터: 직종 대분류, 고용형태, 경력, 학력
- 목록/지도 연동
- 공고 상세 보기와 지원 URL 연결
- 현재 위치/장소 검색 기반 지도 이동

## 3. 처리 흐름

### 3.1 화면 로딩 흐름

1. 사용자가 `https://job.gg.go.kr/jobaba_map/`에 접근합니다.
2. 잡아바 서버가 일자리맵 정적 화면 `index.html`을 반환합니다.
3. `index.html`이 `css/map.css`, `js/map.js`를 로드합니다.
4. `map.js`가 Kakao Maps JS SDK를 로드합니다.
5. 지도 초기화 후 Kakao 지도 `idle` 이벤트에서 채용공고 목록 조회가 실행됩니다.

현재 독립 앱 기준 페이지 컨트롤러는 `MapController`입니다.

- 파일: `backend/src/main/java/kr/go/tkjf/usr/map/controller/MapController.java`
- 현재 경로: `/map`
- 현재 forward: `/map/index.html`

잡아바 운영 적용 시에는 `/jobaba_map/` 요청이 일자리맵 화면을 반환하도록 기존 잡아바 라우팅 또는 `ResourceHandler`를 조정해야 합니다.

### 3.2 채용공고 목록 조회 흐름

1. `map.js`가 현재 지도 bounds를 계산합니다.
2. `/api/v1/map/jobs`로 다음 조건을 전달합니다.
   - `swLat`, `swLng`, `neLat`, `neLng`
   - `sourceType`
   - `keyword`
   - 공공/민간 필터 코드
3. `MapApiController.getJobList()`가 `MapSearchVO`로 조건을 받습니다.
4. `MapServiceImpl.getJobListByViewport()`가 페이징과 공공/민간 균형 처리를 수행합니다.
5. `MapMapper.xml`이 `v_job_posting`과 `tb_empmn_map_coord`를 조인해 좌표가 있고 마감되지 않은 공고만 조회합니다.
6. 서버는 같은 조건의 전체 건수를 `X-Total-Count` 응답 헤더로 내려줍니다.
7. 프론트엔드는 한 번에 20건씩 목록을 불러오며, 화면의 검색결과 숫자는 로딩된 개수가 아니라 `X-Total-Count` 기준 전체 건수를 표시합니다.

관련 파일:

- `backend/src/main/resources/static/map/js/map.js`
  - `loadJobs()`
  - `buildJobSearchParams()`
  - `appendActiveServerFilters()`
- `backend/src/main/java/kr/go/tkjf/usr/map/controller/MapApiController.java`
- `backend/src/main/java/kr/go/tkjf/usr/map/service/impl/MapServiceImpl.java`
- `backend/src/main/resources/kr/go/tkjf/usr/map/dao/sql/MapMapper.xml`

### 3.3 좌표 변환 흐름

1. 목록 조회 후 `map.js`가 `geocodeMissingJobs()`를 실행합니다.
2. `/api/v1/map/jobs/coord-pending`에서 좌표가 없는 공고를 최대 20건 조회합니다.
3. 서버는 `BASIC_ADDR`가 존재하고, 좌표 캐시에 없거나 `GEOCODE_YN='N'`인 공고만 반환합니다.
4. 브라우저가 Kakao Maps JS Geocoder로 주소를 좌표로 변환합니다.
5. 변환 성공 시 `/api/v1/map/jobs/coords`로 좌표를 저장합니다.
6. 서버는 좌표값 범위를 검증한 뒤 `tb_empmn_map_coord`에 upsert합니다.
7. 저장 후 목록을 다시 조회하면 해당 공고가 지도에 노출됩니다.

고용24는 원천 주소가 없으면 좌표 변환 대상에서 제외되며 지도에 노출되지 않습니다.

### 3.4 상세 조회 흐름

1. 사용자가 마커 또는 목록 공고를 선택합니다.
2. 프론트엔드가 `/api/v1/map/jobs/{wantedAuthNo}`를 호출합니다.
3. 서버는 `v_job_posting` 기준 상세 정보와 좌표 캐시를 조회합니다.
4. 상세 패널에서 공고명, 기업명, 주소, 경력/학력/고용형태, 지원 URL을 표시합니다.
5. 지원 URL은 `http:` 또는 `https:`만 버튼으로 렌더링합니다.

### 3.5 공공 NCS 필터 흐름

1. 사용자가 공공 탭에서 NCS 필터를 선택합니다.
2. `map.js`가 `jobNcsCd=R6000xx`를 `/api/v1/map/jobs`에 전달합니다.
3. 서버는 `JOBS_CD` 직접 매칭을 하지 않습니다.
4. `MapMapper.xml`은 `tb_jobcls_ncs_map`에서 `NCS_CD -> CMMN_276` 매핑을 조회합니다.
5. `v_job_posting.JOBABA_CMMN_276_CD`와 매핑되는 공고만 반환합니다.

운영 전제:

- 고용24에는 직접 `R6000xx` NCS 코드가 없다고 봅니다.
- 고용24 직종은 잡아바 분류체계 기반이며, `CMMN_276`으로 NCS와 연결합니다.

## 4. Kakao Maps JS 키 적용

Kakao Maps JavaScript 키는 운영 반영 전 반드시 개발팀 키로 교체해야 합니다.

현재 키 위치:

- 파일: `backend/src/main/resources/static/map/js/kakao-key.js`
- 위치: `window.JobabaMapKakaoKey.selectKakaoJsKey()`
- 현재 코드:

```javascript
var KAKAO_JS_KEY = window.JobabaMapKakaoKey.selectKakaoJsKey(window.location.href);
```

`map.js`는 위 선택 결과를 사용해 Kakao Maps SDK를 로드합니다. 키 값 또는 도메인별 키 선택 규칙을 바꿀 때는 `kakao-key.js`를 수정합니다.

SDK 로드 위치:

- 파일: `backend/src/main/resources/static/map/js/map.js`
- 처리: `script.src = 'https://dapi.kakao.com/v2/maps/sdk.js?appkey=' + KAKAO_JS_KEY + '&libraries=services&autoload=false';`

운영 적용 시 확인할 것:

- 운영용 Kakao JavaScript 키를 `kakao-key.js`에 반영합니다.
- Kakao Developers에서 다음 도메인을 허용 도메인에 등록합니다.
  - 로컬: `localhost`
  - 개발서버: `https://jobaba-map.tanauxd.com`
  - 운영: `job.gg.go.kr`
- 모바일 현위치 기능은 브라우저 보안 정책상 HTTPS 또는 localhost에서만 정상 동작합니다. 개발서버 모바일 QA는 `https://jobaba-map.tanauxd.com/map/index.html`처럼 HTTPS 도메인으로 접속해야 합니다.
- 정적 리소스 경로를 `/jobaba_map/js/...`로 변경해 배치하는 경우, 변경된 경로의 `kakao-key.js`가 함께 배포되어야 합니다.
- `map-share.html`을 운영에서 사용할 경우 `backend/src/main/resources/static/map/map-share.html`의 `/map/index.html` 링크도 `/jobaba_map/` 기준으로 변경해야 합니다.

## 5. 소스 적용 범위

### 5.1 Java 소스

다음 패키지의 소스를 잡아바 기존 시스템에 추가합니다. 기존 프로젝트의 패키지 정책이 다르면 패키지명은 조정하되 클래스 역할은 유지합니다.

| 구분 | 파일 | 역할 |
|---|---|---|
| Controller | `backend/src/main/java/kr/go/tkjf/usr/map/controller/MapController.java` | 일자리맵 페이지 진입 |
| REST Controller | `backend/src/main/java/kr/go/tkjf/usr/map/controller/MapApiController.java` | 지도 조회/상세/좌표 저장 API |
| Service | `backend/src/main/java/kr/go/tkjf/usr/map/service/MapService.java` | 지도 서비스 인터페이스 |
| Service Impl | `backend/src/main/java/kr/go/tkjf/usr/map/service/impl/MapServiceImpl.java` | 페이징, 공공/민간 균형, 좌표 검증 |
| DAO | `backend/src/main/java/kr/go/tkjf/usr/map/dao/MapDao.java` | MyBatis mapper 인터페이스 |
| VO | `backend/src/main/java/kr/go/tkjf/usr/map/vo/JobPostingVO.java` | 채용공고 응답 |
| VO | `backend/src/main/java/kr/go/tkjf/usr/map/vo/MapSearchVO.java` | 검색 조건 |
| VO | `backend/src/main/java/kr/go/tkjf/usr/map/vo/MapCoordVO.java` | 좌표 저장 요청 |

확인 사항:

- 기존 잡아바 프로젝트의 component scan 대상에 Controller/Service 패키지가 포함되어야 합니다.
- `MapDao`가 MyBatis mapper scan 대상에 포함되어야 합니다.
- 기존 보안/인증 interceptor가 `/jobaba_map`, `/api/v1/map/**` 호출을 막지 않는지 확인해야 합니다.
- 좌표 저장 API는 `POST` JSON 요청이므로 CSRF 정책이 있는 경우 예외 또는 토큰 처리가 필요합니다.

### 5.2 MyBatis mapper

다음 XML을 잡아바 프로젝트의 MyBatis mapper 경로에 추가합니다.

- `backend/src/main/resources/kr/go/tkjf/usr/map/dao/sql/MapMapper.xml`

기존 프로젝트 설정에 맞춰 `mapper-locations`에 포함되어야 합니다.

현재 독립 앱 기준 설정:

```properties
mybatis.mapper-locations=classpath:kr/go/tkjf/usr/map/dao/sql/*.xml
```

잡아바 기존 프로젝트의 mapper 경로가 다르면 XML 위치 또는 설정을 맞춰야 합니다.

### 5.3 정적 리소스

현재 정적 리소스는 아래 위치에 있습니다.

| 파일 | 역할 |
|---|---|
| `backend/src/main/resources/static/map/index.html` | 일자리맵 메인 화면 |
| `backend/src/main/resources/static/map/css/map.css` | 일자리맵 CSS |
| `backend/src/main/resources/static/map/js/map.js` | 지도, 필터, API 연동 JS |
| `backend/src/main/resources/static/map/map-share.html` | 공유/확장 화면 |

운영 URL을 `/jobaba_map`으로 가져갈 경우 개발팀 권장 배치는 다음 중 하나입니다.

| 방식 | 설명 |
|---|---|
| 정적 리소스 경로 변경 | `/static/jobaba_map/index.html`, `/static/jobaba_map/css/map.css`, `/static/jobaba_map/js/map.js`로 배치 |
| ResourceHandler 추가 | `/jobaba_map/**` 요청을 현재 `/static/map/**` 리소스로 매핑 |

중요:

- 화면 URL은 `/jobaba_map` 또는 `/jobaba_map/`로 열리게 합니다.
- CSS/JS 상대경로가 깨지지 않도록 실제 정적 리소스 URL 기준을 맞춰야 합니다.
- 현재 `index.html`은 `css/map.css`, `js/map.js` 상대경로를 사용합니다.
- `/jobaba_map`처럼 trailing slash 없이 접근할 경우 상대경로가 `/css/map.css`로 해석될 수 있으므로 `/jobaba_map/`로 redirect하거나 `<base>`/리소스 경로를 조정해야 합니다.

### 5.4 URL 매핑

현재 독립 앱 기준:

| 구분 | 현재 경로 |
|---|---|
| 페이지 | `/map`, `/map/index.html` |
| 목록 API | `/api/v1/map/jobs` |
| 상세 API | `/api/v1/map/jobs/{wantedAuthNo}` |
| 좌표 미변환 API | `/api/v1/map/jobs/coord-pending` |
| 좌표 저장 API | `/api/v1/map/jobs/coords` |

잡아바 운영 권장:

| 구분 | 권장 경로 |
|---|---|
| 페이지 | `/jobaba_map/` |
| 정적 리소스 | `/jobaba_map/css/map.css`, `/jobaba_map/js/map.js` |
| API | `/api/v1/map/**` 유지 권장 |

API를 `/jobaba_map/api/v1/map/**` 하위로 넣는 경우 `map.js`의 API 호출 경로를 함께 변경해야 합니다. 현재 `map.js`는 `/api/v1/map/...` 절대경로를 사용합니다.

## 6. 개발팀 적용 단계

### 6.1 로컬 개발환경 적용

1. Java 소스와 mapper XML을 잡아바 로컬 프로젝트에 추가합니다.
2. 정적 리소스를 `/jobaba_map` URL로 접근 가능한 위치에 배치합니다.
3. 로컬 DB에 신규 테이블을 생성하거나 동기화 SQL로 생성합니다.
   - `tb_empmn_map_coord`
   - `tb_jobcls_ncs_map`
   - `v_job_posting`은 `db/v_job_posting_local.sql` 동기화 실행 시 생성됩니다.
   - `v_job_posting_staging`은 동기화 중 임시 생성 후 교체 완료 시 제거됩니다.
4. `db/jobcls_ncs_map.sql`을 실행해 매핑 데이터를 적재합니다.
5. 로컬 DB에 `v_job_posting` 배치/동기화 조회 테이블을 생성합니다.
   - 성능 기준상 최종 객체는 실시간 VIEW가 아니라 인덱스가 있는 `BASE TABLE`로 생성합니다.
   - 원천 데이터 갱신 후 `v_job_posting_staging`을 만들고, 인덱스를 생성한 뒤 `RENAME TABLE`로 최종 `v_job_posting`과 교체합니다.
   - 운영 구조 검증은 `db/v_job_posting_prod_template.sql` 기준으로 합니다.
   - 로컬 단독 검증이 필요하면 `db/v_job_posting_local.sql`을 참고합니다.
6. Kakao Developers에 로컬 도메인을 등록합니다.
   - 예: `localhost`
7. 로컬에서 `/jobaba_map/` 화면과 `/api/v1/map/jobs` API를 확인합니다.

### 6.2 개발서버 배포

개발서버 배포는 로컬 수정과 검증이 완료된 뒤 사용자 승인을 받은 경우에만 진행합니다. 수정 완료 직후 자동으로 개발서버 jar 교체, Docker 재빌드, 서비스 재시작을 수행하지 않습니다.

1. 개발서버 DB에 신규 테이블과 `v_job_posting` 배치/동기화 조회 테이블을 생성/갱신합니다.
2. 개발서버 도메인을 Kakao Developers 허용 도메인에 등록합니다.
3. 잡아바 개발서버에 소스와 정적 리소스를 배포합니다.
4. 개발서버 URL로 화면/API를 확인합니다.
5. 좌표 저장이 정상 동작하는지 확인합니다.

### 6.3 운영서버 배포

1. 운영 DB 반영 SQL을 재확인합니다.
2. 운영 도메인 `job.gg.go.kr`이 Kakao Developers 허용 도메인에 등록되어 있는지 확인합니다.
3. 운영 소스 배포 전 개발서버 QA 결과를 확인합니다.
4. 운영 배포 후 `/jobaba_map/` 화면, API, 필터, 좌표 저장을 확인합니다.

## 7. DB 인수인계 항목

> **인수인계 범위 (2026-07-01 확정)**
>
> - **공공데이터포털 · 고용24 API**: 잡아바 서버에서 현재 운영 중인 기존 API를 그대로 사용합니다. 별도 인수인계 대상이 아닙니다.
> - **Kakao Maps JS API**: 이 프로젝트에서 신규 적용된 API입니다. 운영 배포 후 `kakao-key.js`의 JavaScript 키를 운영 도메인용으로 교체해야 합니다. (→ Section 4 참조)
> - **기존 테이블 컬럼 추가**: `db/schema.sql` 전체 검토 결과 ALTER TABLE(컬럼 추가) 없음이 확인됩니다.
> - **인수인계 DB 대상**: 아래 신규 테이블 3종에 한합니다. 나머지는 운영 중인 기존 DB를 그대로 사용합니다.

일자리맵 운영을 위해 추가 또는 보장해야 하는 DB 객체는 다음과 같습니다.

| 객체 | 유형 | 운영 유지 여부 | 용도 |
|---|---|---:|---|
| `tb_empmn_map_coord` | 테이블 | 유지 | 채용공고 좌표 캐시 |
| `tb_jobcls_ncs_map` | 테이블 | 유지 | NCS 코드와 잡아바 직종 3차 코드 매핑 |
| `v_job_posting` | 테이블 | 유지 | 앱이 조회하는 최종 표준 채용공고 테이블 |
| `v_job_posting_staging` | 테이블 | 임시 | 동기화 배치 중 새 `v_job_posting`을 만들기 위한 교체 준비 테이블 |
| `v_job_posting_old` | 테이블 | 임시 | `RENAME TABLE` 교체 중 기존 테이블을 잠시 보관하는 백업명 |

`v_job_posting_staging`, `v_job_posting_old`는 정상 완료 후 남아 있으면 안 됩니다. 운영 점검 시 `information_schema.TABLES`에서 최종 `v_job_posting`만 `BASE TABLE`로 남아 있는지 확인합니다.

### 7.1 `tb_empmn_map_coord`

좌표 캐시 테이블입니다. 지도 목록 노출과 좌표 저장 API가 사용합니다.

```sql
CREATE TABLE IF NOT EXISTS tb_empmn_map_coord (
    WANTED_AUTH_NO  VARCHAR(50) NOT NULL COMMENT '공고번호',
    LAT             DECIMAL(18,15) NULL COMMENT '위도',
    LNG             DECIMAL(18,15) NULL COMMENT '경도',
    GEOCODE_YN      CHAR(1) NOT NULL DEFAULT 'N' COMMENT '좌표변환완료여부',
    REG_DT          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일자',
    PRIMARY KEY (WANTED_AUTH_NO),
    INDEX IX_EMPMN_MAP_COORD_VIEWPORT (GEOCODE_YN, LAT, LNG, WANTED_AUTH_NO)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='채용공고 좌표 캐시';
```

주의사항:

- `WANTED_AUTH_NO`는 `v_job_posting`의 공고 식별자와 동일해야 합니다.
- 채널 간 중복 방지를 위해 표준 조회 객체 생성 시 접두사를 부여합니다.
  - 예: `JK-`, `CWMA-`, `KB-`, `IBK-`, `JKR-`, `UNT-`

### 7.2 `tb_jobcls_ncs_map`

공공 NCS 필터를 잡아바 직종 3차 코드와 연결하는 매핑 테이블입니다.

```sql
CREATE TABLE IF NOT EXISTS tb_jobcls_ncs_map (
    NCS_CD          VARCHAR(20) NOT NULL COMMENT 'NCS 코드(R6000xx)',
    JOBABA_GRP_CD  VARCHAR(20) NOT NULL COMMENT '잡아바 공통코드 그룹(CMMN_276)',
    JOBABA_CD      VARCHAR(20) NOT NULL COMMENT '잡아바 공통코드',
    USE_YN         CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '사용여부',
    REG_DT         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일자',
    UPD_DT         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일자',
    PRIMARY KEY (NCS_CD, JOBABA_GRP_CD, JOBABA_CD),
    INDEX IX_JOBCLS_NCS_MAP_JOBABA (JOBABA_GRP_CD, JOBABA_CD),
    INDEX IX_JOBCLS_NCS_MAP_NCS (NCS_CD)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='NCS-잡아바 직종 매핑';
```

적재 파일:

- `db/jobcls_ncs_map.sql`

운영 기준:

- 검색 기준은 NCS `R6000xx`입니다.
- 고용24에는 직접 NCS 코드가 없다고 보고 잡아바 분류체계 `CMMN_276`으로 매핑합니다.
- `R600001` 사업관리는 현재 직접 매핑 정확도가 낮아 매핑 대상에서 제외했습니다.

### 7.3 `v_job_posting`

지도 목록, 상세, 좌표 미변환 공고 조회 API가 공통으로 사용하는 최종 표준 채용공고 테이블입니다.

```sql
-- 실제 컬럼 정의와 생성 SQL은 db/v_job_posting_prod_template.sql 기준
-- 운영 최종 객체는 VIEW가 아니라 BASE TABLE이어야 합니다.
SELECT TABLE_NAME, TABLE_TYPE
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'v_job_posting';
```

운영 기준:

- `TABLE_TYPE`은 `BASE TABLE`이어야 합니다.
- 앱과 `MapMapper.xml`은 원천 테이블을 직접 조회하지 않고 `v_job_posting`만 조회합니다.
- 원천 데이터 일 1회 갱신 완료 후 `scripts/sync_v_job_posting.sh` 또는 운영 배치 시스템에서 동일 SQL을 실행해 갱신합니다.
- 최소 인덱스는 `WANTED_AUTH_NO`, `REG_DT`, `SOURCE_TYPE`, `USE_YN, DEL_YN`, `JOBABA_CMMN_276_CD, JOB_CAREER_CD, JOB_ACDMCR_CD, JOB_EMP_TP_CD`입니다.

### 7.4 `v_job_posting_staging`

`v_job_posting` 동기화 배치가 새 데이터를 먼저 적재하고 인덱스를 생성하는 임시 테이블입니다.

```sql
CREATE TABLE v_job_posting_staging AS
SELECT * FROM v_job_posting_source;

-- 인덱스 생성 후
RENAME TABLE v_job_posting TO v_job_posting_old,
             v_job_posting_staging TO v_job_posting;
```

운영 기준:

- 사용자 API는 이 테이블을 직접 조회하지 않습니다.
- 동기화 성공 후에는 남아 있으면 안 됩니다.
- 동기화 실패 시 `RENAME TABLE` 전 단계라면 기존 `v_job_posting`은 유지됩니다.

### 7.5 `v_job_posting_old`

`RENAME TABLE` 교체 중 기존 `v_job_posting`을 잠시 보관하는 임시 백업명입니다.

운영 기준:

- 정상 동기화 완료 후 `DROP TABLE IF EXISTS v_job_posting_old`로 제거됩니다.
- 운영 점검 시 남아 있다면 직전 동기화가 중간 실패했는지 확인해야 합니다.

## 8. `v_job_posting` 표준 조회 객체

`v_job_posting`은 애플리케이션의 표준 데이터 인터페이스입니다. 이름은 기존 연동 계약을 유지하기 위해 `v_` 접두사를 쓰지만, 운영/개발서버에서는 실시간 SQL VIEW가 아니라 배치/동기화로 갱신되는 인덱스 물리 테이블로 구성합니다.

운영 갱신 흐름:

1. 원천 채용 데이터 수집/갱신 배치가 일 1회 먼저 완료됩니다.
2. `v_job_posting_source` 또는 동등한 SELECT로 원천 테이블 통합, 사업자번호 정규화, 코드 변환을 수행합니다.
3. 결과를 `v_job_posting_staging` 테이블에 적재합니다.
4. `v_job_posting_staging`에 목록/상세/API 조회용 인덱스를 생성합니다.
5. `RENAME TABLE`로 기존 `v_job_posting`과 staging 테이블을 교체합니다.
6. 애플리케이션은 교체 전후 모두 동일하게 `v_job_posting`만 조회합니다.

일자리맵 Spring 앱에는 별도 스케줄러, Spring Batch, Quartz 배치 코드를 추가하지 않습니다. 대신 기존 원천 채용 데이터 일 1회 갱신 배치가 끝난 뒤 `scripts/sync_v_job_posting.sh` 또는 운영 배치 시스템에서 동일 SQL을 호출하는 후속 단계를 둡니다.

### 8.1 왜 필요한가

`v_job_posting`은 일자리맵 소스와 잡아바 운영 원천 테이블 사이의 조회 계약입니다. 새 데이터를 저장하기 위한 테이블이 아니라, 여러 채용 데이터 원천을 일자리맵이 읽을 수 있는 동일한 컬럼 구조로 맞추는 어댑터입니다.

개발팀이 이 내용을 명확히 이해해야 하는 이유:

- 일자리맵 Java/MyBatis 소스는 고용24, 잡코리아, 공공데이터포털 등 개별 원천 테이블을 직접 조회하지 않습니다.
- 현재 `MapMapper.xml`은 `v_job_posting`만 기준으로 목록, 상세, 좌표 미변환 공고를 조회합니다.
- 원천별로 다른 공고번호, 회사명, 주소, 직종코드, 마감일 컬럼을 `WANTED_AUTH_NO`, `COMPANY`, `BASIC_ADDR`, `SOURCE_TYPE`, `JOBABA_CMMN_276_CD` 같은 표준 컬럼으로 맞춰야 합니다.
- 지도 노출은 `v_job_posting.WANTED_AUTH_NO`와 `tb_empmn_map_coord.WANTED_AUTH_NO` 조인으로 처리되므로, 채널별 공고 식별자 규칙이 반드시 일치해야 합니다.
- 공공 NCS 필터는 `v_job_posting.JOBABA_CMMN_276_CD`와 `tb_jobcls_ncs_map` 매핑을 기준으로 동작합니다.

운영 DB에 이미 통합 채용 테이블 또는 통합 조회 객체가 있다면 `v_job_posting`은 그 구조를 직접 사용하거나, 필요한 경우에만 얇은 호환 객체로 둘 수 있습니다. 신규 구성 시에는 복잡한 `UNION ALL`, 코드 변환, 사업자번호 매칭을 요청 시점 VIEW에서 매번 수행하지 말고 원천 데이터 갱신 후 배치/동기화 시점에 물리 테이블로 반영합니다.

반대로 `v_job_posting` 또는 동등한 표준 조회 객체를 만들지 않으면 다음 작업이 필요합니다.

- `MapMapper.xml`에 운영 원천 테이블별 `UNION`과 컬럼 변환 로직을 직접 작성해야 합니다.
- 원천별 공고번호 접두사, 주소 정책, 공공/민간 구분, 직종코드 변환 로직이 mapper에 섞입니다.
- 이후 원천 테이블 구조가 바뀔 때마다 Java/MyBatis 쿼리 수정 범위가 커집니다.

따라서 운영 반영 시 권장 방식은 `MapMapper.xml`의 조회 대상 이름은 유지하고, 운영 DB 쪽에서 `v_job_posting`을 잡아바 실제 데이터 구조에 맞춘 배치/동기화 조회 테이블로 구성하는 것입니다.

### 8.2 성능 기준

개인 개발서버 배포 중 `v_job_posting`을 실시간 VIEW로 둘 경우 2건 조회도 약 9초가 걸리는 문제가 확인되었습니다. 로컬 DB에서도 같은 실행계획이 재현되었고, 원인은 `tb_ent_exclnc` 사업자번호 조인에서 `REPLACE(..., '-', '')` 함수가 적용되어 인덱스를 활용하지 못하는 풀스캔 조인이었습니다.

권장 기준:

- 최종 `v_job_posting`은 `BASE TABLE`이어야 합니다.
- 원천 테이블 통합, 사업자번호 정규화, 코드 변환은 원천 데이터 일 1회 갱신 후 실행되는 배치/동기화 SQL에서 수행합니다.
- 배치/동기화 SQL은 `v_job_posting_staging`을 먼저 만들고 인덱스를 생성한 뒤 `RENAME TABLE`로 최종 `v_job_posting`과 교체합니다.
- `MapMapper.xml`은 원천 테이블을 직접 조회하지 않고 `v_job_posting`만 조회합니다.
- 아래 인덱스를 생성합니다.
  - `WANTED_AUTH_NO`
  - `REG_DT`
  - `SOURCE_TYPE`
  - `USE_YN, DEL_YN`
  - `JOBABA_CMMN_276_CD, JOB_CAREER_CD, JOB_ACDMCR_CD, JOB_EMP_TP_CD`

검증 기준:

- `information_schema.TABLES`에서 `v_job_posting.TABLE_TYPE = 'BASE TABLE'` 확인
- `information_schema.TABLES`에 `v_job_posting_staging`이 남아 있지 않은지 확인
- 지도 목록 대표 쿼리가 1초 이내 응답하는지 확인
- `/api/v1/map/jobs` 초기 조회가 1초 이내 응답하는지 확인

기준 파일:

- `db/v_job_posting_prod_template.sql`

### 8.3 배치 개발 범위

`v_job_posting` 동기화 배치는 필요합니다. 다만 Java/Spring 애플리케이션 내부 배치로 만들 필요는 없습니다.

- 현재 일자리맵 앱에는 `@Scheduled`, Spring Batch, Quartz 기반 배치 코드가 없습니다.
- 원천 채용 데이터는 하루 1회 갱신되는 것으로 확정합니다.
- 운영 배치 수정 범위는 기존 원천 데이터 갱신 작업의 마지막 단계에 `v_job_posting` 동기화 SQL 실행을 추가하는 것입니다.
- 로컬/일반 DB 실행 스크립트는 `scripts/sync_v_job_posting.sh`입니다.
- Docker Compose 개발서버 실행 스크립트는 `scripts/sync_v_job_posting_docker.sh`입니다.
- 실행 주기는 일 1회이며, 원천 데이터 갱신 완료 직후 실행합니다.
- 동기화 실패 시 `RENAME TABLE` 전까지 기존 `v_job_posting`이 유지되므로 앱은 직전 정상 데이터를 계속 조회할 수 있습니다.

로컬 실행 예:

```bash
MYSQL_BIN=/opt/homebrew/bin/mysql \
JOBABA_DB_HOST=127.0.0.1 \
JOBABA_DB_PORT=3306 \
JOBABA_DB_USER=jobaba \
JOBABA_DB_PASSWORD='<로컬 DB 비밀번호>' \
JOBABA_DB_NAME=jobaba_map \
scripts/sync_v_job_posting.sh
```

운영/개발서버에서는 비밀번호를 스크립트에 직접 쓰지 말고 배치 시스템의 환경변수 또는 비밀관리 기능으로 주입합니다.

로컬 DB 접속 참고:

- 로컬 MariaDB 기본 접속 대상은 `127.0.0.1:3306`, DB는 `jobaba_map`, 사용자는 `jobaba`입니다.
- Spring Boot는 `backend/src/main/resources/application.properties`에서 `JOBABA_DB_URL`, `JOBABA_DB_USERNAME`, `JOBABA_DB_PASSWORD` 환경변수를 통해 DB 정보를 주입받습니다.
- 현재 셸에 `JOBABA_DB_PASSWORD`가 없더라도 DB 접속 불가로 단정하지 않습니다. 먼저 `lsof -nP -iTCP:3306 -sTCP:LISTEN`으로 로컬 MariaDB 기동 여부를 확인합니다.
- 비밀번호가 필요한 로컬 검증 작업은 사용자 승인 후 기존 로컬 개발 셸 히스토리에서 확인한 값을 일시적으로 사용하거나, 사용자가 `JOBABA_DB_PASSWORD`를 직접 export한 뒤 실행합니다.
- 비밀번호는 코드, SQL, 문서, 로그에 남기지 않습니다.

### 8.4 필수 출력 컬럼

| 컬럼 | 용도 |
|---|---|
| `WANTED_AUTH_NO` | 공고 고유 식별자 |
| `SOURCE` | 채널명 |
| `SOURCE_TYPE` | 공공/민간 구분 |
| `COMPANY` | 기업/기관명 |
| `TITLE` | 공고명 |
| `JOBS_NM` | 직무명 |
| `JOBS_CD` | 원천 직종코드 보관용 |
| `EMP_TP_NM` | 고용형태명 |
| `CAREER` | 경력명 |
| `MIN_EDUBG` | 학력명 |
| `SAL_AMT` | 임금 |
| `SAL_TP_NM` | 임금유형 |
| `REGION` | 지역명 |
| `CLOSE_DT` | 마감일 |
| `WANTED_INFO_URL` | 공고 상세 URL |
| `BASIC_ADDR` | 기본주소 |
| `DETAIL_ADDR` | 상세주소 |
| `INFO_SVC` | 서비스 구분 |
| `JOB_CAREER_CD` | 공공/민간 경력 필터 코드 |
| `JOB_ACDMCR_CD` | 공공/민간 학력 필터 코드 |
| `JOB_EMP_TP_CD` | 공공/민간 고용형태 필터 코드 |
| `JOB_AREA_CD` | 지역 코드 |
| `JOBABA_CMMN_276_CD` | 잡아바 3차 직종코드, 공공 NCS 매핑에 사용 |
| `JOBABA_CMMN_274_CD` | 잡아바 1차 직종코드, 민간 직종 대분류 필터에 사용 |
| `REG_DT` | 등록일 |
| `USE_YN` | 사용 여부 |
| `DEL_YN` | 삭제 여부 |

## 9. 운영 정책

### 9.1 공공/민간 구분

고용24는 공식 OpenAPI의 `coTp=04`(기업형태: 공공기관) 응답을 기준으로 공공/민간을 분류합니다. 공공기관 공고 목록을 별도 테이블에 적재하고, 원천 데이터의 공고번호와 정보제공처 코드가 매칭되면 `공공`, 매칭되지 않으면 `민간`으로 처리합니다.

신규 테이블은 `tb_work24_public_job`입니다.

| 컬럼 | 의미 |
|---|---|
| `WANTED_AUTH_NO` | 고용24 공고번호 |
| `INFO_TYPE_CD` | 정보제공처 코드 |
| `INFO_TYPE_GROUP` | 정보제공처 그룹 |
| `INST_NM` | 기관명 |
| `INST_TYPE` | 기관유형, 공공은 `P` |

| 기준 | SOURCE_TYPE |
|---|---|
| 고용24 원천 `WANTED_AUTH_NO + INFO_SVC`가 `tb_work24_public_job.WANTED_AUTH_NO + INFO_TYPE_CD`와 매칭되고 `INFO_TYPE_GROUP='tb_workinfoworknet'`, `INST_TYPE='P'` | 공공 |
| 미매칭 | 민간 |

고용24 화면에서 보이는 공고 수와 외부 API로 내려받는 공고 수는 다를 수 있습니다. 화면에는 고용24 자체 공고가 더 많이 포함될 수 있고, 외부 API는 공개된 일부 항목만 제공합니다. 따라서 운영 기준은 "고용24 화면 기준"이 아니라 "고용24 외부 API 제공 기준"입니다.

고용24 공공기관 공고 목록 적재는 `scripts/load_work24_public_jobs.py`를 사용합니다. 이 스크립트는 `WORK24_AUTH_KEY`로 공식 OpenAPI의 기업형태 파라미터 `coTp=04`를 호출해 공공기관 공고만 `tb_work24_public_job`에 적재합니다. HTML 화면 파싱은 사용하지 않습니다. 인증키는 환경변수로 주입하고, 코드/SQL/문서에 저장하지 않습니다.

고용24 원천 공고 적재는 `scripts/load_work24_source_api.py`를 사용합니다. 같은 `WORK24_AUTH_KEY`로 채용정보 OpenAPI 목록(`callTp=L`)을 페이지 단위로 수집한 뒤 `tb_empmn_worknet_api`를 staging 교체 방식으로 갱신합니다.

최종 제외 기준: `tb_app_hire_info.CO_PM`, 기관명 정규화/부분검색, 사업자번호 매칭, 사업자번호 유형코드 판별, 국세청 사업자등록정보 API, `JOBS_CD LIKE 'R600%'`, 고용24 HTML 화면 파싱.

로컬/운영 검증은 `scripts/verify_work24_public_match_rate.sh`로 실행합니다. 결과는 첨부 검증표처럼 `항목 / 전체 / 진행중` 기준으로 고용24 전체 공고, 공공기관 공고 목록 매칭, 신규 공공/민간 판정을 출력합니다.

2026-06-30 로컬 검증 결과:

| 구분 | 건수 | 비율 |
|---|---:|---:|
| 공공 | 40 | 0.06% |
| 민간 | 63,059 | 99.94% |
| 합계 | 63,099 | 100.00% |

### 9.2 고용24 주소 정책

고용24는 원천 테이블의 `BASIC_ADDR`, `DETAIL_ADDR`만 사용합니다.

- 주소가 있으면 좌표 변환 대상입니다.
- 주소가 없으면 지도 비노출입니다.
- 고용24는 `BIZ_NO -> TB_ENT_EXCLNC.BIZRNO -> 주소` fallback을 하지 않습니다.

### 9.3 공공데이터포털/잡코리아 주소 정책

- 공공데이터포털은 `BIZ_REG_NO -> tb_ent_exclnc.BIZRNO`로 기업 주소를 조회합니다.
- 공공데이터포털의 사업자번호가 비어 있는 경우, 기관명과 `tb_ent_exclnc.ENT_NM`이 정확히 1건으로 매칭될 때만 `BIZ_REG_NO`를 보강합니다.
- 잡코리아는 `BIZ_NO -> tb_ent_exclnc.BIZRNO`로 기업 주소를 조회합니다.

### 9.4 좌표 처리

- 지도 목록 조회는 `v_job_posting`과 `tb_empmn_map_coord`를 조인합니다.
- `GEOCODE_YN='Y'`이고 현재 지도 뷰포트 범위에 포함되는 좌표만 노출됩니다.
- 좌표가 없는 공고는 `/api/v1/map/jobs/coord-pending`에서 조회합니다.
- `BASIC_ADDR`가 없거나 빈 문자열이면 좌표 변환 대상에서 제외됩니다.
- 브라우저에서 Kakao Maps JS Geocoder로 주소를 좌표로 변환한 뒤 `/api/v1/map/jobs/coords`로 저장합니다.

## 10. QA 체크리스트

### 10.1 로컬

- `/jobaba_map/` 화면 200 확인
- CSS/JS 로드 200 확인
- 콘솔 오류 없음
- `/api/v1/map/jobs` 200 확인
- 전체/공공/민간 탭 전환 확인
- 공공 NCS 필터 확인
  - 예: `sourceType=PUB&jobNcsCd=R600002`
  - 결과는 `tb_jobcls_ncs_map`과 `JOBABA_CMMN_276_CD` 매핑 기준이어야 합니다.
- 고용24 주소 없는 공고가 지도에 노출되지 않는지 확인
- 좌표 없는 주소 보유 공고가 `/coord-pending`으로 조회되는지 확인
- 좌표 저장 API `/api/v1/map/jobs/coords`가 정상 저장하는지 확인
- 공고 상세 버튼 URL이 `http`/`https`만 렌더링되는지 확인

### 10.2 개발서버

- 개발서버 도메인에서 Kakao Maps JS 로드 확인
- 지도 타일/주소검색 API 호출 확인
- 실제 운영 유사 데이터로 공공/민간 필터 확인
- `/jobaba_map/` 하위폴더 접근 시 새로고침, 직접 URL 접근, 공유 URL 접근 확인

### 10.3 운영서버

- `https://job.gg.go.kr/jobaba_map/` 접근 확인
- 운영 도메인에서 Kakao Maps JS 로드 확인
- 운영 DB `v_job_posting`이 `BASE TABLE`인지 확인
- 운영 DB `v_job_posting` 조회 성능 확인
- 운영 로그에 SQL 오류, 404, 500이 없는지 확인

## 11. 참고 파일

- 운영 조회 객체 템플릿: `db/v_job_posting_prod_template.sql`
- 로컬 조회 객체 템플릿: `db/v_job_posting_local.sql`
- NCS 매핑 테이블/데이터: `db/jobcls_ncs_map.sql`
- 공공데이터포털 사업자번호 보강: `db/public_job_bizno_backfill.sql`
- MyBatis mapper: `backend/src/main/resources/kr/go/tkjf/usr/map/dao/sql/MapMapper.xml`
- 지도 프론트엔드: `backend/src/main/resources/static/map/js/map.js`
- 기능정의: `docs/feature-spec.md`

## 12. 소스코드 QA 결과 (2026-07-01 — 멀티 에이전트 검토)

기준: OWASP Top 10 (2021) + KISA 소프트웨어 보안약점 진단가이드 + 코드 로직/품질 전수 검토

### 12.1 종합 등급

| 구분 | Critical | High | Medium | Low |
|---|---|---|---|---|
| 보안 점검 | 1 | 4 | 6 | 4 |
| 코드/기능 점검 | 0 | 7 | 9 | 6 |

**양호한 항목**: SQLi 방어(전체 `#{...}` 바인딩), XSS 방어(`escapeHtml` 일관 적용, `getSafeExternalUrl`), 입력 검증(VO JSR-303 + 서비스 이중 검증), 에러 정보 노출 차단, DB 자격증명 환경변수 처리

### 12.2 배포 차단 항목 (잡아바 통합 전 필수 수정)

#### [CRITICAL] `/jobs/coords` 쓰기 API — 인증 부재 + Origin 헤더 위조 가능
**위치**: `MapApiController.java:44-79`

`isSameOriginWrite()`가 `X-Forwarded-Host`/`X-Forwarded-Proto` 헤더를 무조건 신뢰합니다. 공격자가 `Origin`과 `X-Forwarded-Host`를 동일 값으로 설정하면 검증을 통과합니다. 이 API는 사실상 누구나 `tb_empmn_map_coord`에 임의 좌표를 쓸 수 있는 공개 쓰기 API입니다.

잡아바 통합 후 Spring Security를 적용하여 이 API는 인증 필수로 제한해야 합니다. 최소한 허용 Origin을 설정값으로 고정하십시오.

```properties
# application.properties에 추가
jobaba.security.allowed-origins=https://job.gg.go.kr
```

```java
// MapApiController.java — X-Forwarded-* 신뢰 제거, 화이트리스트로 교체
@Value("${jobaba.security.allowed-origins:}")
private List<String> allowedOrigins;

private boolean isSameOriginWrite(HttpServletRequest request) {
    String origin = request.getHeader(HttpHeaders.ORIGIN);
    if (origin == null) return false;
    return allowedOrigins.contains(origin);
}
```

> **🔧 2026-07-01 부분 수정** — `isSameOriginWrite()`에서 `X-Forwarded-Host`/`X-Forwarded-Proto` 헤더 신뢰를 제거하고 서버 `HOST` 헤더만 사용하도록 수정 완료. 허용 Origin 화이트리스트(`@Value` 주입) 및 Spring Security 인증 통합은 **개발팀 인수인계 항목**.

#### [HIGH] 인증·인가 계층 전면 부재
**위치**: 프로젝트 전반 — Spring Security 의존성 없음

`/jobs/coord-pending`(좌표 미변환 목록 + 상세 주소 포함)이 익명으로 접근 가능합니다. 잡아바 기존 보안 인터셉터가 `/api/v1/map/**`를 포괄하는지 확인하십시오. 포괄하지 않으면 별도 보안 처리가 필요합니다.

**잡아바 통합 체크리스트:**
- 기존 잡아바 보안 인터셉터가 `/api/v1/map/**` 경로를 차단하지 않는지 확인 (누락되면 맵 기능 동작 불가)
- `coord-pending`·`coords`는 인증 사용자만 접근 가능하도록 별도 처리 검토

#### [HIGH] `/api/vi/map` 오타 엔드포인트
**위치**: `MapApiController.java:20`

`v1`의 오타인 `vi` 경로가 동일 컨트롤러에 매핑됩니다. WAF/프록시 정책을 `/api/v1/*`에만 적용할 경우 `/api/vi/*`로 우회 가능합니다.

```java
// 수정: 오타 경로 제거
@RequestMapping("/api/v1/map")
```

> ✅ **2026-07-01 수정완료** — `MapApiController.java` `@RequestMapping("/api/v1/map")` 단일화 적용.

#### [HIGH] Swagger UI 운영 노출
**위치**: `application.properties:33-34`

`springdoc.swagger-ui.path=/swagger-ui.html` 설정이 잔존합니다. 현재 build.gradle에 springdoc 의존성은 없으나, 추후 추가 시 즉시 API 명세가 공개됩니다. 운영 프로파일에서 비활성화하십시오.

```properties
# application-prod.properties
springdoc.api-docs.enabled=false
springdoc.swagger-ui.enabled=false
```

> ✅ **2026-07-01 수정완료** — `application.properties`에서 springdoc 설정 섹션 전체 제거.

#### [HIGH] 전역 예외 처리기 부재 — 상세 조회 예외 시 500 반환
**위치**: `MapApiController.java:34-37`

`getJobDetail`에 try/catch가 없어 잘못된 형식의 `wantedAuthNo` 요청 시 500 반환. `saveCoord`는 400 처리, `getJobDetail`은 500 처리로 일관성이 없습니다. `@RestControllerAdvice` 전역 예외 핸들러를 추가하십시오.

> ✅ **2026-07-01 수정완료** — `getJobDetail()`에 try-catch 추가: `IllegalArgumentException` → 400, 조회 결과 null → 404.

#### [HIGH] 상세 조회에서 USE_YN/DEL_YN 필터 없음
**위치**: `MapMapper.xml:148-179` (`selectJobDetail`)

```sql
-- 현재: WHERE j.WANTED_AUTH_NO = #{wantedAuthNo} 만 있음
-- 수정: 삭제/미사용 공고 제외 조건 추가
WHERE j.WANTED_AUTH_NO = #{wantedAuthNo}
  AND j.USE_YN = 'Y'
  AND j.DEL_YN = 'N'
```

삭제·미사용 처리된 공고가 상세 API로 직접 접근 시 그대로 노출됩니다.

> ✅ **2026-07-01 수정완료** — `MapMapper.xml` `selectJobDetail`에 `AND j.USE_YN = 'Y' AND j.DEL_YN = 'N'` 조건 추가.

### 12.3 운영 반영 전 강력 권고

#### 보안

| # | 항목 | 위치 | 조치 | 상태 |
|---|---|---|---|---|
| 1 | 보안 응답 헤더 미설정 (CSP, X-Frame-Options, HSTS) | 프로젝트 전반 | 잡아바 기존 보안 헤더 설정 확인. 없으면 추가 | 개발팀 적용 |
| 2 | `size` 상한 불일치 (VO: 200, 서비스: 2000) | `MapServiceImpl.java:60` | `Math.min(size, 200)`으로 통일 | ✅ 수정완료 |
| 3 | 카카오 JS 키 하드코딩 + 개인 도메인 잔존 | `kakao-key.js:13-22` | 운영 배포 시 개인 도메인(`tanauxd.com`) 제거, Kakao 콘솔 허용 도메인 등록 필수 | 운영 배포 후 적용 |
| 4 | Spring Boot 2.7.10 EOL | `build.gradle` | 잡아바 기존 버전 확인. 공공기관 운영 기준 패치 버전 또는 최신 LTS 검토 | 개발팀 검토 |
| 5 | keyword LIKE 와일드카드 이스케이프 미처리 | `MapMapper.xml:34-38` | `%`, `_` 이스케이프 후 `ESCAPE '\\'` 사용 | ✅ 수정완료 |
| 6 | 전 구간 HTTPS 강제 미설정 | `application.properties` | `server.forward-headers-strategy=framework` + 프록시 HTTPS 리다이렉트 | 개발팀 적용 |

#### 기능/코드 품질

| # | 항목 | 위치 | 조치 | 상태 |
|---|---|---|---|---|
| 1 | `distance` 정렬 API 계약 불일치 | `MapMapper.xml:122`, `MapServiceImpl.java:20` | SORT_TYPES 및 `@Pattern`에서 `distance` 제거 | ✅ 수정완료 |
| 2 | countJobList + getJobList 이중 정규화/DB 쿼리 | `MapApiController.java:28-31` | list 먼저 호출 후 정규화된 VO를 count에 재사용 | ✅ 수정완료 |
| 3 | 다중 필터 선택 시 첫 값만 서버 전송 | `map.js:327-335` | 고용형태·경력·학력 필터는 다중값 전송 또는 UI를 단일 선택으로 제약 | 개발팀 검토 |
| 4 | 희망임금 필터 UI만 존재, 실제 동작 없음 | `map.js` (prvSalCds) | 서버 필터 미구현 상태를 UI에서 비활성화하거나 구현 완료 | 개발팀 구현 |
| 5 | `isPublicJob` 클라이언트/서버 판정 기준 불일치 | `map.js:1660-1663` | `job.sourceType === '공공'` 단일 기준으로 통일 | ✅ 수정완료 |
| 6 | geocode 성공 항목 재처리 방지 캐시 없음 | `map.js:432-434` | 저장 성공 ID를 `state.geocodeSavedIds`에 기록, 재지오코딩 방지 | ✅ 수정완료 |
| 7 | `updateCoord` 데드코드 | `MapMapper.xml:285-289` | `MapDao.java` 메서드 및 `MapMapper.xml` 블록 제거 | ✅ 수정완료 |

### 12.4 QA 이력

| QA 일자 | 대상 | 결과 |
|---|---|---|
| 2026-06-26 | `http://localhost:8080/map/index.html` (브라우저) | Health Score 96/100 — ISSUE-001 deferred |
| 2026-07-01 | 소스코드 멀티 에이전트 정적 분석 (보안 + 코드 품질) | Critical 1건 / High 11건 발견 — 배포 차단 항목 5건 |
| 2026-07-01 | 코딩 에이전트 3개 병렬 수정 적용 | 12건 수정완료 (배포차단 4건 + 권고 8건). 개발팀 이관: isSameOriginWrite 화이트리스트, 인증·인가 계층, 다중필터, 희망임금 필터, 보안헤더, HTTPS 강제, Kakao 운영 키 |

## 13. AWS 개발서버 배포 기록

개발서버는 Docker Compose 방식으로 운영됩니다.

### 13.1 서버 정보

| 항목 | 내용 |
|---|---|
| 서버 | AWS EC2 (`43.203.21.169`) |
| 개발서버 도메인 | `jobaba-map.tanauxd.com` |
| 앱 포트 | `18081:8080` (호스트:컨테이너) |
| DB | MariaDB 12.2 (Docker 컨테이너) |
| 런타임 | eclipse-temurin:11-jre |

### 13.2 배포 파일 위치

| 파일 | 위치 |
|---|---|
| Dockerfile | `tmp/jobaba_map_deploy/Dockerfile` |
| docker-compose.yml | `tmp/jobaba_map_deploy/docker-compose.yml` |
| DB 초기화 SQL | `tmp/jobaba_map_deploy/db/init/` |

### 13.3 배포 전 확인 체크리스트

개발서버 재배포 전 다음 항목을 확인합니다.

1. **jar 빌드**
   ```bash
   cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@11 \
     PATH=/opt/homebrew/opt/openjdk@11/bin:$PATH \
     ./gradlew bootJar
   cp build/libs/*.jar ../tmp/jobaba_map_deploy/app.jar
   ```

2. **Kakao 도메인 등록 확인**
   - `kakao-key.js`의 `DEVELOPMENT_HOSTS`에 `jobaba-map.tanauxd.com` 등록 ✅
   - Kakao Developers 허용 도메인에 `https://jobaba-map.tanauxd.com` 등록 확인

3. **환경변수 설정 확인**
   - `MARIADB_ROOT_PASSWORD`, `JOBABA_DB_USERNAME`, `JOBABA_DB_PASSWORD` 환경변수가 배포 서버에 설정되어 있는지 확인
   - `docker-compose.yml`은 이 변수들이 없으면 기동 거부함 (`:?` 문법)

4. **운영 키 미포함 확인**
   - `kakao-key.js`에 운영 도메인(`job.gg.go.kr`) 키가 추가된 경우, 잡아바 운영 배포 전 해당 키를 소스코드가 아닌 서버 환경 변수 또는 별도 파일로 분리할 것을 권고

5. **DB 초기화 SQL 동기화**
   - `tmp/jobaba_map_deploy/db/init/` 경로에 최신 schema SQL이 포함되어 있는지 확인
   - 신규 배포 시 `tb_empmn_map_coord`, `tb_jobcls_ncs_map` 생성 SQL과 `jobcls_ncs_map.sql` 데이터 적재 SQL이 필요
