#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

MYSQL_BIN="${MYSQL_BIN:-mysql}"
JOBABA_DB_HOST="${JOBABA_DB_HOST:-127.0.0.1}"
JOBABA_DB_PORT="${JOBABA_DB_PORT:-3306}"
JOBABA_DB_USER="${JOBABA_DB_USER:-jobaba}"
JOBABA_DB_NAME="${JOBABA_DB_NAME:-jobaba_map}"
JOBABA_SYNC_SQL="${JOBABA_SYNC_SQL:-${PROJECT_ROOT}/db/v_job_posting_local.sql}"
JOBABA_WORK24_PUBLIC_SCHEMA_SQL="${JOBABA_WORK24_PUBLIC_SCHEMA_SQL:-${PROJECT_ROOT}/db/work24_public_job_schema.sql}"
JOBABA_SCHEMA_ONLY="${JOBABA_SCHEMA_ONLY:-N}"

if [ "${1:-}" = "--schema-only" ]; then
  JOBABA_SCHEMA_ONLY="Y"
fi

: "${JOBABA_DB_PASSWORD:?JOBABA_DB_PASSWORD is required}"

if [ ! -f "${JOBABA_SYNC_SQL}" ]; then
  echo "SQL file not found: ${JOBABA_SYNC_SQL}" >&2
  exit 1
fi

MYSQL_CNF="$(mktemp)"
trap 'rm -f "${MYSQL_CNF}"' EXIT
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

echo "[sync] v_job_posting sync started: $(date '+%Y-%m-%d %H:%M:%S')"
echo "[sync] database=${JOBABA_DB_NAME} host=${JOBABA_DB_HOST}:${JOBABA_DB_PORT}"
echo "[sync] sql=${JOBABA_SYNC_SQL}"

if [ -f "${JOBABA_WORK24_PUBLIC_SCHEMA_SQL}" ]; then
  echo "[sync] applying work24 public job schema=${JOBABA_WORK24_PUBLIC_SCHEMA_SQL}"
  "${MYSQL_BIN}" --defaults-extra-file="${MYSQL_CNF}" < "${JOBABA_WORK24_PUBLIC_SCHEMA_SQL}"
fi

if [ "${JOBABA_SCHEMA_ONLY}" = "Y" ]; then
  echo "[sync] schema-only completed: $(date '+%Y-%m-%d %H:%M:%S')"
  exit 0
fi

"${MYSQL_BIN}" --defaults-extra-file="${MYSQL_CNF}" < "${JOBABA_SYNC_SQL}"

"${MYSQL_BIN}" --defaults-extra-file="${MYSQL_CNF}" --table --execute="
SELECT TABLE_NAME, TABLE_TYPE, TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME LIKE 'v_job_posting%'
ORDER BY TABLE_NAME;

SELECT COUNT(*) AS job_count
FROM v_job_posting;
"

echo "[sync] v_job_posting sync completed: $(date '+%Y-%m-%d %H:%M:%S')"
