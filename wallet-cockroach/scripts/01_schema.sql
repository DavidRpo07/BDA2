USE wallet;
DROP TABLE IF EXISTS auditoria_transferencias CASCADE;
DROP TABLE IF EXISTS movimientos CASCADE;
DROP TABLE IF EXISTS transferencias CASCADE;
DROP TABLE IF EXISTS limites_cuenta CASCADE;
DROP TABLE IF EXISTS cuentas CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;

CREATE TABLE usuarios (
  id_usuario        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre            TEXT NOT NULL,
  email             TEXT UNIQUE NOT NULL,
  pais              TEXT NOT NULL,
  fecha_registro    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE cuentas (
  id_cuenta         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_usuario        UUID NOT NULL,
  moneda            TEXT NOT NULL,
  saldo             DECIMAL(18,2) NOT NULL CHECK (saldo >= 0),
  estado            TEXT NOT NULL CHECK (estado IN ('ACTIVA', 'BLOQUEADA', 'CERRADA')),
  fecha_creacion    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT fk_cuentas_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);

CREATE TABLE transferencias (
  id_transferencia      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cuenta_origen         UUID NOT NULL,
  cuenta_destino        UUID NOT NULL,
  monto                 DECIMAL(18,2) NOT NULL CHECK (monto > 0),
  estado                TEXT NOT NULL CHECK (estado IN ('PENDIENTE', 'COMPLETADA', 'FALLIDA')),
  fecha_transferencia   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT fk_transferencias_origen
    FOREIGN KEY (cuenta_origen) REFERENCES cuentas(id_cuenta),
  CONSTRAINT fk_transferencias_destino
    FOREIGN KEY (cuenta_destino) REFERENCES cuentas(id_cuenta),
  CONSTRAINT chk_transferencias_distintas
    CHECK (cuenta_origen <> cuenta_destino)
);

CREATE TABLE limites_cuenta (
  id_cuenta                 UUID PRIMARY KEY,
  monto_max_transferencia   DECIMAL(18,2) NOT NULL CHECK (monto_max_transferencia > 0),
  monto_max_diario          DECIMAL(18,2) NOT NULL CHECK (monto_max_diario > 0),
  CONSTRAINT fk_limites_cuenta
    FOREIGN KEY (id_cuenta) REFERENCES cuentas(id_cuenta)
);

CREATE TABLE auditoria_transferencias (
  id_auditoria         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_transferencia     UUID NOT NULL,
  evento               TEXT NOT NULL,
  detalle              TEXT,
  fecha_evento         TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT fk_auditoria_transferencia
    FOREIGN KEY (id_transferencia) REFERENCES transferencias(id_transferencia)
);

CREATE TABLE movimientos (
  id_movimiento        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_cuenta            UUID NOT NULL,
  tipo_movimiento      TEXT NOT NULL CHECK (tipo_movimiento IN ('DEBITO', 'CREDITO')),
  monto                DECIMAL(18,2) NOT NULL CHECK (monto > 0),
  descripcion          TEXT,
  fecha_movimiento     TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT fk_movimientos_cuenta
    FOREIGN KEY (id_cuenta) REFERENCES cuentas(id_cuenta)
);