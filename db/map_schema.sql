-- ============================================================
-- JOBABA MAP - schema-only database objects
-- ============================================================
-- This file intentionally contains no seed, demo, or production data.
-- Apply view/table templates separately when integrating with the target DB.
-- ============================================================

CREATE TABLE IF NOT EXISTS jwrki.tb_empmn_map_coord (
    WANTED_AUTH_NO  VARCHAR(50)     NOT NULL COMMENT '공고번호',
    LAT             DECIMAL(18,15)  NULL     COMMENT '위도',
    LNG             DECIMAL(18,15)  NULL     COMMENT '경도',
    GEOCODE_YN      CHAR(1)         NOT NULL DEFAULT 'N' COMMENT '좌표변환완료여부',
    REG_DT          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일자',
    PRIMARY KEY (WANTED_AUTH_NO),
    INDEX IX_EMPMN_MAP_COORD_VIEWPORT (GEOCODE_YN, LAT, LNG, WANTED_AUTH_NO)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='채용공고 좌표 캐시';

CREATE TABLE IF NOT EXISTS jwrki.tb_jobcls_ncs_map (
    NCS_CD          VARCHAR(20) NOT NULL COMMENT 'NCS 코드(R6000xx)',
    JOBABA_GRP_CD  VARCHAR(20) NOT NULL COMMENT '잡아바 공통코드 그룹(CMMN_276)',
    JOBABA_CD      VARCHAR(20) NOT NULL COMMENT '잡아바 공통코드',
    USE_YN         CHAR(1)     NOT NULL DEFAULT 'Y' COMMENT '사용여부',
    REG_DT         DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일자',
    UPD_DT         DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일자',
    PRIMARY KEY (NCS_CD, JOBABA_GRP_CD, JOBABA_CD),
    INDEX IX_JOBCLS_NCS_MAP_JOBABA (JOBABA_GRP_CD, JOBABA_CD),
    INDEX IX_JOBCLS_NCS_MAP_NCS (NCS_CD)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='NCS-잡아바 직종 매핑';
