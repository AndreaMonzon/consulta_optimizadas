-- Analizar las variaciones en declaraciones juradas mensuales de contribuyentes para identificar diferencias en base imponible,
--  alícuota e impuesto, considerando únicamente la última versión rectificativa disponible por período.

-- Descripción técnica:
-- Se parte de una tabla de declaraciones juradas históricas (ANALITIC.DETALLE_DJ_PRUEBA). El proceso consta de dos etapas:

--     Filtro de rectificativas más recientes:

--         Se usa ROW_NUMBER() para seleccionar la última rectificativa de cada combinación de CUIT + Anticipo + Actividad + Tipo Contribuyente + Tratamiento + Régimen.

--     Comparación de datos entre períodos:

--         Mediante funciones de ventana (LAG()), se comparan los valores de cada anticipo con los del anticipo inmediatamente anterior (dentro de la misma clave CUIT + Actividad + Tratamiento, etc.).

--         Se calculan las diferencias en base imponible, alícuota e impuesto declarado.



WITH ultimas_rectificativas AS (
  SELECT *
  FROM (
    SELECT d.*,
           ROW_NUMBER() OVER (
             PARTITION BY CUIT, ANTICIPO, actividad, TIPO_CONTRIB, TRATAMIENTO, REGIMEN
             ORDER BY NUMERO_RECTIFICATIVA DESC NULLS LAST
           ) AS rn
    FROM ANALITIC.DETALLE_DJ_prueba d
  )
  WHERE rn = 1
),

agregado_con_lag AS (
  SELECT 
    CUIT,
    ANTICIPO,
    ANTICIPO_FECHA,
    ANIO,
    NUMERO_CUOTA,
    COD_GRUPO,
    DESC_GRUPO,
    COD_SUBGRUPO,
    DESC_SUBGRUPO,
    ACTIVIDAD,
    TRATAMIENTO,
    REGIMEN,
    BASE_IMPONIBLE,
    LAG(BASE_IMPONIBLE) OVER (PARTITION BY CUIT, actividad, TIPO_CONTRIB, TRATAMIENTO, REGIMEN ORDER BY ANTICIPO) AS BASE_IMPONIBLE_ANTERIOR,

    ALICUOTA_DECLARADA,
    LAG(ALICUOTA_DECLARADA) OVER (PARTITION BY CUIT, actividad, TIPO_CONTRIB, TRATAMIENTO, REGIMEN ORDER BY ANTICIPO) AS ALICUOTA_DECLARADA_ANTERIOR,

    IMPUESTO,
    LAG(IMPUESTO) OVER (PARTITION BY CUIT, actividad, TIPO_CONTRIB, TRATAMIENTO, REGIMEN ORDER BY ANTICIPO) AS IMPUESTO_ANTERIOR,

    BASE_IMPONIBLE_ART8,
    LAG(BASE_IMPONIBLE_ART8) OVER (PARTITION BY CUIT,actividad, TIPO_CONTRIB, TRATAMIENTO, REGIMEN ORDER BY ANTICIPO) AS BASE_IMPONIBLE_ART8_ANTERIOR,

   
    FECHA_PRESENTACION,
    LAG(FECHA_PRESENTACION) OVER (PARTITION BY CUIT,actividad, TIPO_CONTRIB, TRATAMIENTO, REGIMEN ORDER BY ANTICIPO) AS FECHA_PRES_ANTERIOR,

    TIPO_CONTRIB,
    NUMERO_RECTIFICATIVA
  FROM ultimas_rectificativas
)

SELECT 
  CUIT,
  ANTICIPO,
  ANTICIPO_FECHA,
  ANIO,
  NUMERO_CUOTA,
  COD_GRUPO,
  DESC_GRUPO,
  COD_SUBGRUPO,
  DESC_SUBGRUPO,
  TRATAMIENTO,
  REGIMEN,
  BASE_IMPONIBLE,
  BASE_IMPONIBLE_ANTERIOR,
  ALICUOTA_DECLARADA,
  ALICUOTA_DECLARADA_ANTERIOR,
  IMPUESTO,
  IMPUESTO_ANTERIOR
  FECHA_PRESENTACION,
  FECHA_PRES_ANTERIOR,
  TIPO_CONTRIB,ACTIVIDAD,
  NUMERO_RECTIFICATIVA

FROM agregado_con_lag