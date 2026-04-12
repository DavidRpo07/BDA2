# CONSULTAS DISTRIBUIDAS

## Paso 1: Conectarse al coordinator

docker exec -it pg_coord_primary psql -U admin -d walletdb

---

## Paso 2: Consulta global

SELECT * FROM cuentas_dist;

---

## Paso 3: Ver plan de ejecución

EXPLAIN ANALYZE
SELECT * FROM cuentas_dist WHERE id_usuario = 4;

---

## Paso 4: Join distribuido

EXPLAIN ANALYZE
SELECT u.nombre, c.id_cuenta, c.saldo
FROM usuarios u
JOIN cuentas_dist c ON u.id_usuario = c.id_usuario;

---

## Paso 5: Join optimizado

EXPLAIN ANALYZE
SELECT u.nombre, c.id_cuenta, c.saldo
FROM usuarios u
JOIN cuentas_shard1 c ON u.id_usuario = c.id_usuario
WHERE u.id_usuario = 4;