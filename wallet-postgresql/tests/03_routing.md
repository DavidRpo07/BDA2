# VALIDACIÓN DE ROUTING

## Paso 1: Conectarse al coordinator

docker exec -it pg_coord_primary psql -U admin -d walletdb

---

## Paso 2: Ver distribución

SELECT id_usuario, get_shard(id_usuario)
FROM usuarios
ORDER BY id_usuario;

---

## Paso 3: Consultar por usuario

SELECT * FROM get_cuenta_por_usuario(4);

SELECT * FROM get_cuenta_por_usuario(5);

Esperado:
Debe consultar solo el shard correcto.