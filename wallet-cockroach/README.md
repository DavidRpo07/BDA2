
# Proyecto 2 - Arquitecturas Distribuidas  
**SI3009 Bases de Datos Avanzadas 2026-1**  
**Motor NewSQL evaluado:** CockroachDB  
**Dominio del problema:** Billetera Digital (Wallet)

---

## 1. Descripción general

En este proyecto se evaluó el comportamiento de una base de datos distribuida **NewSQL** usando **CockroachDB** en un clúster de **3 nodos** desplegado con Docker. El objetivo fue comparar el esfuerzo de implementar un sistema distribuido de forma manual en PostgreSQL frente a una solución distribuida nativa, enfocándonos en particionamiento, replicación, consistencia, transacciones distribuidas y tolerancia a fallos.

La aplicación modelada fue una **billetera digital**, con operaciones típicas de usuarios, cuentas, movimientos, transferencias, límites de cuenta y auditoría. Sobre este modelo se construyeron pruebas para evidenciar cómo CockroachDB maneja internamente la distribución de datos mediante **ranges**, la replicación automática entre nodos, la coordinación de lecturas y escrituras mediante **leaseholders**, y la tolerancia a fallos por consenso **Raft**.

---

## 2. Objetivo del experimento

El propósito de esta parte del proyecto fue demostrar que, en un motor NewSQL como CockroachDB:

- el particionamiento es automático
- la replicación es nativa
- la consistencia fuerte está integrada en el motor
- las transacciones distribuidas no requieren implementación manual de 2PC
- la recuperación ante fallos es más transparente que en un motor clásico distribuido manualmente

---

## 3. Modelo de datos

Para mantener una comparación válida con PostgreSQL, se usó el mismo modelo lógico del dominio Wallet, adaptándolo a CockroachDB.

### Tablas principales

- `usuarios`
- `cuentas`
- `movimientos`
- `transferencias`
- `limites_cuenta`
- `auditoria_transferencias`

### Estructura general del dominio

- Un **usuario** puede tener una o varias **cuentas**
- Una **cuenta** puede registrar múltiples **movimientos**
- Una **transferencia** relaciona una cuenta origen con una cuenta destino
- Cada **cuenta** puede tener límites configurados en `limites_cuenta`
- Cada **transferencia** puede generar eventos en `auditoria_transferencias`

### Consideraciones de diseño

Se usaron identificadores tipo `UUID` en lugar de claves secuenciales para alinearse mejor con el comportamiento distribuido de CockroachDB. Los montos se modelaron con `DECIMAL(18,2)` para representar valores monetarios de manera exacta. También se conservaron restricciones de negocio mediante `CHECK`, claves foráneas y reglas de integridad.

---

## 4. Infraestructura y despliegue

La solución fue desplegada con **Docker Compose**, levantando un clúster de **3 nodos de CockroachDB** en una red local compartida.

### Arquitectura general

```text
                 ┌─────────────────────────────┐
                 │         Cliente SQL         │
                 │ cockroach sql / consultas   │
                 └──────────────┬──────────────┘
                                │
                    ┌───────────┴───────────┐
                    │ Gateway / Nodo acceso │
                    │   crdb1 :26257        │
                    └───────────┬───────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
┌───────▼───────┐       ┌───────▼───────┐       ┌───────▼───────┐
│    crdb1      │       │    crdb2      │       │    crdb3      │
│  Node ID 1    │       │  Node ID 2    │       │  Node ID 3    │
│  Store local  │       │  Store local  │       │  Store local  │
│  Replica set  │       │  Replica set  │       │  Replica set  │
└───────────────┘       └───────────────┘       └───────────────┘