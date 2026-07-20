-- ============================================================
-- v_job_posting 표준 조회 객체 — 운영 원천 테이블 연결 템플릿
-- ============================================================
-- 목적      : 기존 운영 원천 테이블을 변경하지 않고 지도 서비스 조회 컬럼으로 변환
-- 적용 조건 : 개발팀이 실제 운영 스키마/컬럼과 분류 기준을 확인한 뒤 1회 적용
-- 적용 위치 : 지도 서비스가 조회하는 DB 스키마
-- 주의사항  :
--   1. 각 채널 테이블의 스키마명 (jwrki, jedut, jmmbi) 반드시 명시
--   2. JOB_ 컬럼이 없는 테이블은 jedut.tb_code JOIN 으로 R코드 변환 필요
--   3. WANTED_AUTH_NO 는 채널 간 중복 방지를 위해 접두사 부여
--      (예: JKE-xxx / CWMA-xxx / KB-xxx / IBK-xxx / JKR-xxx / UNT-xxx)
--   4. 이 파일은 원천 데이터 INSERT/UPDATE 배치를 대체하거나 수정하지 않음
--   5. DROP/DELETE/TRUNCATE/RENAME 및 staging/old 교체 로직을 포함하지 않음
--   6. 고용24 공공/민간 구분은 운영 원천의 확정된 INFO_SVC 코드로 조정 필요
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

-- !! 아래는 조회 계약 템플릿입니다. 실제 컬럼을 확인하지 않은 상태로 실행하지 마십시오. !!

CREATE OR REPLACE VIEW v_job_posting AS

-- ① 고용24
SELECT
    w.WANTED_AUTH_NO,
    '고용24' AS SOURCE,
    CASE
        WHEN w.INFO_SVC IN ('공공', '공공기관') THEN '공공'
        WHEN w.INFO_SVC = '민간' THEN '민간'
        ELSE NULL
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
WHERE w.USE_YN = 'Y' AND w.DEL_YN = 'N'

UNION ALL

-- ② 공공데이터포털 공공채용
SELECT
    CONCAT('PUB-', p.SEQ) AS WANTED_AUTH_NO,
    '공공데이터포털' AS SOURCE,
    '공공' AS SOURCE_TYPE,
    p.INST_NM AS COMPANY,
    p.TITLE,
    p.RCRUT_FLD_CDS AS JOBS_NM,
    p.RCRUT_FLD_CDS AS JOBS_CD,
    NULL AS EMP_TP_NM,
    p.RCRUT_SE_CDS AS CAREER,
    p.ACBG_COND_CDS AS MIN_EDUBG,
    NULL AS SAL_AMT,
    NULL AS SAL_TP_NM,
    p.WORK_RGN_CDS AS REGION,
    DATE_FORMAT(p.END_DT, '%Y-%m-%d') AS CLOSE_DT,
    p.DTL_URL AS WANTED_INFO_URL,
    NULL AS BASIC_ADDR,
    NULL AS DETAIL_ADDR,
    '공공' AS INFO_SVC,
    p.RCRUT_SE_CDS AS JOB_CAREER_CD,
    p.ACBG_COND_CDS AS JOB_ACDMCR_CD,
    p.EMP_FR_CDS AS JOB_EMP_TP_CD,
    p.WORK_RGN_CDS AS JOB_AREA_CD,
    NULL AS JOBABA_CMMN_276_CD,
    NULL AS JOBABA_CMMN_274_CD,
    p.REG_DT,
    p.USE_YN,
    p.DEL_YN
FROM jwrki.tb_public_job p
WHERE p.USE_YN = 'Y' AND p.DEL_YN = 'N'

UNION ALL

-- ③ 잡코리아 ETC (공공 — JOB_ 컬럼 있음)
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

-- ④ 건설공제회 (민간 — GI_CAREER_CD 등 원천코드 → jedut.tb_code 변환 필요)
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

-- ⑤ KB굿잡 (민간 — 코드 없음, 텍스트만 존재)
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

-- ⑥ IBK 아이원잡 (민간 — 텍스트만 존재)
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

-- ⑦ 잡코리아 기간제 (jedut 스키마)
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

-- ⑧ 잡아바 자체 채용정보 (jmmbi 스키마 — CAREER_CD/ACDMCR_CD/EMP_TP_CD 컬럼명 상이)
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
