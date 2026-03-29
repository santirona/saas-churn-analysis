/*
===============================================================================
PROYECTO: Análisis de Retención y Churn en Modelo SaaS
ARCHIVO: business_queries.sql
MOTOR DB: MySQL
DESCRIPCIÓN:
Este script contiene las consultas analíticas utilizadas para extraer
las métricas clave de negocio (MRR, Churn Rate) y descubrir la causa raíz
de las cancelaciones entre clientes y facturación.
===============================================================================
*/

-- ----------------------------------------------------------------------------
-- CONSULTA 1: Identificación de la Anomalía de Retención
-- Objetivo: Calcular la tasa de cancelación (Churn Rate) y el Ingreso
-- Recurrente Mensual (MRR) perdido, agrupado por tipo de contrato.
-- Hallazgo: El plan anual tiene la misma tasa de cancelación que el mensual.
-- ----------------------------------------------------------------------------

SELECT
    s.contract_type AS Tipo_Contrato,
    COUNT(c.customer_id) AS Total_Clientes,
    SUM(c.churn) AS Clientes_Perdidos,
    ROUND((SUM(c.churn) / COUNT(c.customer_id)) * 100, 2) AS Tasa_Cancelacion_Pct,
    SUM(CASE WHEN c.churn = 1 THEN s.monthly_fee ELSE 0 END) AS Ingreso_Mensual_Perdido
FROM dim_suscripciones s
JOIN fact_comportamiento c ON s.customer_id = c.customer_id
GROUP BY s.contract_type
ORDER BY Tasa_Cancelacion_Pct DESC;


-- ----------------------------------------------------------------------------
-- CONSULTA 2: Diagnóstico de Causa Raíz (Fricción de Pagos vs Soporte)
-- Objetivo: Aislar el plan 'Yearly' (Anual) para comparar las métricas de
-- interacción de los usuarios que cancelaron frente a los retenidos.
-- Hallazgo: El Churn Involuntario es causado por fallos de pago, no por mal
-- servicio de soporte técnico (tiempos de resolución idénticos).
-- ----------------------------------------------------------------------------

SELECT
    CASE WHEN c.churn = 1 THEN 'Canceló (Churn)' ELSE 'Retenido' END AS Estado_Suscripcion,
    COUNT(c.customer_id) AS Cantidad_Usuarios,
    ROUND(AVG(c.support_tickets), 2) AS Promedio_Tickets_Soporte,
    ROUND(AVG(c.avg_resolution_time), 2) AS Tiempo_Resolucion_Dias,
    ROUND(AVG(c.csat_score), 2) AS Score_Satisfaccion_CSAT,
    ROUND(AVG(c.payment_failures), 2) AS Promedio_Fallos_Pago
FROM dim_suscripciones s
JOIN fact_comportamiento c ON s.customer_id = c.customer_id
WHERE s.contract_type = 'Yearly'
GROUP BY c.churn;
