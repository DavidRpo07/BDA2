# VALIDACIÓN DE SHARDS

## Paso 1: Conectarse a cada shard

Shard 1:
docker exec -it pg_shard_1 psql -U admin -d walletdb

Shard 2:
docker exec -it pg_shard_2 psql -U admin -d walletdb

Shard 3:
docker exec -it pg_shard_3 psql -U admin -d walletdb

---

## Paso 2: Verificar cuentas

SELECT * FROM cuentas ORDER BY id_cuenta;

Esperado:
Cada shard debe tener solo sus cuentas correspondientes.

---

## Paso 3: Verificar movimientos

SELECT * FROM movimientos ORDER BY id_movimiento;

Esperado:
Los movimientos deben corresponder a las cuentas del shard.