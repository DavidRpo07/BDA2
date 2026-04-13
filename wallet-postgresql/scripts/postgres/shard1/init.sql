DROP TABLE IF EXISTS movimientos;
DROP TABLE IF EXISTS cuentas;

CREATE TABLE cuentas (
  id_cuenta       BIGINT PRIMARY KEY,
  id_usuario      BIGINT NOT NULL,
  moneda          TEXT NOT NULL,
  saldo           NUMERIC(18,2) NOT NULL CHECK (saldo >= 0),
  estado          TEXT NOT NULL CHECK (estado IN ('ACTIVA', 'BLOQUEADA', 'CERRADA')),
  fecha_creacion  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE movimientos (
  id_movimiento     BIGINT PRIMARY KEY,
  id_cuenta         BIGINT NOT NULL,
  tipo_movimiento   TEXT NOT NULL CHECK (tipo_movimiento IN ('DEBITO', 'CREDITO')),
  monto             NUMERIC(18,2) NOT NULL CHECK (monto > 0),
  descripcion       TEXT,
  fecha_movimiento  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT fk_movimientos_cuenta
    FOREIGN KEY (id_cuenta)
    REFERENCES cuentas(id_cuenta)
    ON DELETE CASCADE
);

INSERT INTO cuentas (id_cuenta, id_usuario, moneda, saldo, estado) VALUES
(1001, 1, 'COP', 1500000.00, 'ACTIVA'),
(1002, 4, 'COP', 980000.00, 'ACTIVA'),
(1003, 7, 'USD', 1200.00, 'ACTIVA');

INSERT INTO movimientos (id_movimiento, id_cuenta, tipo_movimiento, monto, descripcion) VALUES
(5001, 1001, 'CREDITO', 1500000.00, 'Saldo inicial'),
(5002, 1002, 'CREDITO', 980000.00, 'Saldo inicial'),
(5003, 1003, 'CREDITO', 1200.00, 'Saldo inicial');