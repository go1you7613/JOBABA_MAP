#!/usr/bin/env python3
"""Load latest 고용24 CSV into local tb_empmn_worknet_api via staging."""

from __future__ import annotations

import csv
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import List, Tuple


MYSQL = os.environ.get("MYSQL_BIN", "mysql")
DB_HOST = os.environ.get("JOBABA_DB_HOST", "127.0.0.1")
DB_PORT = os.environ.get("JOBABA_DB_PORT", "3306")
DB_USER = os.environ.get("JOBABA_DB_USER", "jobaba")
DB_PASSWORD = os.environ.get("JOBABA_DB_PASSWORD")
DB_NAME = os.environ.get("JOBABA_DB_NAME", "jobaba_map")

TABLE = "tb_empmn_worknet_api"
STAGING = "tb_empmn_worknet_api_staging"
PREV = "tb_empmn_worknet_api_prev"


def qident(name: str) -> str:
    return "`" + name.replace("`", "``") + "`"


def sql_string(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


def detect_csv(path: Path) -> Tuple[str, List[str], int]:
    for encoding in ("utf-8-sig", "cp949", "euc-kr"):
        try:
            with path.open("r", encoding=encoding, newline="") as f:
                reader = csv.reader(f)
                header = next(reader)
                row_count = sum(1 for _ in reader)
            return encoding, [col.strip() for col in header], row_count
        except UnicodeDecodeError:
            continue
    raise RuntimeError(f"unsupported CSV encoding: {path}")


def mysql_defaults_file() -> Path:
    if not DB_PASSWORD:
        raise RuntimeError("JOBABA_DB_PASSWORD is required")

    fd, path = tempfile.mkstemp(prefix="jobaba_worknet_", suffix=".cnf")
    os.close(fd)
    cnf = Path(path)
    cnf.write_text(
        "\n".join(
            [
                "[client]",
                f"host={DB_HOST}",
                f"port={DB_PORT}",
                f"user={DB_USER}",
                f"password={DB_PASSWORD}",
                f"database={DB_NAME}",
                "default-character-set=utf8mb4",
                "local-infile=1",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    cnf.chmod(0o600)
    return cnf


def run_mysql(defaults_file: Path, sql: str) -> str:
    proc = subprocess.run(
        [MYSQL, f"--defaults-extra-file={defaults_file}", "--local-infile=1", "-N", "-B", "-e", sql],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or f"mysql failed with code {proc.returncode}")
    return proc.stdout


def get_table_columns(defaults_file: Path) -> List[str]:
    sql = f"""
SELECT COLUMN_NAME
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = {sql_string(TABLE)}
ORDER BY ORDINAL_POSITION;
"""
    return [line.strip() for line in run_mysql(defaults_file, sql).splitlines() if line.strip()]


def convert_to_utf8_csv(source_path: Path, source_encoding: str, target_dir: Path) -> Path:
    target_path = target_dir / "worknet_utf8.csv"
    with source_path.open("r", encoding=source_encoding, newline="") as src:
        reader = csv.reader(src)
        with target_path.open("w", encoding="utf-8", newline="") as dst:
            writer = csv.writer(dst, lineterminator="\n")
            writer.writerows(reader)
    return target_path


def build_load_sql(csv_path: Path, header: List[str], row_count: int) -> str:
    variables = [f"@v{i}" for i in range(len(header))]
    assignments = []
    for idx, column in enumerate(header):
        value_expr = f"NULLIF(TRIM(TRAILING '\\r' FROM @v{idx}), '')"
        assignments.append(f"{qident(column)} = {value_expr}")

    return f"""
DROP TABLE IF EXISTS {qident(STAGING)};
CREATE TABLE {qident(STAGING)} LIKE {qident(TABLE)};

LOAD DATA LOCAL INFILE {sql_string(str(csv_path))}
INTO TABLE {qident(STAGING)}
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 LINES
({", ".join(variables)})
SET
{",\n".join(assignments)};

SET @loaded_count := (SELECT COUNT(*) FROM {qident(STAGING)});
SET @expected_count := {row_count};
SET @swap_sql := IF(
    @loaded_count = @expected_count,
    'RENAME TABLE {TABLE} TO {PREV}, {STAGING} TO {TABLE}',
    'DO 0'
);

DROP TABLE IF EXISTS {qident(PREV)};
PREPARE swap_stmt FROM @swap_sql;
EXECUTE swap_stmt;
DEALLOCATE PREPARE swap_stmt;

SELECT @expected_count AS expected_count,
       @loaded_count AS loaded_count,
       (SELECT COUNT(*) FROM {qident(TABLE)}) AS final_count;
"""


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: scripts/load_worknet_csv.py <worknet_csv_path>", file=sys.stderr)
        return 2

    csv_path = Path(sys.argv[1]).expanduser().resolve()
    if not csv_path.exists():
        raise RuntimeError(f"CSV not found: {csv_path}")

    encoding, header, row_count = detect_csv(csv_path)
    defaults_file = mysql_defaults_file()
    try:
        table_columns = get_table_columns(defaults_file)
        missing = [col for col in table_columns if col not in header]
        extra = [col for col in header if col not in table_columns]
        if missing or extra:
            raise RuntimeError(f"column mismatch: missing={missing}, extra={extra}")

        with tempfile.TemporaryDirectory(prefix="jobaba_worknet_csv_") as tmp:
            load_path = csv_path
            if encoding != "utf-8-sig":
                load_path = convert_to_utf8_csv(csv_path, encoding, Path(tmp))
            result = run_mysql(defaults_file, build_load_sql(load_path, header, row_count)).strip()
            print(f"encoding={encoding}")
            print(f"csv_rows={row_count}")
            print(result)
            return 0
    finally:
        defaults_file.unlink(missing_ok=True)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.CalledProcessError) as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
