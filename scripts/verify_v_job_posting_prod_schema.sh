#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

MYSQL_BIN="${MYSQL_BIN:-mysql}"
JOBABA_DB_HOST="${JOBABA_DB_HOST:-127.0.0.1}"
JOBABA_DB_PORT="${JOBABA_DB_PORT:-3306}"
JOBABA_DB_USER="${JOBABA_DB_USER:-jobaba}"
JOBABA_DB_NAME="${JOBABA_DB_NAME:-jwrki}"
JOBABA_PROD_SQL="${JOBABA_PROD_SQL:-${PROJECT_ROOT}/db/v_job_posting_prod_template.sql}"

: "${JOBABA_DB_PASSWORD:?JOBABA_DB_PASSWORD is required}"

if [ ! -f "${JOBABA_PROD_SQL}" ]; then
  echo "SQL file not found: ${JOBABA_PROD_SQL}" >&2
  exit 1
fi

MYSQL_CNF="$(mktemp)"
VIEW_QUERY="$(mktemp)"
VERIFY_SQL="$(mktemp)"
trap 'rm -f "${MYSQL_CNF}" "${VIEW_QUERY}" "${VERIFY_SQL}"' EXIT
chmod 600 "${MYSQL_CNF}"

cat > "${MYSQL_CNF}" <<EOF
[client]
host=${JOBABA_DB_HOST}
port=${JOBABA_DB_PORT}
user=${JOBABA_DB_USER}
password=${JOBABA_DB_PASSWORD}
database=${JOBABA_DB_NAME}
default-character-set=utf8mb4
EOF

awk '
  /^CREATE OR REPLACE VIEW v_job_posting_source AS$/ {
    capture = 1
    next
  }
  capture && /^-- ============================================================/ {
    exit
  }
  capture {
    print
  }
' "${JOBABA_PROD_SQL}" > "${VIEW_QUERY}"

if [ ! -s "${VIEW_QUERY}" ]; then
  echo "v_job_posting_source query not found: ${JOBABA_PROD_SQL}" >&2
  exit 1
fi

{
  cat <<'SQL'
CREATE TEMPORARY TABLE tb_work24_public_job (
    WANTED_AUTH_NO VARCHAR(50) NOT NULL,
    INFO_TYPE_CD VARCHAR(50) NOT NULL,
    INFO_TYPE_GROUP VARCHAR(100) NOT NULL,
    INST_NM VARCHAR(200) NOT NULL,
    INST_TYPE CHAR(1) NOT NULL,
    PRIMARY KEY (WANTED_AUTH_NO, INFO_TYPE_CD, INFO_TYPE_GROUP)
);

CREATE TEMPORARY TABLE v_job_posting_verify AS
SELECT *
FROM (
SQL
  sed '/^[[:space:]]*$/d' "${VIEW_QUERY}" | sed '$s/;[[:space:]]*$//'
  cat <<'SQL'
) verified_source
WHERE 1 = 0;

SHOW COLUMNS FROM v_job_posting_verify;
SQL
} > "${VERIFY_SQL}"

EXPECTED_COLUMNS=$'WANTED_AUTH_NO\tSOURCE\tSOURCE_TYPE\tCOMPANY\tTITLE\tJOBS_NM\tJOBS_CD\tEMP_TP_NM\tCAREER\tMIN_EDUBG\tSAL_AMT\tSAL_TP_NM\tREGION\tCLOSE_DT\tWANTED_INFO_URL\tBASIC_ADDR\tDETAIL_ADDR\tINFO_SVC\tJOB_CAREER_CD\tJOB_ACDMCR_CD\tJOB_EMP_TP_CD\tJOB_AREA_CD\tJOBABA_CMMN_276_CD\tJOBABA_CMMN_274_CD\tREG_DT\tUSE_YN\tDEL_YN'
ACTUAL_COLUMNS="$(
  "${MYSQL_BIN}" --defaults-extra-file="${MYSQL_CNF}" --batch --skip-column-names < "${VERIFY_SQL}" \
    | awk -F '\t' '{print $1}' \
    | paste -sd $'\t' -
)"

if [ "${ACTUAL_COLUMNS}" != "${EXPECTED_COLUMNS}" ]; then
  echo "v_job_posting schema mismatch" >&2
  echo "expected: ${EXPECTED_COLUMNS}" >&2
  echo "actual:   ${ACTUAL_COLUMNS}" >&2
  exit 1
fi

echo "v_job_posting production schema verification passed (27 columns)."
