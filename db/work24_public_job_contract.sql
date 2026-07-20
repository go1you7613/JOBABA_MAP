-- ============================================================
-- 고용24 공공기관 공고 분류 계약 예시
-- ============================================================
-- 이 테이블은 MAP이 고용24 API를 직접 수집하기 위한 원천 테이블이 아닙니다.
-- 실제 운영 객체의 생성·소유·적재는 개발팀의 기존 배치 영역입니다.
-- 개발팀의 기존 고용24 공공기관 목록 배치가 복합 식별자를 적재하고,
-- MAP은 v_job_posting 동기화 시 공공/민간 판정에 읽기 전용으로 사용합니다.
-- ============================================================

CREATE TABLE IF NOT EXISTS jwrki.tb_work24_public_job (
    WANTED_AUTH_NO  VARCHAR(50)  NOT NULL COMMENT '고용24 공고번호',
    INFO_TYPE_CD    VARCHAR(50)  NOT NULL COMMENT '정보제공처 코드',
    INFO_TYPE_GROUP VARCHAR(100) NOT NULL COMMENT '정보제공처 그룹',
    INST_NM         VARCHAR(200) NOT NULL COMMENT '기관명',
    INST_TYPE       CHAR(1)      NOT NULL DEFAULT 'P' COMMENT '기관유형(P=공공)',
    PRIMARY KEY (WANTED_AUTH_NO, INFO_TYPE_CD, INFO_TYPE_GROUP),
    INDEX IX_WORK24_PUBLIC_JOB_INST_TYPE (INST_TYPE),
    INDEX IX_WORK24_PUBLIC_JOB_SOURCE (INFO_TYPE_CD, INFO_TYPE_GROUP)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='고용24 공공기관 공고 분류 목록';
