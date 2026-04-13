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
(2001, 2, 'COP', 2100000.00, 'ACTIVA'),
(2002, 5, 'USD', 3200.00, 'ACTIVA'),
(2003, 8, 'COP', 450000.00, 'ACTIVA');

INSERT INTO movimientos (id_movimiento, id_cuenta, tipo_movimiento, monto, descripcion) VALUES
(6001, 2001, 'CREDITO', 2100000.00, 'Saldo inicial'),
(6002, 2002, 'CREDITO', 3200.00, 'Saldo inicial'),
(6003, 2003, 'CREDITO', 450000.00, 'Saldo inicial');