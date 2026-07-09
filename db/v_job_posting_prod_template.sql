-- ============================================================
-- v_job_posting 표준 조회 객체 — 운영 서버 전환용 템플릿
-- ============================================================
-- 적용 조건 : 실제 개발서버(운영 DB)에 반영할 때 사용
-- 적용 위치 : 서비스 DB 스키마 (예: jwrki 또는 별도 MAP 스키마)
-- 주의사항  :
--   1. 각 채널 테이블의 스키마명 (jwrki, jedut, jmmbi) 반드시 명시
--   2. JOB_ 컬럼이 없는 테이블은 jedut.tb_code JOIN 으로 R코드 변환 필요
--   3. WANTED_AUTH_NO 는 채널 간 중복 방지를 위해 접두사 부여
--      (예: JKE-xxx / CWMA-xxx / KB-xxx / IBK-xxx / JKR-xxx / UNT-xxx)
--   4. 운영 조회 성능을 위해 최종 v_job_posting은 실시간 VIEW가 아니라
--      배치/동기화로 갱신되는 인덱스 물리 테이블로 구성
--   5. 고용24 SOURCE_TYPE은 tb_work24_public_job 복합 식별자 매칭으로 분류
--      WANTED_AUTH_NO + INFO_TYPE_CD + INFO_TYPE_GROUP이 매칭되면 '공공', 미매칭이면 '민간'
-- ============================================================
-- jedut.tb_code 기반 R코드 변환 방법 (JOB_ 컬럼 없는 테이블용)
-- jedut.tb_code 확보 후 아래 패턴으로 CASE WHEN 구성
--   JOB_CAREER_CD :
--     CASE t.GI_CAREER_CD
--       WHEN '원천신입코드' THEN 'R2010'
--       WHEN '원천경력코드' THEN 'R2020'
--       ...
--     END
-- ============================================================

-- !! 아래는 예시 구조입니다 — jedut.tb_code 데이터 확보 후 실제 코드값 대입 !!

-- 앱 조회 조인 대상과 문자셋/정렬 규칙을 맞춥니다.
-- 실제 운영 DB의 표준 collation이 다르면 전체 객체에 동일한 기준을 적용하십시오.
ALTER TABLE tb_empmn_map_coord
    CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE tb_jobcls_ncs_map
    CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 운영 반영 전 db/work24_public_job_schema.sql을 먼저 적용하고,
-- 고용24 공공기관 검색 목록의 복합 식별자를 tb_work24_public_job에 적재하십시오.

CREATE OR REPLACE VIEW v_job_posting_source AS

-- ① 고용24 (고용24 공공기관 공고 목록 공고번호 매칭 기준 공공/민간 분류)
SELECT
    w.WANTED_AUTH_NO,
    '고용24' AS SOURCE,
    CASE
        WHEN wp.WANTED_AUTH_NO IS NOT NULL THEN '공공'
        ELSE '민간'
    END AS SOURCE_TYPE,
    w.COMPANY, w.TITLE, w.JOBS_NM, w.JOBS_CD,
    w.EMP_TP_NM, w.CAREER, w.MIN_EDUBG, w.SAL_AMT, w.SAL_TP_NM,
    w.REGION, w.CLOSE_DT, w.WANTED_INFO_URL, w.BASIC_ADDR, w.DETAIL_ADDR, w.INFO_SVC,
    w.JOB_CAREER_CD, w.JOB_ACDMCR_CD, w.JOB_EMP_TP_CD, w.JOB_AREA_CD,
    CASE
        WHEN COALESCE(NULLIF(w.CL_CD, ''), NULLIF(w.JOBS_CD, '')) REGEXP '^[0-9]+$'
        THEN LEFT(LPAD(COALESCE(NULLIF(w.CL_CD, ''), NULLIF(w.JOBS_CD, '')), 6, '0'), 3)
        ELSE NULL
    END AS JOBABA_CMMN_276_CD,
    CASE
        WHEN COALESCE(NULLIF(w.CL_CD, ''), NULLIF(w.JOBS_CD, '')) REGEXP '^[0-9]+$'
        THEN LEFT(LPAD(COALESCE(NULLIF(w.CL_CD, ''), NULLIF(w.JOBS_CD, '')), 6, '0'), 1)
        ELSE NULL
    END AS JOBABA_CMMN_274_CD,
    w.REG_DT, w.USE_YN, w.DEL_YN
FROM jwrki.tb_empmn_worknet_api w
LEFT JOIN (
    SELECT WANTED_AUTH_NO, INFO_TYPE_CD
    FROM tb_work24_public_job
    WHERE INST_TYPE = 'P'
      AND INFO_TYPE_GROUP = 'tb_workinfoworknet'
    GROUP BY WANTED_AUTH_NO, INFO_TYPE_CD
) wp
  ON w.WANTED_AUTH_NO COLLATE utf8mb4_unicode_ci
   = wp.WANTED_AUTH_NO COLLATE utf8mb4_unicode_ci
 AND w.INFO_SVC COLLATE utf8mb4_unicode_ci
   = wp.INFO_TYPE_CD COLLATE utf8mb4_unicode_ci
WHERE w.USE_YN = 'Y' AND w.DEL_YN = 'N'

UNION ALL

-- ② 잡코리아 ETC (공공 — JOB_ 컬럼 있음)
SELECT
    WANTED_AUTH_NO,
    '잡코리아(공공)' AS SOURCE,
    '공공'           AS SOURCE_TYPE,
    COM_NAME AS COMPANY, GI_SUBJECT AS TITLE, PART_NO_INFO AS JOBS_NM, GI_PART_NO_CD AS JOBS_CD,
    PASS_TYPE_INFO AS EMP_TP_NM, CAREER_INFO AS CAREER, EDU_CUTLINE_INFO AS MIN_EDUBG,
    PAY_INFO AS SAL_AMT, NULL AS SAL_TP_NM,
    AREA_INFO AS REGION,
    CASE WHEN GI_END_DATE REGEXP '^[0-9]{8}$'
         THEN CONCAT(SUBSTR(GI_END_DATE,1,4),'-',SUBSTR(GI_END_DATE,5,2),'-',SUBSTR(GI_END_DATE,7,2))
         ELSE GI_END_DATE END AS CLOSE_DT,
    JK_URL AS WANTED_INFO_URL, NULL AS BASIC_ADDR, NULL AS DETAIL_ADDR, '공공' AS INFO_SVC,
    JOB_CAREER_CD, JOB_ACDMCR_CD, JOB_EMP_TP_CD, JOB_AREA_CD,
    CASE WHEN CL_CD REGEXP '^[0-9]+$' THEN LPAD(CL_CD, 3, '0') ELSE NULL END AS JOBABA_CMMN_276_CD,
    CASE WHEN CL_CD REGEXP '^[0-9]+$' THEN LEFT(LPAD(CL_CD, 3, '0'), 1) ELSE NULL END AS JOBABA_CMMN_274_CD,
    REG_DT, USE_YN, DEL_YN
FROM jwrki.tb_empmn_jobkorea_etc_api
WHERE USE_YN = 'Y' AND DEL_YN = 'N'

UNION ALL

-- ③ 건설공제회 (민간 — GI_CAREER_CD 등 원천코드 → jedut.tb_code 변환 필요)
SELECT
    CONCAT('CWMA-', GI_NO)   AS WANTED_AUTH_NO,
    '건설공제회'              AS SOURCE,
    '민간'                    AS SOURCE_TYPE,
    COM_NAME AS COMPANY, GI_SUBJECT AS TITLE, PART_NO_INFO AS JOBS_NM, GI_PART_NO_CD AS JOBS_CD,
    PASS_TYPE_INFO AS EMP_TP_NM, CAREER_INFO AS CAREER, EDU_CUTLINE_INFO AS MIN_EDUBG,
    PAY_INFO AS SAL_AMT, NULL AS SAL_TP_NM,
    AREA_INFO AS REGION,
    CASE WHEN GI_END_DATE REGEXP '^[0-9]{8}$'
         THEN CONCAT(SUBSTR(GI_END_DATE,1,4),'-',SUBSTR(GI_END_DATE,5,2),'-',SUBSTR(GI_END_DATE,7,2))
         ELSE GI_END_DATE END AS CLOSE_DT,
    NULL AS WANTED_INFO_URL, NULL AS BASIC_ADDR, NULL AS DETAIL_ADDR, '민간' AS INFO_SVC,
    -- TODO: jedut.tb_code 확보 후 아래 CASE WHEN 으로 교체
    GI_CAREER_CD AS JOB_CAREER_CD,
    GI_EDU_CUTLINE_CD AS JOB_ACDMCR_CD,
    GI_JOB_TYPE_CD AS JOB_EMP_TP_CD,
    AREA_CD AS JOB_AREA_CD,
    NULL AS JOBABA_CMMN_276_CD,
    NULL AS JOBABA_CMMN_274_CD,
    REG_DT, USE_YN, DEL_YN
FROM jwrki.tb_empmn_cwma_api
WHERE USE_YN = 'Y' AND DEL_YN = 'N'

UNION ALL

-- ④ KB굿잡 (민간 — 코드 없음, 텍스트만 존재)
SELECT
    CONCAT('KB-', GI_NO)     AS WANTED_AUTH_NO,
    'KB굿잡'                  AS SOURCE,
    '민간'                    AS SOURCE_TYPE,
    COM_NAME AS COMPANY, GI_SUBJECT AS TITLE, PART_NO_INFO AS JOBS_NM, NULL AS JOBS_CD,
    GI_JOB_TYPE_NM AS EMP_TP_NM, GI_CAREER_NM AS CAREER, GI_EDU_CUTLINE_NM AS MIN_EDUBG,
    PAY_INFO AS SAL_AMT, NULL AS SAL_TP_NM,
    AREA_INFO AS REGION,
    CASE WHEN GI_END_DATE REGEXP '^[0-9]{8}$'
         THEN CONCAT(SUBSTR(GI_END_DATE,1,4),'-',SUBSTR(GI_END_DATE,5,2),'-',SUBSTR(GI_END_DATE,7,2))
         ELSE GI_END_DATE END AS CLOSE_DT,
    NULL AS WANTED_INFO_URL, NULL AS BASIC_ADDR, NULL AS DETAIL_ADDR, '민간' AS INFO_SVC,
    -- TODO: 텍스트 역매핑 또는 jedut.tb_code LIKE 검색으로 구현
    NULL AS JOB_CAREER_CD,
    NULL AS JOB_ACDMCR_CD,
    NULL AS JOB_EMP_TP_CD,
    AREA_CD AS JOB_AREA_CD,
    NULL AS JOBABA_CMMN_276_CD,
    NULL AS JOBABA_CMMN_274_CD,
    REG_DT, USE_YN, DEL_YN
FROM jwrki.tb_empmn_kb_goobjob_api
WHERE USE_YN = 'Y' AND DEL_YN = 'N'

UNION ALL

-- ⑤ IBK 아이원잡 (민간 — 텍스트만 존재)
SELECT
    CONCAT('IBK-', JOB_ID)   AS WANTED_AUTH_NO,
    'IBK아이원잡'             AS SOURCE,
    '민간'                    AS SOURCE_TYPE,
    COM_NAME AS COMPANY, JOB_TITLE AS TITLE, JOB_TYPECOND AS JOBS_NM, NULL AS JOBS_CD,
    JOB_TYPECOND AS EMP_TP_NM, JOB_CAREERINFO AS CAREER, JOB_EDU AS MIN_EDUBG,
    NULL AS SAL_AMT, NULL AS SAL_TP_NM,
    JOB_AREA AS REGION,
    JOB_ENDDATE AS CLOSE_DT,
    NULL AS WANTED_INFO_URL, NULL AS BASIC_ADDR, NULL AS DETAIL_ADDR, '민간' AS INFO_SVC,
    NULL AS JOB_CAREER_CD, NULL AS JOB_ACDMCR_CD, NULL AS JOB_EMP_TP_CD, NULL AS JOB_AREA_CD,
    NULL AS JOBABA_CMMN_276_CD,
    NULL AS JOBABA_CMMN_274_CD,
    REG_DT, USE_YN, DEL_YN
FROM jwrki.tb_empmn_ionejob_api
WHERE USE_YN = 'Y' AND DEL_YN = 'N'

UNION ALL

-- ⑥ 잡코리아 기간제 (jedut 스키마)
SELECT
    CONCAT('JKR-', RCRIT_NO) AS WANTED_AUTH_NO,
    '잡코리아(기간제)'         AS SOURCE,
    '공공'                    AS SOURCE_TYPE,
    ORG_NM AS COMPANY, RCRIT_PBANCTTL AS TITLE, GI_JOB_TYPE AS JOBS_NM, NULL AS JOBS_CD,
    GI_JOB_TYPE AS EMP_TP_NM, GI_CAREER AS CAREER, GI_EDU_CUTLINE AS MIN_EDUBG,
    NULL AS SAL_AMT, NULL AS SAL_TP_NM,
    AREA_NM AS REGION,
    RCRIT_ENDDATE AS CLOSE_DT,
    NULL AS WANTED_INFO_URL, NULL AS BASIC_ADDR, NULL AS DETAIL_ADDR, '공공' AS INFO_SVC,
    NULL AS JOB_CAREER_CD, NULL AS JOB_ACDMCR_CD, NULL AS JOB_EMP_TP_CD, NULL AS JOB_AREA_CD,
    NULL AS JOBABA_CMMN_276_CD,
    NULL AS JOBABA_CMMN_274_CD,
    REG_DT, USE_YN, DEL_YN
FROM jedut.tb_recruit_jobkorea_api
WHERE USE_YN = 'Y' AND DEL_YN = 'N'

UNION ALL

-- ⑦ 잡아바 자체 채용정보 (jmmbi 스키마 — CAREER_CD/ACDMCR_CD/EMP_TP_CD 컬럼명 상이)
SELECT
    CONCAT('UNT-', EMPMN_NO) AS WANTED_AUTH_NO,
    '잡아바'                  AS SOURCE,
    '민간'                    AS SOURCE_TYPE,
    ORG_NM AS COMPANY, EMPMN_TTLT AS TITLE, JOB_NM AS JOBS_NM, JOB_CD AS JOBS_CD,
    EMP_TP_NM AS EMP_TP_NM, CAREER_NM AS CAREER, ACDMCR_NM AS MIN_EDUBG,
    NULL AS SAL_AMT, NULL AS SAL_TP_NM,
    AREA_NM AS REGION,
    CLOSE_DT AS CLOSE_DT,
    APPLY_URL AS WANTED_INFO_URL, NULL AS BASIC_ADDR, NULL AS DETAIL_ADDR, '민간' AS INFO_SVC,
    -- CAREER_CD / ACDMCR_CD / EMP_TP_CD 는 컬럼명은 다르나 값이 R코드인지 확인 필요
    CAREER_CD AS JOB_CAREER_CD,
    ACDMCR_CD AS JOB_ACDMCR_CD,
    EMP_TP_CD AS JOB_EMP_TP_CD,
    AREA_CD   AS JOB_AREA_CD,
    CASE
        WHEN JOB_CD REGEXP '^[0-9]+$' THEN LEFT(LPAD(JOB_CD, 6, '0'), 3)
        ELSE NULL
    END AS JOBABA_CMMN_276_CD,
    CASE
        WHEN JOB_CD REGEXP '^[0-9]+$' THEN LEFT(LPAD(JOB_CD, 6, '0'), 1)
        ELSE NULL
    END AS JOBABA_CMMN_274_CD,
    REG_DT, USE_YN, DEL_YN
FROM jmmbi.tb_ent_untact_empmn
WHERE USE_YN = 'Y' AND DEL_YN = 'N';

-- ============================================================
-- 배치/동기화 반영: 최종 v_job_posting은 VIEW가 아니라 조회용 물리 테이블로 사용
-- 흐름: source VIEW -> staging TABLE -> index -> atomic rename
-- ============================================================
DROP TABLE IF EXISTS v_job_posting_staging;

CREATE TABLE v_job_posting_staging AS
SELECT * FROM v_job_posting_source;

DROP VIEW v_job_posting_source;

ALTER TABLE v_job_posting_staging
    CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE INDEX idx_v_job_posting_auth_no ON v_job_posting_staging (WANTED_AUTH_NO);
CREATE INDEX idx_v_job_posting_reg_dt ON v_job_posting_staging (REG_DT);
CREATE INDEX idx_v_job_posting_close_dt ON v_job_posting_staging (CLOSE_DT, REG_DT);
CREATE INDEX idx_v_job_posting_source_type ON v_job_posting_staging (SOURCE_TYPE);
CREATE INDEX idx_v_job_posting_use_del ON v_job_posting_staging (USE_YN, DEL_YN);
CREATE INDEX idx_v_job_posting_list
    ON v_job_posting_staging (USE_YN, DEL_YN, SOURCE_TYPE, REG_DT);
CREATE INDEX idx_v_job_posting_pub_filters
    ON v_job_posting_staging (JOBABA_CMMN_276_CD, JOB_CAREER_CD, JOB_ACDMCR_CD, JOB_EMP_TP_CD);
CREATE INDEX idx_v_job_posting_prv_filters
    ON v_job_posting_staging (JOBABA_CMMN_274_CD, JOB_CAREER_CD, JOB_ACDMCR_CD, JOB_EMP_TP_CD);

SET @jobaba_map_object_type := (
    SELECT TABLE_TYPE
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'v_job_posting'
    LIMIT 1
);

DROP TABLE IF EXISTS v_job_posting_old;

SET @jobaba_map_drop_view_sql := CASE
    WHEN @jobaba_map_object_type = 'VIEW' THEN 'DROP VIEW v_job_posting'
    ELSE 'DO 0'
END;

PREPARE jobaba_map_drop_view_stmt FROM @jobaba_map_drop_view_sql;
EXECUTE jobaba_map_drop_view_stmt;
DEALLOCATE PREPARE jobaba_map_drop_view_stmt;

SET @jobaba_map_swap_sql := CASE
    WHEN @jobaba_map_object_type = 'BASE TABLE'
        THEN 'RENAME TABLE v_job_posting TO v_job_posting_old, v_job_posting_staging TO v_job_posting'
    ELSE 'RENAME TABLE v_job_posting_staging TO v_job_posting'
END;

PREPARE jobaba_map_swap_stmt FROM @jobaba_map_swap_sql;
EXECUTE jobaba_map_swap_stmt;
DEALLOCATE PREPARE jobaba_map_swap_stmt;

DROP TABLE IF EXISTS v_job_posting_old;
