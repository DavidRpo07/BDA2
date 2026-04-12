# VALIDACIÓN DE AUSENCIA DE SPLIT-BRAIN

## Objetivo

Comprobar que, después del failover, no existen dos nodos actuando como líder al mismo tiempo.

Un escenario de split-brain ocurriría si:
- el nuevo líder acepta escrituras
- y el líder antiguo, al volver, también acepta escrituras
- o si dos nodos aparecen como primary simultáneamente

---



## Reencender el líder antiguo y comprobar que no vuelve como segundo primary

Si el primary original había sido apagado, volver a encenderlo:

docker start pg_coord_primary

Luego conectarse:

docker exec -it pg_coord_primary psql -U postgres -d walletdb

Ejecutar:

SELECT pg_is_in_recovery();

### Esperado
No debe comportarse como segundo primary.
Idealmente debe volver como standby o reengancharse al nuevo líder.

Ahora intentar escribir:

INSERT INTO usuarios (id_usuario, nombre, email, pais)
VALUES (1202, 'Old Primary Test', 'old.primary@test.com', 'CO');

### Esperado
No debería aceptar escrituras si ya no es el líder.

### Interpretación
Si el líder antiguo no acepta escrituras al regresar, entonces no se generó split-brain.

---
