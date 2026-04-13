# VALIDACIÓN DE REPLICACIÓN

## Paso 1: Identificar el primary

docker exec -it pg_coord_primary psql -U postgres -d walletdb

SELECT pg_is_in_recovery();

false = primary
true = replica

---

## Paso 2: Ver estado

SELECT application_name, state, sync_state
FROM pg_stat_replication;

---

## Paso 3: Insertar en primary

INSERT INTO usuarios (id_usuario, nombre, email, pais)
VALUES (800, 'Test Rep', 'testeo@rep.com', 'CO');

---

## Paso 4: Validar en réplica

SELECT * FROM usuarios WHERE id_usuario = 800;