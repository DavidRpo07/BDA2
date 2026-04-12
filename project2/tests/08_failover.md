# VALIDACIÓN DE FAILOVER

## Paso 1: Simular caída

docker stop pg_coord_primary

---

## Paso 2: Ver logs

docker logs pg_coord_replica1

---

## Paso 3: Identificar nuevo líder accediendo a la replica y ejecutando

SELECT pg_is_in_recovery();

---

## Paso 4: Probar escritura

INSERT INTO usuarios (id_usuario, nombre, email, pais)
VALUES (999, 'Nuevo Lider', 'lider@test.com', 'CO');

---

## Paso 5: Validar en réplica

SELECT * FROM usuarios WHERE id_usuario = 999;