DROP TABLE IF EXISTS auditoria_transferencias CASCADE;
DROP TABLE IF EXISTS transferencias CASCADE;
DROP TABLE IF EXISTS limites_cuenta CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;

CREATE TABLE usuarios (
  id_usuario        BIGINT PRIMARY KEY,
  nombre            TEXT NOT NULL,
  email             TEXT UNIQUE NOT NULL,
  pais              TEXT NOT NULL,
  fecha_registro    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE transferencias (
  id_transferencia      BIGINT PRIMARY KEY,
  cuenta_origen         BIGINT NOT NULL,
  cuenta_destino        BIGINT NOT NULL,
  monto                 NUMERIC(18,2) NOT NULL CHECK (monto > 0),
  estado                TEXT NOT NULL CHECK (estado IN ('PENDIENTE', 'COMPLETADA', 'FALLIDA')),
  fecha_transferencia   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE limites_cuenta (
  id_cuenta                 BIGINT PRIMARY KEY,
  monto_max_transferencia   NUMERIC(18,2) NOT NULL CHECK (monto_max_transferencia > 0),
  monto_max_diario          NUMERIC(18,2) NOT NULL CHECK (monto_max_diario > 0)
);

CREATE TABLE auditoria_transferencias (
  id_auditoria         BIGINT PRIMARY KEY,
  id_transferencia     BIGINT NOT NULL,
  evento               TEXT NOT NULL,
  detalle              TEXT,
  fecha_evento         TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT fk_auditoria_transferencia
    FOREIGN KEY (id_transferencia)
    REFERENCES transferencias(id_transferencia)
    ON DELETE CASCADE
);

INSERT INTO usuarios (id_usuario, nombre, email, pais) VALUES
(1, 'Ana Torres', 'ana@example.com', 'CO'),
(2, 'Luis Rojas', 'luis@example.com', 'CO'),
(3, 'Marta Gomez', 'marta@example.com', 'MX');

INSERT INTO transferencias (id_transferencia, cuenta_origen, cuenta_destino, monto, estado) VALUES
(1, 1001, 2001, 100000, 'COMPLETADA');

INSERT INTO limites_cuenta (id_cuenta, monto_max_transferencia, monto_max_diario) VALUES
(1001, 2000000, 5000000),
(2001, 3000000, 6000000);

INSERT INTO auditoria_transferencias (id_auditoria, id_transferencia, evento, detalle) VALUES
(1, 1, 'CREADA', 'Transferencia inicial de prueba');