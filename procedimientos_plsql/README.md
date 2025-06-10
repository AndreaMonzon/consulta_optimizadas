# Procedimiento PL/SQL: Carga de Declaraciones Juradas Convenio Multilateral

Este procedimiento almacenable en Oracle (`carga_cab_djcm_incre_test`) automatiza el proceso de carga de declaraciones juradas (DJ) para el impuesto de Convenio Multilateral, tomando como fuente distintas tablas de un sistema remoto y registrando la información en una base local para su análisis y procesamiento posterior.

## Objetivo

- Identificar y cargar transacciones nuevas (o rectificativas) que aún no han sido procesadas.
- Consolidar los datos fiscales en la tabla `cabecera_dj`.
- Marcar adecuadamente los estados de las transacciones como:
  - **C** (Cargado correctamente)
  - **S** (Ya existente)
  - **X** (Error en procesamiento)

## Proceso general

1. **Lectura de datos remotos** desde vistas/materializadas relacionadas con disquetes de DJ.
2. **Validación de existencia previa** para evitar duplicados.
3. **Inserción de datos** consolidados en `analitic.cabecera_dj`.
4. **Actualización de información complementaria**, como base imponible país, impuesto país, vencimientos y tipo de presentación (CM04).
5. **Gestión de errores** y registro del estado del proceso.

## Tablas involucradas

- **Remotas** (`@mulat` y `@tcsdisc`)

  - `mv_DISQUETE_REG_1`, `mv_DISQUETE_REG_15`, `disquete_reg_6`, `disquete_reg_2`
  - `transacciones_proceso`, `transaccion`
  - `tbl_vencimientos`, `vw_tbl_personas`

- **Locales**
  - `analitic.cabecera_dj`

## Características destacadas

- Manejo de cursores PL/SQL para recorrer múltiples registros.
- Uso de funciones de validación y transformación (`decode`, `substr`, `to_date`, etc).
- Commit transaccional por registro con control de errores.
- Modularidad que permite adaptarlo a otros tipos de DJ (autónomos, locales, etc).

## 📁 ¿Dónde puede aplicarse?

Ideal para entornos de administración fiscal, data warehouses gubernamentales o sistemas contables que requieren una sincronización y consolidación de datos provenientes de fuentes heterogéneas.

## Recomendaciones

- Configurar jobs automáticos en Oracle para su ejecución periódica.
- Registrar los errores en una tabla de log personalizada (para trazabilidad).
- Aplicar validaciones adicionales para evitar carga de datos inconsistentes.

---

Desarrollado como parte de un proyecto de automatización de procesos fiscales en Oracle PL/SQL.
