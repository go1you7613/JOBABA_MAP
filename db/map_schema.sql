-- ============================================================
-- JOBABA MAP - schema-only database objects
-- ============================================================
-- This file intentionally contains no seed, demo, or production data.
-- Apply view/table templates separately when integrating with the target DB.
-- ============================================================

CREATE TABLE IF NOT EXISTS tb_empmn_map_coord (
    WANTED_AUTH_NO  VARCHAR(50)     NOT NULL COMMENT '공고번호',
    LAT             DECIMAL(18,15)  NULL     COMMENT '위도',
    LNG             DECIMAL(18,15)  NULL     COMMENT '경도',
    GEOCODE_YN      CHAR(1)         NOT NULL DEFAULT 'N' COMMENT '좌표변환완료여부',
    REG_DT          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일자',
    PRIMARY KEY (WANTED_AUTH_NO),
    INDEX IX_EMPMN_MAP_COORD_VIEWPORT (GEOCODE_YN, LAT, LNG, WANTED_AUTH_NO)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='채용공고 좌표 캐시';

CREATE TABLE IF NOT EXISTS tb_work24_public_job (
    WANTED_AUTH_NO  VARCHAR(50)  NOT NULL COMMENT '고용24 공고번호',
    INFO_TYPE_CD    VARCHAR(50)  NOT NULL COMMENT '정보제공처 코드',
    INFO_TYPE_GROUP VARCHAR(100) NOT NULL COMMENT '정보제공처 그룹',
    INST_NM         VARCHAR(200) NOT NULL COMMENT '기관명',
    INST_TYPE       CHAR(1)      NOT NULL DEFAULT 'P' COMMENT '기관유형(P=공공)',
    PRIMARY KEY (WANTED_AUTH_NO, INFO_TYPE_CD, INFO_TYPE_GROUP),
    INDEX idx_work24_public_job_inst_type (INST_TYPE),
    INDEX idx_work24_public_job_source (INFO_TYPE_CD, INFO_TYPE_GROUP),
    INDEX idx_work24_public_job_inst_nm (INST_NM)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='고용24 공공기관 공고 목록';

CREATE TABLE IF NOT EXISTS tb_jobcls_ncs_map (
    NCS_CD          VARCHAR(20) NOT NULL COMMENT 'NCS 코드(R6000xx)',
    JOBABA_GRP_CD  VARCHAR(20) NOT NULL COMMENT '잡아바 공통코드 그룹(CMMN_276)',
    JOBABA_CD      VARCHAR(20) NOT NULL COMMENT '잡아바 공통코드',
    USE_YN         CHAR(1)     NOT NULL DEFAULT 'Y' COMMENT '사용여부',
    REG_DT         DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일자',
    UPD_DT         DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일자',
    PRIMARY KEY (NCS_CD, JOBABA_GRP_CD, JOBABA_CD),
    INDEX IX_JOBCLS_NCS_MAP_JOBABA (JOBABA_GRP_CD, JOBABA_CD),
    INDEX IX_JOBCLS_NCS_MAP_NCS (NCS_CD)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='NCS-잡아바 직종 매핑';

-- Local standalone development only.
-- Existing JOBABA integration should use the source recruitment tables already
-- present in the target DB and the v_job_posting production template.
CREATE TABLE IF NOT EXISTS tb_empmn_worknet_api (
    WANTED_AUTH_NO  VARCHAR(50)  NOT NULL COMMENT '공고번호(PK)',
    COMPANY         VARCHAR(200) NULL     COMMENT '회사명',
    TITLE           LONGTEXT     NULL     COMMENT '공고제목',
    JOBS_NM         TEXT         NULL     COMMENT '직무명',
    JOBS_CD         VARCHAR(20)  NULL     COMMENT '직종코드',
    SAL_TP_NM       VARCHAR(50)  NULL     COMMENT '임금유형명',
    SAL_AMT         VARCHAR(50)  NULL     COMMENT '임금',
    REGION          TEXT         NULL     COMMENT '지역',
    REGION_CD       VARCHAR(10)  NULL     COMMENT '지역코드',
    MIN_EDUBG       VARCHAR(50)  NULL     COMMENT '최소학력',
    MIN_EDUBG_CD    VARCHAR(10)  NULL     COMMENT '최소학력코드',
    CAREER          VARCHAR(50)  NULL     COMMENT '경력',
    CAREER_CD       VARCHAR(10)  NULL     COMMENT '경력코드',
    EMP_TP_NM       VARCHAR(100) NULL     COMMENT '고용형태명',
    EMP_TP_CD       VARCHAR(50)  NULL     COMMENT '고용형태코드',
    WANTED_REG_DT   VARCHAR(10)  NULL     COMMENT '등록일',
    CLOSE_DT        VARCHAR(50)  NULL     COMMENT '마감일',
    WANTED_INFO_URL TEXT         NULL     COMMENT '공고URL',
    BASIC_ADDR      TEXT         NULL     COMMENT '기본주소',
    DETAIL_ADDR     TEXT         NULL     COMMENT '상세주소',
    INFO_SVC        VARCHAR(50)  NULL     COMMENT '서비스구분(공공/민간)',
    CL_CD           VARCHAR(10)  NULL     COMMENT '분류코드',
    BIZ_NO          VARCHAR(10)  NULL     COMMENT '사업자번호',
    REG_DT          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일자',
    UPD_DT          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    USE_YN          CHAR(1)      NOT NULL DEFAULT 'Y' COMMENT '사용여부',
    DEL_YN          CHAR(1)      NOT NULL DEFAULT 'N' COMMENT '삭제여부',
    PRIMARY KEY (WANTED_AUTH_NO)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='채용정보_워크넷_API';
