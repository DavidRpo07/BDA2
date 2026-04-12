# VALIDACIÓN DEL COORDINATOR

## Paso 1: Conectarse al coordinator (primary actual)

docker exec -it pg_coord_primary psql -U admin -d walletdb

(si hubo failover usar replica1 o replica2 según el líder)

---

## Paso 2: Ver tablas locales

SELECT * FROM usuarios ORDER BY id_usuario;
SELECT * FROM transferencias ORDER BY id_transferencia;
SELECT * FROM limites_cuenta ORDER BY id_cuenta;

---

## Paso 3: Ver datos globales (FDW)

SELECT * FROM cuentas_dist ORDER BY id_cuenta;
SELECT * FROM movimientos_dist ORDER BY id_movimiento;

Esperado:
Debe traer datos de los 3 shards.