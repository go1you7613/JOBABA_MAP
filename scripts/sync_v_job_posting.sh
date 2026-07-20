#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

MYSQL_BIN="${MYSQL_BIN:-mysql}"
JOBABA_DB_HOST="${JOBABA_DB_HOST:-127.0.0.1}"
JOBABA_DB_PORT="${JOBABA_DB_PORT:-3306}"
JOBABA_DB_USER="${JOBABA_DB_USER:-jobaba}"
JOBABA_DB_NAME="${JOBABA_DB_NAME:-jwrki}"
JOBABA_SYNC_SQL="${JOBABA_SYNC_SQL:-${PROJECT_ROOT}/db/v_job_posting_prod_template.sql}"
JOBABA_ALLOW_VIEW_MIGRATION="${JOBABA_ALLOW_VIEW_MIGRATION:-N}"
JOBABA_ALLOW_ZERO_WORK24_PUBLIC_MATCH="${JOBABA_ALLOW_ZERO_WORK24_PUBLIC_MATCH:-N}"

: "${JOBABA_DB_PASSWORD:?JOBABA_DB_PASSWORD is required}"

if [ "${JOBABA_DB_NAME}" != "jwrki" ]; then
  echo "JOBABA_DB_NAME must be jwrki because the application mapper is schema-qualified." >&2
  exit 1
fi

if [ ! -f "${JOBABA_SYNC_SQL}" ]; then
  echo "SQL file not found: ${JOBABA_SYNC_SQL}" >&2
  exit 1
fi

MYSQL_CNF="$(mktemp)"
LOCK_PIPE=""
LOCK_PID=""

cleanup_runtime() {
  if [ -n "${LOCK_PID}" ]; then
    kill "${LOCK_PID}" >/dev/null 2>&1 || true
    wait "${LOCK_PID}" >/dev/null 2>&1 || true
  fi
  if [ -n "${LOCK_PIPE}" ]; then
    rm -f "${LOCK_PIPE}"
  fi
  rm -f "${MYSQL_CNF}"
}

trap cleanup_runtime EXIT
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

mysql_value() {
  "${MYSQL_BIN}" --defaults-extra-file="${MYSQL_CNF}" --batch --skip-column-names --execute="$1"
}

cleanup_staging() {
  "${MYSQL_BIN}" --defaults-extra-file="${MYSQL_CNF}" --execute="
DROP TABLE IF EXISTS jwrki.v_job_posting_staging;
DROP VIEW IF EXISTS jwrki.v_job_posting_source;
" >/dev/null 2>&1 || true
}

LOCK_PIPE="$(mktemp -u "${TMPDIR:-/tmp}/jobaba-map-sync-lock.XXXXXX")"
mkfifo "${LOCK_PIPE}"
"${MYSQL_BIN}" --defaults-extra-file="${MYSQL_CNF}" \
  --batch --skip-column-names --silent --unbuffered \
  --execute="SELECT GET_LOCK('jobaba_map.v_job_posting.sync', 0); SELECT SLEEP(86400);" \
  > "${LOCK_PIPE}" &
LOCK_PID=$!

if ! IFS= read -r LOCK_RESULT < "${LOCK_PIPE}"; then
  echo "[sync] failed to acquire the database advisory lock." >&2
  exit 1
fi
rm -f "${LOCK_PIPE}"
LOCK_PIPE=""

if [ "${LOCK_RESULT}" != "1" ]; then
  echo "[sync] another v_job_posting sync is already running." >&2
  exit 1
fi

echo "[sync] v_job_posting staging started: $(date '+%Y-%m-%d %H:%M:%S')"
echo "[sync] database=${JOBABA_DB_NAME} host=${JOBABA_DB_HOST}:${JOBABA_DB_PORT}"
echo "[sync] sql=${JOBABA_SYNC_SQL}"

cleanup_staging

if ! "${MYSQL_BIN}" --defaults-extra-file="${MYSQL_CNF}" < "${JOBABA_SYNC_SQL}"; then
  cleanup_staging
  echo "[sync] staging build failed; current v_job_posting was preserved." >&2
  exit 1
fi

COLUMN_COUNT="$(mysql_value "
SELECT COUNT(*)
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'v_job_posting_staging';
")"
ROW_COUNT="$(mysql_value "SELECT COUNT(*) FROM jwrki.v_job_posting_staging;")"
NULL_ID_COUNT="$(mysql_value "
SELECT COUNT(*)
FROM jwrki.v_job_posting_staging
WHERE WANTED_AUTH_NO IS NULL OR TRIM(WANTED_AUTH_NO) = '';
")"
DUPLICATE_ID_COUNT="$(mysql_value "
SELECT COUNT(*)
FROM (
    SELECT WANTED_AUTH_NO
    FROM jwrki.v_job_posting_staging
    GROUP BY WANTED_AUTH_NO
    HAVING COUNT(*) > 1
) D;
")"
PUBLIC_PORTAL_COUNT="$(mysql_value "
SELECT COUNT(*)
FROM jwrki.v_job_posting_staging
WHERE SOURCE = '공공데이터포털'
  AND SOURCE_TYPE = '공공'
  AND INFO_SVC = '공공';
")"
PUBLIC_SOURCE_COUNT="$(mysql_value "
SELECT COUNT(*)
FROM jwrki.tb_public_job
WHERE USE_YN = 'Y' AND DEL_YN = 'N';
")"
WORKNET_SOURCE_COUNT="$(mysql_value "
SELECT COUNT(*)
FROM jwrki.tb_empmn_worknet_api
WHERE USE_YN = 'Y' AND DEL_YN = 'N';
")"
WORK24_PUBLIC_CONTRACT_COUNT="$(mysql_value "
SELECT COUNT(*)
FROM jwrki.tb_work24_public_job
WHERE INST_TYPE = 'P'
  AND INFO_TYPE_GROUP = 'tb_workinfoworknet';
")"
WORK24_PUBLIC_MATCH_COUNT="$(mysql_value "
SELECT COUNT(*)
FROM jwrki.v_job_posting_staging
WHERE SOURCE = '고용24'
  AND SOURCE_TYPE = '공공';
")"
JOBKOREA_PUBLIC_COUNT="$(mysql_value "
SELECT COUNT(*)
FROM jwrki.v_job_posting_staging
WHERE SOURCE LIKE '잡코리아%'
  AND (SOURCE_TYPE = '공공' OR INFO_SVC = '공공');
")"

WORK24_PUBLIC_VALID=1
if [ "${WORKNET_SOURCE_COUNT}" -gt 0 ] \
  && [ "${JOBABA_ALLOW_ZERO_WORK24_PUBLIC_MATCH}" != "Y" ] \
  && { [ "${WORK24_PUBLIC_CONTRACT_COUNT}" -le 0 ] || [ "${WORK24_PUBLIC_MATCH_COUNT}" -le 0 ]; }; then
  WORK24_PUBLIC_VALID=0
fi

if [ "${COLUMN_COUNT}" -ne 27 ] \
  || [ "${ROW_COUNT}" -le 0 ] \
  || [ "${NULL_ID_COUNT}" -ne 0 ] \
  || [ "${DUPLICATE_ID_COUNT}" -ne 0 ] \
  || [ "${PUBLIC_PORTAL_COUNT}" -ne "${PUBLIC_SOURCE_COUNT}" ] \
  || [ "${JOBKOREA_PUBLIC_COUNT}" -ne 0 ] \
  || [ "${WORK24_PUBLIC_VALID}" -ne 1 ]; then
  cleanup_staging
  echo "[sync] validation failed; current v_job_posting was preserved." >&2
  echo "[sync] columns=${COLUMN_COUNT} rows=${ROW_COUNT} null_ids=${NULL_ID_COUNT} duplicate_ids=${DUPLICATE_ID_COUNT}" >&2
  echo "[sync] public_portal=${PUBLIC_PORTAL_COUNT} public_source=${PUBLIC_SOURCE_COUNT} jobkorea_public=${JOBKOREA_PUBLIC_COUNT}" >&2
  echo "[sync] worknet=${WORKNET_SOURCE_COUNT} work24_contract=${WORK24_PUBLIC_CONTRACT_COUNT} work24_public_match=${WORK24_PUBLIC_MATCH_COUNT}" >&2
  if [ "${WORK24_PUBLIC_VALID}" -ne 1 ]; then
    echo "[sync] active Worknet rows require a populated public-job contract and at least one public match." >&2
  fi
  exit 1
fi

OBJECT_TYPE="$(mysql_value "
SELECT COALESCE(MAX(TABLE_TYPE), 'NONE')
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'v_job_posting';
")"

if [ "${OBJECT_TYPE}" = "VIEW" ] && [ "${JOBABA_ALLOW_VIEW_MIGRATION}" != "Y" ]; then
  cleanup_staging
  echo "[sync] existing v_job_posting is a VIEW." >&2
  echo "[sync] run the first conversion in a maintenance window with JOBABA_ALLOW_VIEW_MIGRATION=Y." >&2
  exit 1
fi

VIEW_BACKUP_TYPE="$(mysql_value "
SELECT COALESCE(MAX(TABLE_TYPE), 'NONE')
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'v_job_posting_view_backup';
")"

OLD_OBJECT_TYPE="$(mysql_value "
SELECT COALESCE(MAX(TABLE_TYPE), 'NONE')
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'v_job_posting_old';
")"

if [ "${VIEW_BACKUP_TYPE}" != "NONE" ] || [ "${OLD_OBJECT_TYPE}" != "NONE" ]; then
  cleanup_staging
  echo "[sync] a previous backup object remains; refusing to overwrite recovery data." >&2
  echo "[sync] old=${OLD_OBJECT_TYPE} view_backup=${VIEW_BACKUP_TYPE}" >&2
  exit 1
fi

if [ "${OBJECT_TYPE}" = "BASE TABLE" ]; then
  "${MYSQL_BIN}" --defaults-extra-file="${MYSQL_CNF}" --execute="
RENAME TABLE jwrki.v_job_posting TO jwrki.v_job_posting_old,
             jwrki.v_job_posting_staging TO jwrki.v_job_posting;
"
elif [ "${OBJECT_TYPE}" = "VIEW" ]; then
  "${MYSQL_BIN}" --defaults-extra-file="${MYSQL_CNF}" --execute="
RENAME TABLE jwrki.v_job_posting TO jwrki.v_job_posting_view_backup,
             jwrki.v_job_posting_staging TO jwrki.v_job_posting;
"
else
  "${MYSQL_BIN}" --defaults-extra-file="${MYSQL_CNF}" --execute="
RENAME TABLE jwrki.v_job_posting_staging TO jwrki.v_job_posting;
"
fi

FINAL_ROW_COUNT="$(mysql_value "SELECT COUNT(*) FROM jwrki.v_job_posting;")"

if [ "${FINAL_ROW_COUNT}" -ne "${ROW_COUNT}" ]; then
  "${MYSQL_BIN}" --defaults-extra-file="${MYSQL_CNF}" \
    --execute="DROP TABLE IF EXISTS jwrki.v_job_posting_failed;" || true
  if [ "${OBJECT_TYPE}" = "BASE TABLE" ]; then
    "${MYSQL_BIN}" --defaults-extra-file="${MYSQL_CNF}" --execute="
RENAME TABLE jwrki.v_job_posting TO jwrki.v_job_posting_failed,
             jwrki.v_job_posting_old TO jwrki.v_job_posting;
DROP TABLE jwrki.v_job_posting_failed;
" || true
  elif [ "${OBJECT_TYPE}" = "VIEW" ]; then
    "${MYSQL_BIN}" --defaults-extra-file="${MYSQL_CNF}" --execute="
RENAME TABLE jwrki.v_job_posting TO jwrki.v_job_posting_failed,
             jwrki.v_job_posting_view_backup TO jwrki.v_job_posting;
DROP TABLE jwrki.v_job_posting_failed;
" || true
  else
    "${MYSQL_BIN}" --defaults-extra-file="${MYSQL_CNF}" \
      --execute="DROP TABLE IF EXISTS jwrki.v_job_posting;" || true
  fi
  echo "[sync] post-swap validation failed; rollback was attempted." >&2
  exit 1
fi

"${MYSQL_BIN}" --defaults-extra-file="${MYSQL_CNF}" --execute="
DROP TABLE IF EXISTS jwrki.v_job_posting_old;
DROP VIEW IF EXISTS jwrki.v_job_posting_view_backup;
DROP VIEW IF EXISTS jwrki.v_job_posting_source;
"

echo "[sync] v_job_posting completed: $(date '+%Y-%m-%d %H:%M:%S')"
echo "[sync] rows=${FINAL_ROW_COUNT} public_portal=${PUBLIC_PORTAL_COUNT} jobkorea_public=${JOBKOREA_PUBLIC_COUNT}"
echo "[sync] worknet=${WORKNET_SOURCE_COUNT} work24_contract=${WORK24_PUBLIC_CONTRACT_COUNT} work24_public_match=${WORK24_PUBLIC_MATCH_COUNT}"
