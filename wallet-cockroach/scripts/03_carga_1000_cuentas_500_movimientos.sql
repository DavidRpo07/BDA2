USE wallet;

-- =========================================================
-- 1) CREAR 1000 USUARIOS NUEVOS
-- =========================================================
INSERT INTO usuarios (nombre, email, pais)
SELECT
    'Usuario Masivo ' || gs.n::STRING AS nombre,
    'usuario.masivo.' || gs.n::STRING || '@wallet.com' AS email,
    CASE
        WHEN gs.n % 5 = 0 THEN 'Colombia'
        WHEN gs.n % 5 = 1 THEN 'México'
        WHEN gs.n % 5 = 2 THEN 'Argentina'
        WHEN gs.n % 5 = 3 THEN 'Chile'
        ELSE 'Perú'
    END AS pais
FROM generate_series(1, 1000) AS gs(n);

-- =========================================================
-- 2) CREAR 1000 CUENTAS NUEVAS
--    Una cuenta por cada usuario nuevo
-- =========================================================
INSERT INTO cuentas (id_usuario, moneda, saldo, estado)
SELECT
    u.id_usuario,
    CASE
        WHEN row_number() OVER (ORDER BY u.email) % 5 = 0 THEN 'COP'
        WHEN row_number() OVER (ORDER BY u.email) % 5 = 1 THEN 'MXN'
        WHEN row_number() OVER (ORDER BY u.email) % 5 = 2 THEN 'ARS'
        WHEN row_number() OVER (ORDER BY u.email) % 5 = 3 THEN 'CLP'
        ELSE 'PEN'
    END AS moneda,
    1000000.00::DECIMAL(18,2) AS saldo,
    'ACTIVA' AS estado
FROM usuarios u
WHERE u.email LIKE 'usuario.masivo.%@wallet.com';

-- =========================================================
-- 3) OPCIONAL: CREAR LÍMITES PARA LAS 1000 CUENTAS NUEVAS
--    Si no los necesitas, puedes borrar este bloque
-- =========================================================
INSERT INTO limites_cuenta (id_cuenta, monto_max_transferencia, monto_max_diario)
SELECT
    c.id_cuenta,
    500000.00::DECIMAL(18,2),
    2000000.00::DECIMAL(18,2)
FROM cuentas c
JOIN usuarios u ON c.id_usuario = u.id_usuario
WHERE u.email LIKE 'usuario.masivo.%@wallet.com';

-- =========================================================
-- 4) CREAR 500 MOVIMIENTOS POR CADA CUENTA NUEVA
--    Total esperado: 500,000 movimientos
-- =========================================================
INSERT INTO movimientos (id_cuenta, tipo_movimiento, monto, descripcion, fecha_movimiento)
SELECT
    c.id_cuenta,
    CASE
        WHEN random() > 0.5 THEN 'DEBITO'
        ELSE 'CREDITO'
    END AS tipo_movimiento,
    round(((random() * 990000) + 1000)::DECIMAL, 2) AS monto,
    'Movimiento masivo #' || gs.n::STRING AS descripcion,
    now() - (random() * INTERVAL '180 days') AS fecha_movimiento
FROM cuentas c
JOIN usuarios u ON c.id_usuario = u.id_usuario
CROSS JOIN generate_series(1, 500) AS gs(n)
WHERE u.email LIKE 'usuario.masivo.%@wallet.com';