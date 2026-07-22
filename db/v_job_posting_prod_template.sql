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

-- 이 템플릿은 운영 동기화 DB에서 컬럼이 확인된 다음 5개 원천만 통합합니다.
--   1. jwrki.tb_empmn_worknet_api
--   2. jwrki.tb_public_job
--   3. jwrki.tb_empmn_jobkorea_api
--   4. jwrki.tb_empmn_jobkorea_etc_api
--   5. jedut.tb_recruit_jobkorea_api
-- CWMA/KB굿잡/아이원잡/잡아바 자체공고는 실제 컬럼 매핑과 분류 기준을
-- 별도로 검증한 뒤 추가하십시오. 검증되지 않은 예시 SELECT는 운영 SQL에 두지 않습니다.

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

-- ② 공공데이터포털 공공채용 (원천 자체가 공공 전용)
-- 사업자번호 주소가 없으면 첫 번째 근무지역 코드명을 BASIC_ADDR로 사용합니다.
-- 이 경우 좌표는 기관 본사가 아니라 공고의 대표 근무지역 중심점입니다.
SELECT
    CONCAT('PUB-', p.SEQ) AS WANTED_AUTH_NO,
    '공공데이터포털' AS SOURCE,
    '공공' AS SOURCE_TYPE,
    p.INST_NM AS COMPANY,
    p.TITLE,
    p.RCRUT_FLD_CDS AS JOBS_NM,
    p.JOBS_CD,
    NULL AS EMP_TP_NM,
    p.RCRUT_SE_CDS AS CAREER,
    p.ACBG_COND_CDS AS MIN_EDUBG,
    NULL AS SAL_AMT,
    NULL AS SAL_TP_NM,
    p.WORK_RGN_CDS AS REGION,
    DATE_FORMAT(p.END_DT, '%Y-%m-%d') AS CLOSE_DT,
    p.DTL_URL AS WANTED_INFO_URL,
    CASE
        WHEN LENGTH(TRIM(ent.HDQTR_KOR_ADRS)) > 0 THEN ent.HDQTR_KOR_ADRS
        WHEN LENGTH(TRIM(ent_info.BASIC_ADDR)) > 0 THEN ent_info.BASIC_ADDR
        WHEN LENGTH(TRIM(jedut.GET_CODE_NMS('CMMN_369', p.WORK_RGN_DTL_CDS))) > 0
            THEN SUBSTRING_INDEX(jedut.GET_CODE_NMS('CMMN_369', p.WORK_RGN_DTL_CDS), ',', 1)
        ELSE SUBSTRING_INDEX(jedut.GET_CODE_NMS('CMMN_368', p.WORK_RGN_CDS), ',', 1)
    END AS BASIC_ADDR,
    CASE
        WHEN LENGTH(TRIM(ent.HDQTR_KOR_DETAIL_ADRS)) > 0 THEN ent.HDQTR_KOR_DETAIL_ADRS
        ELSE ent_info.DETAIL_ADDR
    END AS DETAIL_ADDR,
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
FROM (
    SELECT
        pub.*,
        CONCAT_WS(',',
            CASE WHEN FIND_IN_SET('1', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) OR FIND_IN_SET('01', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600001' END,
            CASE WHEN FIND_IN_SET('2', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) OR FIND_IN_SET('02', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600002' END,
            CASE WHEN FIND_IN_SET('3', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) OR FIND_IN_SET('03', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600003' END,
            CASE WHEN FIND_IN_SET('4', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) OR FIND_IN_SET('04', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600004' END,
            CASE WHEN FIND_IN_SET('5', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) OR FIND_IN_SET('05', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600005' END,
            CASE WHEN FIND_IN_SET('6', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) OR FIND_IN_SET('06', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600006' END,
            CASE WHEN FIND_IN_SET('7', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) OR FIND_IN_SET('07', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600007' END,
            CASE WHEN FIND_IN_SET('8', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) OR FIND_IN_SET('08', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600008' END,
            CASE WHEN FIND_IN_SET('9', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) OR FIND_IN_SET('09', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600009' END,
            CASE WHEN FIND_IN_SET('10', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600010' END,
            CASE WHEN FIND_IN_SET('11', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600011' END,
            CASE WHEN FIND_IN_SET('12', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600012' END,
            CASE WHEN FIND_IN_SET('13', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600013' END,
            CASE WHEN FIND_IN_SET('14', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600014' END,
            CASE WHEN FIND_IN_SET('15', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600015' END,
            CASE WHEN FIND_IN_SET('16', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600016' END,
            CASE WHEN FIND_IN_SET('17', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600017' END,
            CASE WHEN FIND_IN_SET('18', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600018' END,
            CASE WHEN FIND_IN_SET('19', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600019' END,
            CASE WHEN FIND_IN_SET('20', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600020' END,
            CASE WHEN FIND_IN_SET('21', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600021' END,
            CASE WHEN FIND_IN_SET('22', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600022' END,
            CASE WHEN FIND_IN_SET('23', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600023' END,
            CASE WHEN FIND_IN_SET('24', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600024' END,
            CASE WHEN FIND_IN_SET('25', REPLACE(pub.RCRUT_FLD_CDS, ' ', '')) THEN 'R600025' END
        ) AS JOBS_CD
    FROM jwrki.tb_public_job pub
) p
LEFT JOIN jwrki.tb_ent_exclnc ent
  ON p.BIZ_REG_NO COLLATE utf8mb4_unicode_ci
   = ent.BIZRNO COLLATE utf8mb4_unicode_ci
LEFT JOIN (
    SELECT BIZRNO, BASIC_ADDR, DETAIL_ADDR
    FROM (
        SELECT
            REPLACE(BIZRNO, '-', '') AS BIZRNO,
            CASE
                WHEN LENGTH(TRIM(RDNMAD)) > 0 THEN RDNMAD
                ELSE ADRES
            END AS BASIC_ADDR,
            CASE
                WHEN LENGTH(TRIM(RDNMAD_DTL)) > 0 THEN RDNMAD_DTL
                ELSE ADRES_DTL
            END AS DETAIL_ADDR,
            ROW_NUMBER() OVER (
                PARTITION BY REPLACE(BIZRNO, '-', '')
                ORDER BY
                    CASE WHEN LENGTH(TRIM(RDNMAD)) > 0 THEN 0 ELSE 1 END,
                    COALESCE(UPD_DT, REG_DT) DESC,
                    SEQ DESC
            ) AS RN
        FROM jwrki.tb_ent_info
        WHERE USE_YN = 'Y'
          AND DEL_YN = 'N'
          AND BIZRNO IS NOT NULL
          AND LENGTH(TRIM(BIZRNO)) > 0
    ) ranked_ent_info
    WHERE RN = 1
) ent_info
  ON p.BIZ_REG_NO COLLATE utf8mb4_unicode_ci
   = ent_info.BIZRNO COLLATE utf8mb4_unicode_ci
WHERE p.USE_YN = 'Y' AND p.DEL_YN = 'N'

UNION ALL

-- ③ 잡코리아 일반 채용 (민간)
SELECT
    CONCAT('JK-', jk.GI_NO) AS WANTED_AUTH_NO,
    '잡코리아' AS SOURCE,
    '민간' AS SOURCE_TYPE,
    jk.COM_NAME AS COMPANY,
    jk.GI_SUBJECT AS TITLE,
    jk.PART_NO_INFO AS JOBS_NM,
    jk.GI_PART_NO_CD AS JOBS_CD,
    jk.JOB_TYPE_INFO AS EMP_TP_NM,
    jk.CAREER_INFO AS CAREER,
    jk.EDU_CUTLINE_INFO AS MIN_EDUBG,
    COALESCE(NULLIF(TRIM(jk.PAY_TERM_INFO), ''), jk.PAY_INFO) AS SAL_AMT,
    CASE
        WHEN NULLIF(TRIM(jk.PAY_TERM_INFO), '') IS NOT NULL THEN jk.PAY_INFO
        ELSE NULL
    END AS SAL_TP_NM,
    jk.AREA_INFO AS REGION,
    CASE WHEN jk.GI_END_DATE REGEXP '^[0-9]{8}$'
         THEN CONCAT(SUBSTR(jk.GI_END_DATE,1,4),'-',SUBSTR(jk.GI_END_DATE,5,2),'-',SUBSTR(jk.GI_END_DATE,7,2))
         ELSE jk.GI_END_DATE END AS CLOSE_DT,
    jk.JK_URL AS WANTED_INFO_URL,
    ent.HDQTR_KOR_ADRS AS BASIC_ADDR,
    ent.HDQTR_KOR_DETAIL_ADRS AS DETAIL_ADDR,
    '민간' AS INFO_SVC,
    jk.JOB_CAREER_CD,
    jk.JOB_ACDMCR_CD,
    jk.JOB_EMP_TP_CD,
    jk.JOB_AREA_CD,
    CASE WHEN jk.CL_CD REGEXP '^[0-9]+$' THEN LPAD(jk.CL_CD, 3, '0') ELSE NULL END AS JOBABA_CMMN_276_CD,
    CASE WHEN jk.CL_CD REGEXP '^[0-9]+$' THEN LEFT(LPAD(jk.CL_CD, 3, '0'), 1) ELSE NULL END AS JOBABA_CMMN_274_CD,
    jk.REG_DT,
    jk.USE_YN,
    jk.DEL_YN
FROM jwrki.tb_empmn_jobkorea_api jk
LEFT JOIN jwrki.tb_ent_exclnc ent
  ON jk.BIZ_NO COLLATE utf8mb4_unicode_ci
   = ent.BIZRNO COLLATE utf8mb4_unicode_ci
WHERE jk.USE_YN = 'Y' AND jk.DEL_YN = 'N'

UNION ALL

-- ④ 잡코리아 ETC 테마채용관 (민간)
-- COMPANY_TYPE은 공공/민간 코드가 아닙니다.
--   01=LG전자 협력관, 02=참 괜찮은 중소기업, 03=신성장기업관
-- GI_NO + COMPANY_TYPE이 복합키이므로 표준 식별자에도 두 값을 모두 포함합니다.
SELECT
    CONCAT('JKE-', etc.COMPANY_TYPE, '-', etc.GI_NO) AS WANTED_AUTH_NO,
    '잡코리아 ETC' AS SOURCE,
    '민간' AS SOURCE_TYPE,
    etc.COMPANY_NAME AS COMPANY,
    etc.GI_SUBJECT AS TITLE,
    etc.GI_PART_NO_NM AS JOBS_NM,
    etc.GI_PART_NO_CD AS JOBS_CD,
    etc.GI_JOB_TYPE_NM AS EMP_TP_NM,
    etc.GI_CAREER_NM AS CAREER,
    etc.GI_EDU_CUTLINE_NM AS MIN_EDUBG,
    etc.GI_PAY_TERM_NM AS SAL_AMT,
    CASE etc.GI_PAY_CD
        WHEN '1' THEN '연봉'
        WHEN '2' THEN '월급'
        WHEN '4' THEN '일급'
        WHEN '5' THEN '시급'
        WHEN '6' THEN '건별'
        ELSE NULL
    END AS SAL_TP_NM,
    etc.AREA_NM AS REGION,
    CASE WHEN etc.GI_END_DATE REGEXP '^[0-9]{8}$'
         THEN CONCAT(SUBSTR(etc.GI_END_DATE,1,4),'-',SUBSTR(etc.GI_END_DATE,5,2),'-',SUBSTR(etc.GI_END_DATE,7,2))
         ELSE etc.GI_END_DATE END AS CLOSE_DT,
    etc.JK_URL AS WANTED_INFO_URL,
    ent.HDQTR_KOR_ADRS AS BASIC_ADDR,
    ent.HDQTR_KOR_DETAIL_ADRS AS DETAIL_ADDR,
    '민간' AS INFO_SVC,
    (
        SELECT c.REF_KEY_1
        FROM jedut.tb_code c
        WHERE c.GRP_CD = 'CMMN_122'
          AND c.CMN_CD = etc.GI_CAREER_CD
        LIMIT 1
    ) AS JOB_CAREER_CD,
    (
        SELECT c.REF_KEY_1
        FROM jedut.tb_code c
        WHERE c.GRP_CD = 'CMMN_124'
          AND c.CMN_CD = etc.GI_EDU_CUTLINE_CD
        LIMIT 1
    ) AS JOB_ACDMCR_CD,
    (
        SELECT GROUP_CONCAT(c.REF_KEY_1 ORDER BY c.ORDR ASC)
        FROM jedut.tb_code c
        WHERE c.GRP_CD = 'CMMN_125'
          AND FIND_IN_SET(c.CMN_CD, etc.GI_JOB_TYPE_CD)
    ) AS JOB_EMP_TP_CD,
    etc.AREA_CD AS JOB_AREA_CD,
    (
        SELECT c.REF_KEY_1
        FROM jedut.tb_code c
        WHERE c.GRP_CD = 'JOBKO_02'
          AND c.CMN_CD = SUBSTRING_INDEX(etc.GI_PART_NO_CD, ',', 1)
        LIMIT 1
    ) AS JOBABA_CMMN_276_CD,
    LEFT((
        SELECT c.REF_KEY_1
        FROM jedut.tb_code c
        WHERE c.GRP_CD = 'JOBKO_02'
          AND c.CMN_CD = SUBSTRING_INDEX(etc.GI_PART_NO_CD, ',', 1)
        LIMIT 1
    ), 1) AS JOBABA_CMMN_274_CD,
    etc.REG_DT,
    etc.USE_YN,
    etc.DEL_YN
FROM jwrki.tb_empmn_jobkorea_etc_api etc
LEFT JOIN jwrki.tb_ent_exclnc ent
  ON etc.BIZ_NO COLLATE utf8mb4_unicode_ci
   = ent.BIZRNO COLLATE utf8mb4_unicode_ci
WHERE etc.USE_YN = 'Y' AND etc.DEL_YN = 'N'

UNION ALL

-- ⑤ 잡코리아 인턴 채용 (민간)
SELECT
    CONCAT('JKR-', r.GI_NO) AS WANTED_AUTH_NO,
    '잡코리아(인턴)' AS SOURCE,
    '민간' AS SOURCE_TYPE,
    r.C_NAME AS COMPANY,
    r.GI_SUBJECT AS TITLE,
    r.GI_PART_NO AS JOBS_NM,
    NULL AS JOBS_CD,
    r.GI_JOB_TYPE AS EMP_TP_NM,
    NULL AS CAREER,
    r.GI_EDU_CUTLINE AS MIN_EDUBG,
    NULL AS SAL_AMT,
    NULL AS SAL_TP_NM,
    r.AREACODE AS REGION,
    CASE WHEN r.GI_END_DATE REGEXP '^[0-9]{8}$'
         THEN CONCAT(SUBSTR(r.GI_END_DATE,1,4),'-',SUBSTR(r.GI_END_DATE,5,2),'-',SUBSTR(r.GI_END_DATE,7,2))
         ELSE r.GI_END_DATE END AS CLOSE_DT,
    r.JK_URL AS WANTED_INFO_URL,
    NULL AS BASIC_ADDR,
    NULL AS DETAIL_ADDR,
    '민간' AS INFO_SVC,
    NULL AS JOB_CAREER_CD,
    NULL AS JOB_ACDMCR_CD,
    NULL AS JOB_EMP_TP_CD,
    NULL AS JOB_AREA_CD,
    NULL AS JOBABA_CMMN_276_CD,
    NULL AS JOBABA_CMMN_274_CD,
    r.REG_DT,
    r.USE_YN,
    r.DEL_YN
FROM jedut.tb_recruit_jobkorea_api r
WHERE r.USE_YN = 'Y' AND r.DEL_YN = 'N';

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
