USE wallet;

-- =========================================================
-- 1. USUARIOS
-- =========================================================
INSERT INTO usuarios (nombre, email, pais) VALUES
('Ana Gómez', 'ana.gomez@wallet.com', 'Colombia'),
('Luis Pérez', 'luis.perez@wallet.com', 'México'),
('María Ruiz', 'maria.ruiz@wallet.com', 'Argentina'),
('Carlos Díaz', 'carlos.diaz@wallet.com', 'Chile'),
('Sofía Torres', 'sofia.torres@wallet.com', 'Perú');

-- =========================================================
-- 2. CUENTAS
--    Una cuenta por usuario
-- =========================================================
INSERT INTO cuentas (id_usuario, moneda, saldo, estado)
SELECT id_usuario, 'COP', 1500000.00, 'ACTIVA'
FROM usuarios
WHERE email = 'ana.gomez@wallet.com';

INSERT INTO cuentas (id_usuario, moneda, saldo, estado)
SELECT id_usuario, 'MXN', 32000.00, 'ACTIVA'
FROM usuarios
WHERE email = 'luis.perez@wallet.com';

INSERT INTO cuentas (id_usuario, moneda, saldo, estado)
SELECT id_usuario, 'ARS', 850000.00, 'ACTIVA'
FROM usuarios
WHERE email = 'maria.ruiz@wallet.com';

INSERT INTO cuentas (id_usuario, moneda, saldo, estado)
SELECT id_usuario, 'CLP', 1200000.00, 'BLOQUEADA'
FROM usuarios
WHERE email = 'carlos.diaz@wallet.com';

INSERT INTO cuentas (id_usuario, moneda, saldo, estado)
SELECT id_usuario, 'PEN', 5400.00, 'ACTIVA'
FROM usuarios
WHERE email = 'sofia.torres@wallet.com';

-- =========================================================
-- 3. LIMITES_CUENTA
--    Un límite por cuenta
-- =========================================================
INSERT INTO limites_cuenta (id_cuenta, monto_max_transferencia, monto_max_diario)
SELECT c.id_cuenta, 500000.00, 2000000.00
FROM cuentas c
JOIN usuarios u ON c.id_usuario = u.id_usuario
WHERE u.email = 'ana.gomez@wallet.com';

INSERT INTO limites_cuenta (id_cuenta, monto_max_transferencia, monto_max_diario)
SELECT c.id_cuenta, 10000.00, 40000.00
FROM cuentas c
JOIN usuarios u ON c.id_usuario = u.id_usuario
WHERE u.email = 'luis.perez@wallet.com';

INSERT INTO limites_cuenta (id_cuenta, monto_max_transferencia, monto_max_diario)
SELECT c.id_cuenta, 200000.00, 700000.00
FROM cuentas c
JOIN usuarios u ON c.id_usuario = u.id_usuario
WHERE u.email = 'maria.ruiz@wallet.com';

INSERT INTO limites_cuenta (id_cuenta, monto_max_transferencia, monto_max_diario)
SELECT c.id_cuenta, 300000.00, 1000000.00
FROM cuentas c
JOIN usuarios u ON c.id_usuario = u.id_usuario
WHERE u.email = 'carlos.diaz@wallet.com';

INSERT INTO limites_cuenta (id_cuenta, monto_max_transferencia, monto_max_diario)
SELECT c.id_cuenta, 1500.00, 5000.00
FROM cuentas c
JOIN usuarios u ON c.id_usuario = u.id_usuario
WHERE u.email = 'sofia.torres@wallet.com';

-- =========================================================
-- 4. MOVIMIENTOS
-- =========================================================
INSERT INTO movimientos (id_cuenta, tipo_movimiento, monto, descripcion)
SELECT c.id_cuenta, 'CREDITO', 1500000.00, 'Depósito inicial'
FROM cuentas c
JOIN usuarios u ON c.id_usuario = u.id_usuario
WHERE u.email = 'ana.gomez@wallet.com';

INSERT INTO movimientos (id_cuenta, tipo_movimiento, monto, descripcion)
SELECT c.id_cuenta, 'CREDITO', 32000.00, 'Abono de nómina'
FROM cuentas c
JOIN usuarios u ON c.id_usuario = u.id_usuario
WHERE u.email = 'luis.perez@wallet.com';

INSERT INTO movimientos (id_cuenta, tipo_movimiento, monto, descripcion)
SELECT c.id_cuenta, 'DEBITO', 50000.00, 'Pago de servicio'
FROM cuentas c
JOIN usuarios u ON c.id_usuario = u.id_usuario
WHERE u.email = 'maria.ruiz@wallet.com';

INSERT INTO movimientos (id_cuenta, tipo_movimiento, monto, descripcion)
SELECT c.id_cuenta, 'DEBITO', 100000.00, 'Compra en comercio'
FROM cuentas c
JOIN usuarios u ON c.id_usuario = u.id_usuario
WHERE u.email = 'ana.gomez@wallet.com';

INSERT INTO movimientos (id_cuenta, tipo_movimiento, monto, descripcion)
SELECT c.id_cuenta, 'CREDITO', 5400.00, 'Recarga inicial'
FROM cuentas c
JOIN usuarios u ON c.id_usuario = u.id_usuario
WHERE u.email = 'sofia.torres@wallet.com';

-- =========================================================
-- 5. TRANSFERENCIAS
-- =========================================================
INSERT INTO transferencias (cuenta_origen, cuenta_destino, monto, estado)
SELECT 
    co.id_cuenta,
    cd.id_cuenta,
    120000.00,
    'COMPLETADA'
FROM cuentas co
JOIN usuarios uo ON co.id_usuario = uo.id_usuario
JOIN cuentas cd ON 1 = 1
JOIN usuarios ud ON cd.id_usuario = ud.id_usuario
WHERE uo.email = 'ana.gomez@wallet.com'
  AND ud.email = 'maria.ruiz@wallet.com';

INSERT INTO transferencias (cuenta_origen, cuenta_destino, monto, estado)
SELECT 
    co.id_cuenta,
    cd.id_cuenta,
    2500.00,
    'PENDIENTE'
FROM cuentas co
JOIN usuarios uo ON co.id_usuario = uo.id_usuario
JOIN cuentas cd ON 1 = 1
JOIN usuarios ud ON cd.id_usuario = ud.id_usuario
WHERE uo.email = 'luis.perez@wallet.com'
  AND ud.email = 'sofia.torres@wallet.com';

INSERT INTO transferencias (cuenta_origen, cuenta_destino, monto, estado)
SELECT 
    co.id_cuenta,
    cd.id_cuenta,
    80000.00,
    'FALLIDA'
FROM cuentas co
JOIN usuarios uo ON co.id_usuario = uo.id_usuario
JOIN cuentas cd ON 1 = 1
JOIN usuarios ud ON cd.id_usuario = ud.id_usuario
WHERE uo.email = 'maria.ruiz@wallet.com'
  AND ud.email = 'ana.gomez@wallet.com';

-- =========================================================
-- 6. AUDITORIA_TRANSFERENCIAS
-- =========================================================
INSERT INTO auditoria_transferencias (id_transferencia, evento, detalle)
SELECT id_transferencia, 'CREACION', 'Transferencia creada correctamente'
FROM transferencias
WHERE estado = 'COMPLETADA'
LIMIT 1;

INSERT INTO auditoria_transferencias (id_transferencia, evento, detalle)
SELECT id_transferencia, 'VALIDACION', 'Transferencia en espera de aprobación'
FROM transferencias
WHERE estado = 'PENDIENTE'
LIMIT 1;

INSERT INTO auditoria_transferencias (id_transferencia, evento, detalle)
SELECT id_transferencia, 'ERROR', 'Transferencia rechazada por validación de saldo o política'
FROM transferencias
WHERE estado = 'FALLIDA'
LIMIT 1;