#!/bin/bash
set -euo pipefail

export PGPASSWORD="${POSTGRESQL_POSTGRES_PASSWORD}"

psql -v ON_ERROR_STOP=1 -U postgres -d "${POSTGRESQL_DATABASE}" -f /opt/bitnami/scripts/20_fdw_routing.sql
