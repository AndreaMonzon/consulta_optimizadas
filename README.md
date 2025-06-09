# 🧠 Consultas SQL Optimizadas

Este repositorio contiene un conjunto de consultas SQL diseñadas para resolver problemas comunes en el análisis de datos fiscales y financieros, con un enfoque en **optimización de performance**, **claridad** y **mantenibilidad**.

## 📌 Objetivo

Centralizar y documentar consultas SQL optimizadas que aplican principalmente a entornos de Oracle, utilizadas en procesos reales relacionados con:

- Cuentas corrientes
- Planes de pago
- Cálculo de impuestos
- Rectificativas y devengados

## 🛠️ Tecnologías utilizadas

- Oracle SQL (PL/SQL)
- SQL Análisis con funciones de ventana (`LAG`, `ROW_NUMBER`, etc.)
- Vistas analíticas y joins complejos

## 📂 Contenido

| Archivo SQL                             | Descripción breve                                                  |
|----------------------------------------|--------------------------------------------------------------------|
| `consulta_calculos_impuesto.sql`       | Consulta para cálculo de impuestos con base imponible y alícuotas |
| `consulta_optimizada_cta_cte.sql`      | Optimización sobre cuentas corrientes con condiciones complejas   |
| `consulta_optimizada_planes_pago.sql`  | Planes de pago con filtros y mejoras de lectura                   |
| `cuenta_cte_devengado_ir.sql`          | Consulta de devengados con intereses en cuentas corrientes        |




## 💡 Notas adicionales

- Las consultas fueron aplicadas en un contexto real de análisis fiscal.
- Se utilizan funciones analíticas y subqueries correlacionadas para obtener últimos valores o rectificativas.
- Los scripts están organizados por propósito y tipo de operación.

## 🙋‍♀️ Sobre mí

**Andrea Monzón**  
Junior Data Engineer  
💼 Apasionada por transformar datos en decisiones  
🔗 [LinkedIn](https://www.linkedin.com/in/andreamonzon/) 



💬 *¡Gracias por visitar este repo! Si te resulta útil, no dudes en darle una estrella ⭐ o conectarte conmigo en LinkedIn.*
