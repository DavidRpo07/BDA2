# VALIDACIÓN SYNC VS ASYNC

## Paso 1: Conectarse al líder actual

docker exec -it pg_coord_primary psql -U postgres -d walletdb

docker exec -it pg_coord_replica1 env PGPASSWORD=postgrespass \
psql -U postgres -d walletdb -c "ALTER SYSTEM SET synchronous_commit = 'on';"

docker exec -it pg_coord_replica1 env PGPASSWORD=postgrespass \
psql -U postgres -d walletdb -c "ALTER SYSTEM SET synchronous_standby_names = '';"

docker exec -it pg_coord_replica1 env PGPASSWORD=postgrespass \
psql -U postgres -d walletdb -c "SELECT pg_reload_conf();"

docker exec -it pg_coord_replica1 env PGPASSWORD=postgrespass \
psql -U postgres -d walletdb -c "SHOW synchronous_commit; SHOW synchronous_standby_names; SELECT application_name, state, sync_state FROM pg_stat_replication ORDER BY application_name;"


---

## Paso 3: Verificar

SHOW synchronous_commit;
SHOW synchronous_standby_names;

SELECT application_name, sync_state FROM pg_stat_replication;

---

## Paso 4: Modo SYNC

docker exec -it pg_coord_replica1 env PGPASSWORD=postgrespass \
psql -U postgres -d walletdb -c "ALTER SYSTEM SET synchronous_commit = 'on';"

docker exec -it pg_coord_replica1 env PGPASSWORD=postgrespass \
psql -U postgres -d walletdb -c "ALTER SYSTEM SET synchronous_standby_names = 'FIRST 1 (\"pg-coord-1\", \"pg-coord-3\")';"

docker exec -it pg_coord_replica1 env PGPASSWORD=postgrespass \
psql -U postgres -d walletdb -c "SELECT pg_reload_conf();"

docker exec -it pg_coord_replica1 env PGPASSWORD=postgrespass \
psql -U postgres -d walletdb -c "SHOW synchronous_commit; SHOW synchronous_standby_names; SELECT application_name, state, sync_state FROM pg_stat_replication ORDER BY application_name;"


## Paso 5: Verificar

SELECT application_name, sync_state FROM pg_stat_replication;