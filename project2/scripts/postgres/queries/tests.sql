SELECT * FROM cuentas_dist;

EXPLAIN (ANALYZE, COSTS OFF)
SELECT *
FROM cuentas_dist
WHERE id_usuario = 4;

SELECT *
FROM cuentas_shard1
WHERE id_usuario = 4;

SELECT id_usuario, get_shard(id_usuario)
FROM usuarios
ORDER BY id_usuario;

EXPLAIN (ANALYZE, COSTS OFF)
SELECT u.nombre, c.id_cuenta, c.saldo
FROM usuarios u
JOIN cuentas_dist c ON u.id_usuario = c.id_usuario;

EXPLAIN (ANALYZE, COSTS OFF)
SELECT u.nombre, c.id_cuenta, c.saldo
FROM usuarios u
JOIN cuentas_shard1 c ON u.id_usuario = c.id_usuario
WHERE u.id_usuario = 4;

-- Routing --
SELECT id_usuario, get_shard(id_usuario)
FROM usuarios
ORDER BY id_usuario;

-- Insert distribuido automático
SELECT insert_cuenta_distribuida(1010, 10, 'COP', 500000, 'ACTIVA');

-- Verificación global
SELECT * FROM cuentas_dist WHERE id_usuario = 10;

-- Verificación directa
SELECT * FROM cuentas_shard1 WHERE id_usuario = 10;

-- Consulta dirigida por clave de partición
SELECT * FROM get_cuenta_por_usuario(4);
SELECT * FROM get_cuenta_por_usuario(5);
SELECT * FROM get_cuenta_por_usuario(6);

-- Comparación explain: global vs dirigida
EXPLAIN (ANALYZE, COSTS OFF)
SELECT *
FROM cuentas_dist
WHERE id_usuario = 4;

EXPLAIN (ANALYZE, COSTS OFF)
SELECT * FROM get_cuenta_por_usuario(4);