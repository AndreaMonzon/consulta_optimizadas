
Análisis de Vencimientos y Consistencia de Cuotas C0/RC      DELETE


Objetivo

Detectar la secuencia de vencimientos de obligaciones por contribuyente (CLAVE_IMPONIBLE), 
dentro de cada año fiscal, e identificar inconsistencias en cuotas tipo C0 (cuota cero) en función del orden
 y los montos involucrados.

SELECT 
    ANIO,
    CLAVE_IMPONIBLE,
    CONCEPTO_CTA_CTE,
    CONCEPTO_DESCR,
    CONCEPTO_OBLIGACION,
    CREDITOS,
    CTA_CTE_ID,
    CTO_CTA_DESCR,
    CUIT,
    DEBITOS,
    FECHA_MOVIMIENTO,
    FECHA_MOVIMIENTO_PAGO,
    FECHA_PRESENTACION,
    FECHA_VENCIMIENTO,
    IMP_DESCR,
    IMPUESTO,
    NUMERO_ASIENTO,
    NUMERO_CUOTA,
    NUMERO_OBLIGACION_IMPUESTO,
    PERIODO,
    RAZON_SOCIAL,
    SUBCONCEPTO_CTA_CTE,
    SUBCONCEPTO_DESCR,
    VENCIMIENTO,
    tipo_cuota --Etiqueta 'C0' si numero_cuota = 0, sino 'RC',
    diferencia --Suma total de movimientos (créditos + débitos) por contribuyente y cuota.,
--COUNT(DISTINCT ...) OVER (...): cuenta cuántos tipos de cuotas (C0, RC) hay por actividad y año.
--Cantidad de tipos de cuota diferentes por anio y clave_imponible.
    COUNT(DISTINCT tipo_cuota) OVER (PARTITION BY anio, clave_imponible) AS CANT_LIQUID,
--DENSE_RANK() OVER (...): asigna el orden real de vencimientos dentro de cada actividad y año.
    DENSE_RANK() OVER (PARTITION BY anio, clave_imponible ORDER BY fecha_vencimiento ASC) AS orden_vencimiento,
--CASE WHEN: lógica condicional para determinar si corresponde considerar la cuota como válida (S) o no (N).
    CASE
         WHEN concepto_obligacion <> 0010 THEN 'S'
         WHEN numero_cuota = 0 AND diferencia > 0 THEN 'N'
         WHEN COUNT(DISTINCT tipo_cuota) OVER (PARTITION BY anio, clave_imponible) = 1 THEN 'S'
         WHEN numero_cuota = 0 AND COUNT(DISTINCT tipo_cuota) OVER (PARTITION BY anio, clave_imponible) > 1 THEN 'N'
         ELSE 'S'
    END AS corresponde

FROM (
    SELECT 
        ANIO,
        CLAVE_IMPONIBLE,
        CONCEPTO_CTA_CTE,
        CONCEPTO_DESCR,
        CONCEPTO_OBLIGACION,
        CREDITOS,
        CTA_CTE_ID,
        CTO_CTA_DESCR,
        CUIT,
        DEBITOS,
        FECHA_MOVIMIENTO,
        FECHA_MOVIMIENTO_PAGO,
        FECHA_PRESENTACION,
        FECHA_VENCIMIENTO,
        IMP_DESCR,
        IMPUESTO,
        NUMERO_ASIENTO,
        NUMERO_CUOTA,
        NUMERO_OBLIGACION_IMPUESTO,
        PERIODO,
        RAZON_SOCIAL,
        SUBCONCEPTO_CTA_CTE,
        SUBCONCEPTO_DESCR,
        VENCIMIENTO,

        CASE 
            WHEN numero_cuota = 0 THEN 'C0'
            ELSE 'RC'
        END AS tipo_cuota,

        MAX(fecha_vencimiento) OVER (PARTITION BY cuit, anio, clave_imponible) AS MAX_FE_VEN,
        MAX(CASE WHEN numero_cuota = 0 THEN fecha_vencimiento END) OVER (
            PARTITION BY cuit, concepto_obligacion, anio, clave_imponible
        ) AS MAX_FE_VEN_C0,

        SUM(COALESCE(debitos, 0) + COALESCE(creditos, 0)) OVER (
            PARTITION BY cuit, numero_cuota, clave_imponible
        ) AS diferencia

    FROM analitic.cuentas_corrientes_detalle
    WHERE concepto_cta_cte NOT IN (9999, 9998) and anio>2020
)
