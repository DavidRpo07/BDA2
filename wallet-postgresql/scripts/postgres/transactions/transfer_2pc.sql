-- =====================================================
-- 2PC - TRANSFERENCIA DISTRIBUIDA ENTRE SHARDS
-- Contexto:
-- cuenta 1001 -> shard1
-- cuenta 2001 -> shard2
-- monto ejemplo: 100000
-- =====================================================


-- =====================================================
-- ESCENARIO 0: VERIFICACIÓN INICIAL
-- Ejecutar por separado en cada shard
-- =====================================================

-- En pg_shard_1
SELECT id_cuenta, id_usuario, saldo
FROM cuentas
WHERE id_cuenta = 1001;

-- En pg_shard_2
SELECT id_cuenta, id_usuario, saldo
FROM cuentas
WHERE id_cuenta = 2001;



-- =====================================================
-- ESCENARIO 1: CASO EXITOSO (COMMIT PREPARED EN AMBOS)
-- =====================================================

-- -------------------------
-- PASO 1: PREPARE EN SHARD 1
-- Ejecutar en pg_shard_1
-- -------------------------
BEGIN;

UPDATE cuentas
SET saldo = saldo - 100000
WHERE id_cuenta = 1001;

INSERT INTO movimientos (
  id_movimiento, id_cuenta, tipo_movimiento, monto, descripcion
)
VALUES (
  8002, 1001, 'DEBITO', 100000, 'Transferencia a cuenta 2001'
);

PREPARE TRANSACTION 'tx_ok_1001_2001';


-- -------------------------
-- PASO 2: PREPARE EN SHARD 2
-- Ejecutar en pg_shard_2
-- -------------------------
BEGIN;

UPDATE cuentas
SET saldo = saldo + 100000
WHERE id_cuenta = 2001;

INSERT INTO movimientos (
  id_movimiento, id_cuenta, tipo_movimiento, monto, descripcion
)
VALUES (
  9002, 2001, 'CREDITO', 100000, 'Transferencia recibida de cuenta 1001'
);

PREPARE TRANSACTION 'tx_ok_1001_2001';


-- -------------------------
-- PASO 3: REGISTRO EN COORDINADOR
-- Ejecutar en pg_coordinator
-- -------------------------
INSERT INTO transferencias (
  id_transferencia, cuenta_origen, cuenta_destino, monto, estado
)
VALUES (
  1, 1001, 2001, 100000, 'COMPLETADA'
);

INSERT INTO auditoria_transferencias (
  id_auditoria, id_transferencia, evento, detalle
)
VALUES
(1, 1, 'PREPARE_OK', 'Ambos shards preparados'),
(2, 1, 'COMMIT_GLOBAL', 'Transferencia confirmada con 2PC');


-- -------------------------
-- PASO 4: COMMIT DEFINITIVO
-- Ejecutar en pg_shard_1 y pg_shard_2
-- -------------------------
COMMIT PREPARED 'tx_ok_1001_2001';


-- =====================================================
-- VERIFICACIÓN DEL CASO EXITOSO
-- =====================================================

-- En pg_shard_1
SELECT id_cuenta, saldo
FROM cuentas
WHERE id_cuenta = 1001;

-- En pg_shard_2
SELECT id_cuenta, saldo
FROM cuentas
WHERE id_cuenta = 2001;

-- En pg_coordinator
SELECT * FROM transferencias ORDER BY id_transferencia;
SELECT * FROM auditoria_transferencias ORDER BY id_auditoria;



-- =====================================================
-- ESCENARIO 2: FALLA ANTES DE QUE TODOS HAGAN PREPARE
-- shard1 sí prepara, shard2 falla antes de prepare
-- entonces rollback prepared solo en shard1
-- =====================================================

-- -------------------------
-- PASO 1: PREPARE EN SHARD 1
-- Ejecutar en pg_shard_1
-- -------------------------
BEGIN;

UPDATE cuentas
SET saldo = saldo - 50000
WHERE id_cuenta = 1001;

INSERT INTO movimientos (
  id_movimiento, id_cuenta, tipo_movimiento, monto, descripcion
)
VALUES (
  8002, 1001, 'DEBITO', 50000, 'Transferencia fallida antes de prepare global'
);

PREPARE TRANSACTION 'tx_fail_before_prepare';


-- -------------------------
-- PASO 2: EN SHARD 2 SIMULAR ERROR
-- NO HACER PREPARE
-- por ejemplo: cuenta inválida o abortar manualmente
-- -------------------------


-- -------------------------
-- PASO 3: ABORTAR LO PREPARADO EN SHARD 1
-- Ejecutar en pg_shard_1
-- -------------------------
ROLLBACK PREPARED 'tx_fail_before_prepare';


-- -------------------------
-- PASO 4: REGISTRO EN COORDINADOR
-- Ejecutar en pg_coordinator
-- -------------------------
INSERT INTO transferencias (
  id_transferencia, cuenta_origen, cuenta_destino, monto, estado
)
VALUES (
  2, 1001, 2001, 50000, 'FALLIDA'
);

INSERT INTO auditoria_transferencias (
  id_auditoria, id_transferencia, evento, detalle
)
VALUES
(3, 2, 'FAIL_BEFORE_PREPARE', 'Shard 2 falló antes de PREPARE'),
(4, 2, 'ROLLBACK_GLOBAL', 'Rollback preparado ejecutado solo en shard 1');


-- =====================================================
-- VERIFICACIÓN ESCENARIO 2
-- =====================================================

-- En pg_shard_1
SELECT id_cuenta, saldo
FROM cuentas
WHERE id_cuenta = 1001;



-- =====================================================
-- ESCENARIO 3: FALLA DESPUÉS DE QUE TODOS HICIERON PREPARE
-- ambos shards preparados, luego aborta todo
-- =====================================================

-- -------------------------
-- PASO 1: PREPARE EN SHARD 1
-- Ejecutar en pg_shard_1
-- -------------------------
BEGIN;

UPDATE cuentas
SET saldo = saldo - 30000
WHERE id_cuenta = 1001;

INSERT INTO movimientos (
  id_movimiento, id_cuenta, tipo_movimiento, monto, descripcion
)
VALUES (
  8003, 1001, 'DEBITO', 30000, 'Transferencia abortada después del prepare'
);

PREPARE TRANSACTION 'tx_fail_after_prepare';


-- -------------------------
-- PASO 2: PREPARE EN SHARD 2
-- Ejecutar en pg_shard_2
-- -------------------------
BEGIN;

UPDATE cuentas
SET saldo = saldo + 30000
WHERE id_cuenta = 2001;

INSERT INTO movimientos (
  id_movimiento, id_cuenta, tipo_movimiento, monto, descripcion
)
VALUES (
  9003, 2001, 'CREDITO', 30000, 'Transferencia abortada después del prepare'
);

PREPARE TRANSACTION 'tx_fail_after_prepare';


-- -------------------------
-- PASO 3: FALLA / DECISIÓN DE ABORTAR
-- Ejecutar rollback en ambos shards
-- -------------------------
ROLLBACK PREPARED 'tx_fail_after_prepare';


-- -------------------------
-- PASO 4: REGISTRO EN COORDINADOR
-- Ejecutar en pg_coordinator
-- -------------------------
INSERT INTO transferencias (
  id_transferencia, cuenta_origen, cuenta_destino, monto, estado
)
VALUES (
  3, 1001, 2001, 30000, 'FALLIDA'
);

INSERT INTO auditoria_transferencias (
  id_auditoria, id_transferencia, evento, detalle
)
VALUES
(5, 3, 'FAIL_AFTER_PREPARE', 'Ambos shards alcanzaron PREPARE'),
(6, 3, 'ROLLBACK_GLOBAL', 'Rollback prepared ejecutado en ambos shards');


-- =====================================================
-- VERIFICACIÓN ESCENARIO 3
-- =====================================================

-- En pg_shard_1
SELECT id_cuenta, saldo
FROM cuentas
WHERE id_cuenta = 1001;

-- En pg_shard_2
SELECT id_cuenta, saldo
FROM cuentas
WHERE id_cuenta = 2001;



-- =====================================================
-- CONSULTA DE TRANSACCIONES PREPARADAS
-- Útil para demostrar bloqueo si el coordinador fallara
-- =====================================================

SELECT * FROM pg_prepared_xacts;