-- Consulta optimizada para consolidación de planes de pago
-- Fecha: 2023-02-9
-- Autor: Andrea Monzon
-- Descripción: Este repositorio contiene una consulta SQL optimizada utilizada para consolidar información sobre planes de pago, 
--impuestos y conceptos asociados, provenientes de distintas tablas en un entorno Oracle. Se aplicaron buenas prácticas de ingeniería
-- de datos para mejorar su rendimiento, legibilidad y mantenibilidad..
-- Acciones realizadas
-- 1. Se usó `ROW_NUMBER` para filtrar los últimos vencimientos.
-- 2. Se aplicaron `CTE (WITH)` para modularizar la consulta.
-- 3. Se incorporaron descripciones de conceptos e impuestos.
-- 4. Se evitó el uso de subconsultas innecesarias en el `SELECT`.
-- 5. Se validó el `Plan Hash` para confirmar mejora.
--previo a esos pasos se  gregar índices en columnas utilizadas para JOIN o filtros.

Verificar estadísticas con DBMS_STATS.
-- ## Resultado
-- Consulta más clara, mantenible y rápida.
--Se utilizaron Common Table Expressions (CTEs) para organizar la lógica en etapas:

   -- base_planes: Selecciona la versión más reciente por combinación clave usando ROW_NUMBER().

WITH base_planes AS (
  SELECT 
    ANIO,
    CONCEPTO_OBLIGACION,
    FECHA_CORTE,
    IMPORTE_PLAN_FACILIDAD,
    IMPUESTO,
    NUMERO_CUOTA,
    NUMERO_OBLIGACION_IMPUESTO,
    NUMERO_RECTIFICATIVA,
    PLAN_FACILIDAD,
    clave_imponible,
    ROW_NUMBER() OVER (
      PARTITION BY PLAN_FACILIDAD, anio, concepto_obligacion, impuesto, 
                   numero_cuota, numero_obligacion_impuesto, numero_rectificativa
      ORDER BY fecha_corte DESC
    ) sec
  FROM analitic.detalle_planes_vencimientos
),
--planes_generales: Une planes con su fecha de generación.
planes_generales AS (
  SELECT DISTINCT 
    dpf.CUIT, 
    dpf.PLAN_FACILIDAD, 
    cpf.FECHA_GENERACION
  FROM analitic.DETALLE_PLANES_FACILIDADES dpf
  LEFT JOIN (
    SELECT 
      plan_facilidad, 
      FECHA_GENERACION
    FROM analitic.cabecera_planes_facilidades
    GROUP BY plan_facilidad, FECHA_GENERACION
  ) cpf ON dpf.PLAN_FACILIDAD = cpf.PLAN_FACILIDAD
),
--conceptos / impuestos: Diccionarios descriptivos de conceptos e impuestos (vía DBLink).
conceptos AS (
  SELECT 
    concepto_obligacion, 
    concepto_obligacion_descr
  FROM tbl_conceptos_obligaciones@tcsdisc.dgrcorrientes.gov.ar
),

impuestos AS (
  SELECT 
    impuesto, 
    impuesto_descr
  FROM tbl_impuestos@tcsdisc.dgrcorrientes.gov.ar
)

SELECT
  b.FECHA_GENERACION AS fecha_movimiento,
  b.FECHA_GENERACION AS fecha_movimiento_pago,
  a.ANIO,
  TO_NUMBER(TO_CHAR(a.ANIO) || TO_CHAR(a.NUMERO_CUOTA, 'FM00')) AS periodo,
  a.CONCEPTO_OBLIGACION,
  c.concepto_obligacion_descr AS concepto_descr,
  3333 AS concepto_cta_cte,
  'Acogimiento plan de pago' AS cto_cta_descr,
  3333 AS subconcepto_cta_cte,
  'Acogimiento plan de pago' AS subconcepto_descr,
  0 AS numero_asiento,
  a.IMPORTE_PLAN_FACILIDAD AS creditos,
  0 AS debitos,
  a.IMPUESTO,
  i.impuesto_descr AS imp_descr,
  a.NUMERO_CUOTA,
  a.PLAN_FACILIDAD,
  b.CUIT,
  b.FECHA_GENERACION AS fecha_presentacion,
  a.clave_imponible
FROM base_planes a
LEFT JOIN planes_generales b ON a.PLAN_FACILIDAD = b.PLAN_FACILIDAD
LEFT JOIN conceptos c ON a.CONCEPTO_OBLIGACION = c.concepto_obligacion
LEFT JOIN impuestos i ON a.IMPUESTO = i.impuesto
WHERE a.sec = 1;


SELECT  cuit_a
        FROM tcscorrweb.snap_detalle_retenciones_temp@tcsprod.dgrcorrientes.gov.ar