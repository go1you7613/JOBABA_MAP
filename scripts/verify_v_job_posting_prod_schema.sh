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

for source_table in \
  "jwrki.tb_empmn_worknet_api" \
  "jwrki.tb_public_job" \
  "jwrki.tb_empmn_jobkorea_api" \
  "jwrki.tb_empmn_jobkorea_etc_api" \
  "jedut.tb_recruit_jobkorea_api"; do
  if ! grep -Fq "${source_table}" "${JOBABA_PROD_SQL}"; then
    echo "required source is missing: ${source_table}" >&2
    exit 1
  fi
done

for protected_source in \
  "jwrki.tb_empmn_worknet_api" \
  "jwrki.tb_public_job" \
  "jwrki.tb_empmn_jobkorea_api" \
  "jwrki.tb_empmn_jobkorea_etc_api" \
  "jwrki.tb_ent_exclnc" \
  "jwrki.tb_ent_info" \
  "jedut.tb_recruit_jobkorea_api" \
  "jedut.tb_code"; do
  protected_pattern="${protected_source//./\\.}"
  if grep -Eiq "^[[:space:]]*(INSERT[[:space:]]+INTO|UPDATE|DELETE[[:space:]]+FROM|ALTER[[:space:]]+TABLE|DROP[[:space:]]+(TABLE|VIEW)|TRUNCATE[[:space:]]+TABLE|RENAME[[:space:]]+TABLE)[[:space:]]+${protected_pattern}([[:space:];]|$)" "${JOBABA_PROD_SQL}"; then
    echo "production SQL must not mutate source table: ${protected_source}" >&2
    exit 1
  fi
done

for excluded_source in \
  "tb_empmn_cwma_api" \
  "tb_empmn_kb_goobjob_api" \
  "tb_empmn_ionejob_api" \
  "tb_ent_untact_empmn"; do
  if grep -Eq "^[[:space:]]*FROM[[:space:]].*${excluded_source}" "${JOBABA_PROD_SQL}"; then
    echo "unverified source must stay excluded: ${excluded_source}" >&2
    exit 1
  fi
done

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
  /^CREATE OR REPLACE VIEW jwrki\.v_job_posting_source AS$/ {
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
