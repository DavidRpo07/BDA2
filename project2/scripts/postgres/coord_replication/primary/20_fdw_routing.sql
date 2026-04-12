CREATE EXTENSION IF NOT EXISTS postgres_fdw;

DROP SERVER IF EXISTS shard1_srv CASCADE;
DROP SERVER IF EXISTS shard2_srv CASCADE;
DROP SERVER IF EXISTS shard3_srv CASCADE;

CREATE SERVER shard1_srv
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'pg_shard_1', port '5432', dbname 'walletdb');

CREATE SERVER shard2_srv
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'pg_shard_2', port '5432', dbname 'walletdb');

CREATE SERVER shard3_srv
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'pg_shard_3', port '5432', dbname 'walletdb');

DROP USER MAPPING IF EXISTS FOR admin SERVER shard1_srv;
DROP USER MAPPING IF EXISTS FOR admin SERVER shard2_srv;
DROP USER MAPPING IF EXISTS FOR admin SERVER shard3_srv;
DROP USER MAPPING IF EXISTS FOR postgres SERVER shard1_srv;
DROP USER MAPPING IF EXISTS FOR postgres SERVER shard2_srv;
DROP USER MAPPING IF EXISTS FOR postgres SERVER shard3_srv;

CREATE USER MAPPING FOR admin
  SERVER shard1_srv
  OPTIONS (user 'admin', password 'admin');

CREATE USER MAPPING FOR admin
  SERVER shard2_srv
  OPTIONS (user 'admin', password 'admin');

CREATE USER MAPPING FOR admin
  SERVER shard3_srv
  OPTIONS (user 'admin', password 'admin');

CREATE USER MAPPING FOR postgres
  SERVER shard1_srv
  OPTIONS (user 'admin', password 'admin');

CREATE USER MAPPING FOR postgres
  SERVER shard2_srv
  OPTIONS (user 'admin', password 'admin');

CREATE USER MAPPING FOR postgres
  SERVER shard3_srv
  OPTIONS (user 'admin', password 'admin');

DROP FOREIGN TABLE IF EXISTS cuentas_shard1 CASCADE;
DROP FOREIGN TABLE IF EXISTS movimientos_shard1 CASCADE;
DROP FOREIGN TABLE IF EXISTS cuentas_shard2 CASCADE;
DROP FOREIGN TABLE IF EXISTS movimientos_shard2 CASCADE;
DROP FOREIGN TABLE IF EXISTS cuentas_shard3 CASCADE;
DROP FOREIGN TABLE IF EXISTS movimientos_shard3 CASCADE;

CREATE FOREIGN TABLE cuentas_shard1 (
  id_cuenta       BIGINT,
  id_usuario      BIGINT,
  moneda          TEXT,
  saldo           NUMERIC(18,2),
  estado          TEXT,
  fecha_creacion  TIMESTAMPTZ
)
SERVER shard1_srv
OPTIONS (schema_name 'public', table_name 'cuentas');

CREATE FOREIGN TABLE movimientos_shard1 (
  id_movimiento     BIGINT,
  id_cuenta         BIGINT,
  tipo_movimiento   TEXT,
  monto             NUMERIC(18,2),
  descripcion       TEXT,
  fecha_movimiento  TIMESTAMPTZ
)
SERVER shard1_srv
OPTIONS (schema_name 'public', table_name 'movimientos');

CREATE FOREIGN TABLE cuentas_shard2 (
  id_cuenta       BIGINT,
  id_usuario      BIGINT,
  moneda          TEXT,
  saldo           NUMERIC(18,2),
  estado          TEXT,
  fecha_creacion  TIMESTAMPTZ
)
SERVER shard2_srv
OPTIONS (schema_name 'public', table_name 'cuentas');

CREATE FOREIGN TABLE movimientos_shard2 (
  id_movimiento     BIGINT,
  id_cuenta         BIGINT,
  tipo_movimiento   TEXT,
  monto             NUMERIC(18,2),
  descripcion       TEXT,
  fecha_movimiento  TIMESTAMPTZ
)
SERVER shard2_srv
OPTIONS (schema_name 'public', table_name 'movimientos');

CREATE FOREIGN TABLE cuentas_shard3 (
  id_cuenta       BIGINT,
  id_usuario      BIGINT,
  moneda          TEXT,
  saldo           NUMERIC(18,2),
  estado          TEXT,
  fecha_creacion  TIMESTAMPTZ
)
SERVER shard3_srv
OPTIONS (schema_name 'public', table_name 'cuentas');

CREATE FOREIGN TABLE movimientos_shard3 (
  id_movimiento     BIGINT,
  id_cuenta         BIGINT,
  tipo_movimiento   TEXT,
  monto             NUMERIC(18,2),
  descripcion       TEXT,
  fecha_movimiento  TIMESTAMPTZ
)
SERVER shard3_srv
OPTIONS (schema_name 'public', table_name 'movimientos');

CREATE OR REPLACE VIEW cuentas_dist AS
SELECT * FROM cuentas_shard1
UNION ALL
SELECT * FROM cuentas_shard2
UNION ALL
SELECT * FROM cuentas_shard3;

CREATE OR REPLACE VIEW movimientos_dist AS
SELECT * FROM movimientos_shard1
UNION ALL
SELECT * FROM movimientos_shard2
UNION ALL
SELECT * FROM movimientos_shard3;

CREATE OR REPLACE FUNCTION get_shard(id_usuario BIGINT)
RETURNS TEXT AS $$
BEGIN
  IF id_usuario % 3 = 1 THEN
    RETURN 'pg_shard_1';
  ELSIF id_usuario % 3 = 2 THEN
    RETURN 'pg_shard_2';
  ELSE
    RETURN 'pg_shard_3';
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_cuenta_distribuida(
  p_id_cuenta BIGINT,
  p_id_usuario BIGINT,
  p_moneda TEXT,
  p_saldo NUMERIC,
  p_estado TEXT
)
RETURNS TEXT AS $$
DECLARE
  destino TEXT;
BEGIN
  destino := get_shard(p_id_usuario);

  IF destino = 'pg_shard_1' THEN
    INSERT INTO cuentas_shard1 (id_cuenta, id_usuario, moneda, saldo, estado, fecha_creacion)
    VALUES (p_id_cuenta, p_id_usuario, p_moneda, p_saldo, p_estado, now());
  ELSIF destino = 'pg_shard_2' THEN
    INSERT INTO cuentas_shard2 (id_cuenta, id_usuario, moneda, saldo, estado, fecha_creacion)
    VALUES (p_id_cuenta, p_id_usuario, p_moneda, p_saldo, p_estado, now());
  ELSE
    INSERT INTO cuentas_shard3 (id_cuenta, id_usuario, moneda, saldo, estado, fecha_creacion)
    VALUES (p_id_cuenta, p_id_usuario, p_moneda, p_saldo, p_estado, now());
  END IF;

  RETURN destino;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_cuenta_por_usuario(p_id_usuario BIGINT)
RETURNS TABLE (
  id_cuenta BIGINT,
  id_usuario BIGINT,
  moneda TEXT,
  saldo NUMERIC(18,2),
  estado TEXT,
  fecha_creacion TIMESTAMPTZ
) AS $$
DECLARE
  destino TEXT;
BEGIN
  destino := get_shard(p_id_usuario);

  IF destino = 'pg_shard_1' THEN
    RETURN QUERY
    SELECT c.id_cuenta, c.id_usuario, c.moneda, c.saldo, c.estado, c.fecha_creacion
    FROM cuentas_shard1 c
    WHERE c.id_usuario = p_id_usuario;

  ELSIF destino = 'pg_shard_2' THEN
    RETURN QUERY
    SELECT c.id_cuenta, c.id_usuario, c.moneda, c.saldo, c.estado, c.fecha_creacion
    FROM cuentas_shard2 c
    WHERE c.id_usuario = p_id_usuario;

  ELSE
    RETURN QUERY
    SELECT c.id_cuenta, c.id_usuario, c.moneda, c.saldo, c.estado, c.fecha_creacion
    FROM cuentas_shard3 c
    WHERE c.id_usuario = p_id_usuario;
  END IF;
END;
$$ LANGUAGE plpgsql;

GRANT USAGE ON FOREIGN SERVER shard1_srv TO admin;
GRANT USAGE ON FOREIGN SERVER shard2_srv TO admin;
GRANT USAGE ON FOREIGN SERVER shard3_srv TO admin;

GRANT SELECT, INSERT ON cuentas_shard1 TO admin;
GRANT SELECT, INSERT ON cuentas_shard2 TO admin;
GRANT SELECT, INSERT ON cuentas_shard3 TO admin;
GRANT SELECT ON movimientos_shard1 TO admin;
GRANT SELECT ON movimientos_shard2 TO admin;
GRANT SELECT ON movimientos_shard3 TO admin;

GRANT SELECT ON cuentas_dist TO admin;
GRANT SELECT ON movimientos_dist TO admin;

GRANT EXECUTE ON FUNCTION get_shard(BIGINT) TO admin;
GRANT EXECUTE ON FUNCTION insert_cuenta_distribuida(BIGINT, BIGINT, TEXT, NUMERIC, TEXT) TO admin;
GRANT EXECUTE ON FUNCTION get_cuenta_por_usuario(BIGINT) TO admin;
