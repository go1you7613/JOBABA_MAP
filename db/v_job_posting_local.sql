-- ============================================================
-- v_job_posting 표준 조회 객체 — 로컬 개발 환경 (jobaba_map 스키마)
-- ============================================================
-- 목적 : 채널별 테이블을 단일 인터페이스로 추상화
--        MapMapper.xml 은 항상 v_job_posting 객체만 참조
-- 전환 : 운영 반영 시 v_job_posting_prod_template.sql 참조
--        운영에서는 실시간 VIEW보다 인덱스가 있는 물리 테이블/동기화 테이블 권장
-- 주의 : 아래 SELECT는 임시 소스 VIEW로 만든 뒤 v_job_posting_staging 테이블에 적재하고,
--        인덱스 생성 후 최종 v_job_posting 테이블로 교체한다.
-- ============================================================
-- 표준 컬럼 정의
-- WANTED_AUTH_NO : 공고 식별자 (worknet: PUB-xxx / jobkorea: JK-xxx)
-- SOURCE         : 채널명 (공공기관 | 잡코리아 | …)
-- SOURCE_TYPE    : 채널 구분 (공공 | 민간)
--                  고용24는 tb_work24_public_job의
--                  WANTED_AUTH_NO + INFO_TYPE_CD + INFO_TYPE_GROUP 매칭 기준으로
--                  매칭되면 공공, 미매칭이면 민간으로 분류한다.
-- JOB_CAREER_CD  : 공공=R2000 R코드 / 민간=GI_CAREER_CD 원천코드(1~4)
-- JOB_ACDMCR_CD  : 공공=R7000 R코드 / 민간=GI_EDU_CUTLINE_CD 원천코드(0~7)
-- JOB_EMP_TP_CD  : 공공=R1000 R코드 / 민간=GI_JOB_TYPE_CD 원천코드(1,2,3… 다중값 콤마구분)
-- JOB_AREA_CD    : 통합 지역코드 R3000
-- JOBABA_CMMN_276_CD : 잡아바 3차 직종코드
-- JOBABA_CMMN_274_CD : 잡아바 1차 직종코드
-- ============================================================

USE jobaba_map;

ALTER TABLE tb_empmn_map_coord
    CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE tb_jobcls_ncs_map
    CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE OR REPLACE VIEW v_job_posting_source AS

-- ① 고용24 / 공고번호+정보제공처 기준 공공기관 공고 목록 매칭
SELECT
    w.WANTED_AUTH_NO,
    '고용24' AS SOURCE,
    CASE
        WHEN wp.WANTED_AUTH_NO IS NOT NULL THEN '공공'
        ELSE '민간'
    END AS SOURCE_TYPE,
    w.COMPANY,
    w.TITLE,
    w.JOBS_NM,
    w.JOBS_CD,
    w.EMP_TP_NM,
    w.CAREER,
    w.MIN_EDUBG,
    w.SAL_AMT,
    w.SAL_TP_NM,
    w.REGION,
    w.CLOSE_DT,
    w.WANTED_INFO_URL,
    w.BASIC_ADDR,
    w.DETAIL_ADDR,
    w.INFO_SVC,
    w.JOB_CAREER_CD,
    w.JOB_ACDMCR_CD,
    w.JOB_EMP_TP_CD,
    w.JOB_AREA_CD,
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
    w.REG_DT,
    w.USE_YN,
    w.DEL_YN
FROM tb_empmn_worknet_api w
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

-- ② 공공데이터포털 공공일자리 (공공)
SELECT
    CONVERT(CONCAT('PUB-', p.SEQ) USING utf8mb4) COLLATE utf8mb4_unicode_ci AS WANTED_AUTH_NO,
    CONVERT('공공데이터포털' USING utf8mb4) COLLATE utf8mb4_unicode_ci AS SOURCE,
    CONVERT('공공' USING utf8mb4) COLLATE utf8mb4_unicode_ci AS SOURCE_TYPE,
    CONVERT(p.INST_NM USING utf8mb4) COLLATE utf8mb4_unicode_ci AS COMPANY,
    CONVERT(p.TITLE USING utf8mb4) COLLATE utf8mb4_unicode_ci AS TITLE,
    CONVERT(p.RCRUT_FLD_CDS USING utf8mb4) COLLATE utf8mb4_unicode_ci AS JOBS_NM,
    CONVERT(p.JOBS_CD USING utf8mb4) COLLATE utf8mb4_unicode_ci AS JOBS_CD,
    NULL AS EMP_TP_NM,
    CONVERT(p.RCRUT_SE_CDS USING utf8mb4) COLLATE utf8mb4_unicode_ci AS CAREER,
    CONVERT(p.ACBG_COND_CDS USING utf8mb4) COLLATE utf8mb4_unicode_ci AS MIN_EDUBG,
    NULL AS SAL_AMT,
    NULL AS SAL_TP_NM,
    CONVERT(p.WORK_RGN_CDS USING utf8mb4) COLLATE utf8mb4_unicode_ci AS REGION,
    CONVERT(DATE_FORMAT(p.END_DT, '%Y-%m-%d') USING utf8mb4) COLLATE utf8mb4_unicode_ci AS CLOSE_DT,
    CONVERT(p.DTL_URL USING utf8mb4) COLLATE utf8mb4_unicode_ci AS WANTED_INFO_URL,
    CONVERT(ent.HDQTR_KOR_ADRS USING utf8mb4) COLLATE utf8mb4_unicode_ci AS BASIC_ADDR,
    CONVERT(ent.HDQTR_KOR_DETAIL_ADRS USING utf8mb4) COLLATE utf8mb4_unicode_ci AS DETAIL_ADDR,
    CONVERT('공공' USING utf8mb4) COLLATE utf8mb4_unicode_ci AS INFO_SVC,
    CONVERT(p.RCRUT_SE_CDS USING utf8mb4) COLLATE utf8mb4_unicode_ci AS JOB_CAREER_CD,
    CONVERT(p.ACBG_COND_CDS USING utf8mb4) COLLATE utf8mb4_unicode_ci AS JOB_ACDMCR_CD,
    CONVERT(p.EMP_FR_CDS USING utf8mb4) COLLATE utf8mb4_unicode_ci AS JOB_EMP_TP_CD,
    CONVERT(p.WORK_RGN_CDS USING utf8mb4) COLLATE utf8mb4_unicode_ci AS JOB_AREA_CD,
    NULL AS JOBABA_CMMN_276_CD,
    NULL AS JOBABA_CMMN_274_CD,
    p.REG_DT,
    CONVERT(p.USE_YN USING utf8mb4) COLLATE utf8mb4_unicode_ci AS USE_YN,
    CONVERT(p.DEL_YN USING utf8mb4) COLLATE utf8mb4_unicode_ci AS DEL_YN
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
    FROM tb_public_job pub
) p
LEFT JOIN tb_ent_exclnc ent
  ON REPLACE(p.BIZ_REG_NO, '-', '') COLLATE utf8mb4_unicode_ci
   = REPLACE(ent.BIZRNO, '-', '') COLLATE utf8mb4_unicode_ci
WHERE p.USE_YN = 'Y' AND p.DEL_YN = 'N'

UNION ALL

-- ③ 잡코리아 채용공고 (민간)
-- JOB_EMP_TP_CD : GI_JOB_TYPE_CD (1=정규직, 2=계약직, 3=인턴직, 6=프리랜서, 7=아르바이트, 다중값 콤마구분)
-- JOB_CAREER_CD : GI_CAREER_CD   (1=신입, 2=경력, 3=신입/경력, 4=관계없음)
-- JOB_ACDMCR_CD : GI_EDU_CUTLINE_CD (0=학력무관, 3=고졸, 4=대졸2~3, 5=대졸4, 7=박사)
SELECT
    CONCAT('JK-', jk.GI_NO) AS WANTED_AUTH_NO,
    '잡코리아'              AS SOURCE,
    '민간'                  AS SOURCE_TYPE,
    jk.COM_NAME             AS COMPANY,
    jk.GI_SUBJECT           AS TITLE,
    jk.PART_NO_INFO         AS JOBS_NM,
    jk.GI_PART_NO_CD        AS JOBS_CD,
    jk.JOB_TYPE_INFO        AS EMP_TP_NM,
    jk.CAREER_INFO          AS CAREER,
    jk.EDU_CUTLINE_INFO     AS MIN_EDUBG,
    jk.PAY_INFO             AS SAL_AMT,
    NULL                    AS SAL_TP_NM,
    jk.AREA_INFO            AS REGION,
    CASE WHEN jk.GI_END_DATE REGEXP '^[0-9]{8}$'
         THEN CONCAT(SUBSTR(jk.GI_END_DATE,1,4),'-',SUBSTR(jk.GI_END_DATE,5,2),'-',SUBSTR(jk.GI_END_DATE,7,2))
         ELSE jk.GI_END_DATE
    END                     AS CLOSE_DT,
    jk.JK_URL               AS WANTED_INFO_URL,
    CONVERT(ent.HDQTR_KOR_ADRS USING utf8mb4) COLLATE utf8mb4_unicode_ci AS BASIC_ADDR,
    CONVERT(ent.HDQTR_KOR_DETAIL_ADRS USING utf8mb4) COLLATE utf8mb4_unicode_ci AS DETAIL_ADDR,
    '민간'                  AS INFO_SVC,
    jk.GI_CAREER_CD         AS JOB_CAREER_CD,
    jk.GI_EDU_CUTLINE_CD    AS JOB_ACDMCR_CD,
    jk.GI_JOB_TYPE_CD       AS JOB_EMP_TP_CD,
    jk.JOB_AREA_CD,
    CASE
        WHEN jk.CL_CD REGEXP '^[0-9]+$' THEN LPAD(jk.CL_CD, 3, '0')
        ELSE NULL
    END                     AS JOBABA_CMMN_276_CD,
    CASE
        WHEN jk.CL_CD REGEXP '^[0-9]+$' THEN LEFT(LPAD(jk.CL_CD, 3, '0'), 1)
        ELSE NULL
    END                     AS JOBABA_CMMN_274_CD,
    jk.REG_DT,
    jk.USE_YN,
    jk.DEL_YN
FROM tb_empmn_jobkorea_api jk
LEFT JOIN tb_ent_exclnc ent
  ON REPLACE(jk.BIZ_NO, '-', '') COLLATE utf8mb4_unicode_ci
   = REPLACE(ent.BIZRNO, '-', '') COLLATE utf8mb4_unicode_ci
WHERE jk.USE_YN = 'Y' AND jk.DEL_YN = 'N';

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
