#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

MYSQL_BIN="${MYSQL_BIN:-mysql}"
JOBABA_DB_HOST="${JOBABA_DB_HOST:-127.0.0.1}"
JOBABA_DB_PORT="${JOBABA_DB_PORT:-3306}"
JOBABA_DB_USER="${JOBABA_DB_USER:-jobaba}"
JOBABA_DB_NAME="${JOBABA_DB_NAME:-jobaba_map}"
JOBABA_VERIFY_SQL="${JOBABA_VERIFY_SQL:-${PROJECT_ROOT}/db/verify_work24_public_match_rate.sql}"

: "${JOBABA_DB_PASSWORD:?JOBABA_DB_PASSWORD is required}"

if [ ! -f "${JOBABA_VERIFY_SQL}" ]; then
  echo "SQL file not found: ${JOBABA_VERIFY_SQL}" >&2
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

echo "[verify] work24 public-job match-rate verification started: $(date '+%Y-%m-%d %H:%M:%S')"
echo "[verify] database=${JOBABA_DB_NAME} host=${JOBABA_DB_HOST}:${JOBABA_DB_PORT}"
echo "[verify] sql=${JOBABA_VERIFY_SQL}"

"${MYSQL_BIN}" --defaults-extra-file="${MYSQL_CNF}" --table < "${JOBABA_VERIFY_SQL}"

echo "[verify] work24 public-job match-rate verification completed: $(date '+%Y-%m-%d %H:%M:%S')"
