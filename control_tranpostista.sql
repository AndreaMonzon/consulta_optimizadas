-- Este proyecto SQL utiliza CTEs y funciones analíticas para calcular indicadores clave de rendimiento (KPIs) a partir de datos de productos transportados, personas fiscalizadas y relevamientos realizados en puestos de control.
-- Objetivo

-- Calcular un KPI de eficiencia del transporte (kg/km) y otros indicadores útiles a partir de datos de relevamientos, incorporando técnicas de SQL avanzadas como:

--     Common Table Expressions (CTEs)

--     Funciones de ventana (RANK())

--     Condicionales para evitar divisiones por cero

--     Agregaciones y joins optimizados

--  se calcula

--     Eficiencia (kg/km): Cuánto peso se transporta por kilómetro recorrido.

--     Monto imponible estimado: Multiplicación entre kilos transportados y un valor estimado por producto.

--     Ranking de relevamientos: Por puesto de control, basado en la fecha más reciente.

--     Joins multi-tabla: Entre relevamientos, productos, y personas fiscalizadas.
-- Consulta optimizada con CTEs, KPI de eficiencia (kg/km) y ranking de relevamientos
WITH
-- CTE de productos para evitar múltiples llamadas remotas
productos AS (
  SELECT producto, descripcion AS producto_desc
  FROM transporte.tbl_productos@tcsdisc.
),
-- CTE de personas para concesionario y cuenta orden
personas AS (
  SELECT
    sujeto_id,
    pa_persona.get_cuit@tcsdisc(sujeto_id) AS cuit,
    pa_persona.get_persona_descr@tcsdisc(sujeto_id) AS razon_social
  FROM personas.tbl_personas@tcsdisc
),
-- CTE principal de relevamientos
relevamientos AS (
  SELECT
    rp.cuit_transportista AS cuit_consignatario,
    rp.puesto_control,
    rp.fecha_relevamiento,
    rp.actividad,
    rp.producto,
    rp.km_recorridos,
    rp.km_base_calculo,
    rp.fecha_ticket,
    rp.kg_base_calculo * rp.km_recorridos AS monto_imponible_km_recorridos
  FROM transporte.tbl_relevamiento_pesado@tcsdisc rp
  WHERE rp.fecha_relevamiento > TO_DATE('2014-12-31', 'YYYY-MM-DD')
)

SELECT
  r.cuit_consignatario,
  r.puesto_control,
  r.actividad,
  prod.producto_desc,
  SUM(r.km_recorridos)                        AS total_km_recorridos,
  SUM(r.monto_imponible_km_recorridos)        AS total_monto_imponible,
  -- KPI: eficiencia en kg por km
  CASE WHEN SUM(r.km_recorridos) = 0 THEN NULL
       ELSE ROUND(SUM(r.kg_base_calculo) / SUM(r.km_recorridos), 2)
  END                                         AS eficiencia_kg_por_km,
  -- Ranking de relevamientos por puesto de control (más recientes primero)
  RANK() OVER (
    PARTITION BY r.puesto_control
    ORDER BY r.fecha_relevamiento DESC
  )                                           AS ranking_fecha_relevamiento
FROM relevamientos r
LEFT JOIN productos prod ON r.producto = prod.producto
GROUP BY
  r.cuit_consignatario,
  r.puesto_control,
  r.actividad,
  prod.producto_desc;
