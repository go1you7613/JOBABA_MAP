-- ============================================================
-- 고용24 공공기관 공고 목록
-- ============================================================
-- 목적:
--   - 고용24 OpenAPI의 기업형태(coTp=04: 공공기관) 목록을 별도 보관한다.
--   - 고용24 상세 링크의 복합 식별자
--     WANTED_AUTH_NO + INFO_TYPE_CD + INFO_TYPE_GROUP 기준으로 보관한다.
--   - 고용24 원천 데이터는 WANTED_AUTH_NO와 INFO_TYPE_CD로 이 테이블과
--     매칭하여 매칭되면 공공, 매칭되지 않으면 민간으로 분류한다.
--   - HTML 화면 파싱 결과는 이 테이블에 적재하지 않는다.
-- ============================================================

CREATE TABLE IF NOT EXISTS tb_work24_public_job (
    WANTED_AUTH_NO  VARCHAR(50) NOT NULL COMMENT '고용24 공고번호',
    INFO_TYPE_CD    VARCHAR(50) NOT NULL COMMENT '정보제공처 코드',
    INFO_TYPE_GROUP VARCHAR(100) NOT NULL COMMENT '정보제공처 그룹',
    INST_NM         VARCHAR(200) NOT NULL COMMENT '기관명',
    INST_TYPE       CHAR(1) NOT NULL DEFAULT 'P' COMMENT '기관유형(P=공공)',
    PRIMARY KEY (WANTED_AUTH_NO, INFO_TYPE_CD, INFO_TYPE_GROUP),
    INDEX idx_work24_public_job_inst_type (INST_TYPE),
    INDEX idx_work24_public_job_source (INFO_TYPE_CD, INFO_TYPE_GROUP),
    INDEX idx_work24_public_job_inst_nm (INST_NM)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='고용24 공공기관 공고 목록';

ALTER TABLE tb_work24_public_job
    ADD COLUMN IF NOT EXISTS INFO_TYPE_CD VARCHAR(50) NOT NULL DEFAULT 'VALIDATION' COMMENT '정보제공처 코드' AFTER WANTED_AUTH_NO,
    ADD COLUMN IF NOT EXISTS INFO_TYPE_GROUP VARCHAR(100) NOT NULL DEFAULT 'tb_workinfoworknet' COMMENT '정보제공처 그룹' AFTER INFO_TYPE_CD;

SET @work24_public_pk_cols := (
    SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX)
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'tb_work24_public_job'
      AND INDEX_NAME = 'PRIMARY'
);

SET @work24_public_pk_sql := IF(
    @work24_public_pk_cols = 'WANTED_AUTH_NO,INFO_TYPE_CD,INFO_TYPE_GROUP',
    'DO 0',
    'ALTER TABLE tb_work24_public_job DROP PRIMARY KEY, ADD PRIMARY KEY (WANTED_AUTH_NO, INFO_TYPE_CD, INFO_TYPE_GROUP)'
);
PREPARE work24_public_pk_stmt FROM @work24_public_pk_sql;
EXECUTE work24_public_pk_stmt;
DEALLOCATE PREPARE work24_public_pk_stmt;

ALTER TABLE tb_work24_public_job
    ADD INDEX IF NOT EXISTS idx_work24_public_job_source (INFO_TYPE_CD, INFO_TYPE_GROUP);
