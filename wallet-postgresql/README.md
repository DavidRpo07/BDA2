# Población de datos: 1000 cuentas y 500 movimientos por cuenta

## Objetivo

Este README documenta los scripts necesarios para:

1. Insertar **1000 cuentas** desde el **coordinator** usando la función de routing `insert_cuenta_distribuida()`.
2. Generar **500 movimientos por cuenta** directamente en cada **shard**.

La estrategia es híbrida:

* **Cuentas**: se insertan desde el coordinator para demostrar el **enrutamiento manual** en PostgreSQL clásico.
* **Movimientos**: se insertan directamente en cada shard para evitar el overhead de FDW en una carga masiva y poblar la tabla de mayor volumen.

---

## Paso 1. Insertar 1000 cuentas desde el coordinator

Conectarse al **coordinator primary**:

```bash
docker exec -it pg_coord_primary env PGPASSWORD=postgrespass psql -U postgres -d walletdb
```

Ejecutar:

```sql
-- =========================================
-- INSERTAR 1000 CUENTAS DISTRIBUIDAS
-- =========================================

SELECT insert_cuenta_distribuida(
    100000 + gs,                     -- id_cuenta (evita colisiones)
    1000 + gs,                       -- id_usuario (clave de partición)
    CASE
        WHEN gs % 5 = 0 THEN 'USD'
        ELSE 'COP'
    END,                             -- moneda
    ROUND((random() * 5000000 + 100000)::numeric, 2),
    'ACTIVA'
)
FROM generate_series(1, 1000) AS gs;
```

### Validación después de insertar cuentas

```sql
SELECT COUNT(*) FROM cuentas_dist WHERE id_cuenta >= 100001;

SELECT get_shard(id_usuario), COUNT(*)
FROM cuentas_dist
WHERE id_cuenta >= 100001
GROUP BY 1
ORDER BY 1;
```

### Resultado esperado

* Deben existir **1000 cuentas nuevas**.
* Deben repartirse aproximadamente así:

  * `pg_shard_1` → ~333
  * `pg_shard_2` → ~333
  * `pg_shard_3` → ~334

---

## Paso 2. Insertar 500 movimientos por cuenta en cada shard

> Importante: estos scripts generan movimientos **solo para las cuentas nuevas**, es decir, para `id_cuenta >= 100001`.

---

## Shard 1

Conectarse a `pg_shard_1`:

```bash
docker exec -it pg_shard_1 psql -U admin -d walletdb
```

Ejecutar:

```sql
-- =========================================
-- SHARD 1: 500 movimientos por cuenta
-- =========================================

INSERT INTO movimientos (
    id_movimiento,
    id_cuenta,
    tipo_movimiento,
    monto,
    descripcion,
    fecha_movimiento
)
SELECT
    1000000 + row_number() OVER () AS id_movimiento,
    c.id_cuenta,
    CASE
        WHEN random() < 0.5 THEN 'DEBITO'
        ELSE 'CREDITO'
    END AS tipo_movimiento,
    ROUND((random() * 500000 + 1000)::numeric, 2) AS monto,
    'Movimiento masivo generado en shard 1',
    now() - (random() * interval '365 days')
FROM cuentas c
CROSS JOIN generate_series(1, 500) g
WHERE c.id_cuenta >= 100001;
```

### Validación en shard 1

```sql
SELECT COUNT(*) AS cuentas_nuevas
FROM cuentas
WHERE id_cuenta >= 100001;

SELECT COUNT(*) AS movimientos_nuevos
FROM movimientos
WHERE id_cuenta >= 100001;
```

---

## Shard 2

Conectarse a `pg_shard_2`:

```bash
docker exec -it pg_shard_2 psql -U admin -d walletdb
```

Ejecutar:

```sql
-- =========================================
-- SHARD 2: 500 movimientos por cuenta
-- =========================================

INSERT INTO movimientos (
    id_movimiento,
    id_cuenta,
    tipo_movimiento,
    monto,
    descripcion,
    fecha_movimiento
)
SELECT
    2000000 + row_number() OVER () AS id_movimiento,
    c.id_cuenta,
    CASE
        WHEN random() < 0.5 THEN 'DEBITO'
        ELSE 'CREDITO'
    END AS tipo_movimiento,
    ROUND((random() * 500000 + 1000)::numeric, 2) AS monto,
    'Movimiento masivo generado en shard 2',
    now() - (random() * interval '365 days')
FROM cuentas c
CROSS JOIN generate_series(1, 500) g
WHERE c.id_cuenta >= 100001;
```

### Validación en shard 2

```sql
SELECT COUNT(*) AS cuentas_nuevas
FROM cuentas
WHERE id_cuenta >= 100001;

SELECT COUNT(*) AS movimientos_nuevos
FROM movimientos
WHERE id_cuenta >= 100001;
```

---

## Shard 3

Conectarse a `pg_shard_3`:

```bash
docker exec -it pg_shard_3 psql -U admin -d walletdb
```

Ejecutar:

```sql
-- =========================================
-- SHARD 3: 500 movimientos por cuenta
-- =========================================

INSERT INTO movimientos (
    id_movimiento,
    id_cuenta,
    tipo_movimiento,
    monto,
    descripcion,
    fecha_movimiento
)
SELECT
    3000000 + row_number() OVER () AS id_movimiento,
    c.id_cuenta,
    CASE
        WHEN random() < 0.5 THEN 'DEBITO'
        ELSE 'CREDITO'
    END AS tipo_movimiento,
    ROUND((random() * 500000 + 1000)::numeric, 2) AS monto,
    'Movimiento masivo generado en shard 3',
    now() - (random() * interval '365 days')
FROM cuentas c
CROSS JOIN generate_series(1, 500) g
WHERE c.id_cuenta >= 100001;
```

### Validación en shard 3

```sql
SELECT COUNT(*) AS cuentas_nuevas
FROM cuentas
WHERE id_cuenta >= 100001;

SELECT COUNT(*) AS movimientos_nuevos
FROM movimientos
WHERE id_cuenta >= 100001;
```

---

## Paso 3. Validación global desde el coordinator

Volver al **coordinator primary**:

```bash
docker exec -it pg_coord_primary env PGPASSWORD=postgrespass psql -U postgres -d walletdb
```

Ejecutar:

```sql
SELECT COUNT(*) AS total_cuentas_nuevas
FROM cuentas_dist
WHERE id_cuenta >= 100001;

SELECT COUNT(*) AS total_movimientos_nuevos
FROM movimientos_dist
WHERE id_cuenta >= 100001;
```

### Resultado esperado

* **1000 cuentas nuevas**
* **500.000 movimientos nuevos**

---

## Consultas de revisión útiles

```sql
SELECT *
FROM cuentas_dist
WHERE id_cuenta >= 100001
ORDER BY id_cuenta
LIMIT 20;

SELECT *
FROM movimientos_dist
WHERE id_cuenta >= 100001
ORDER BY id_movimiento
LIMIT 20;
```

---

## Justificación del enfoque

Se decidió:

* insertar las **cuentas** desde el **coordinator** para evidenciar el **routing manual** en PostgreSQL clásico,
* e insertar los **movimientos** directamente en cada **shard** para poblar la tabla de mayor volumen de manera más eficiente.

Esto permite comparar posteriormente con la solución NewSQL:

* en PostgreSQL, la transparencia de inserción distribuida debe construirse manualmente,
* mientras que en una base NewSQL el auto-sharding y el routing son responsabilidad del motor.
