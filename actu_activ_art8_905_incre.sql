/**
 * PROCEDIMIENTO: ACTU_ACTIV_ART8_905_INCRE
 *
 * DESCRIPCIÓN:
 * Este procedimiento procesa las declaraciones juradas (DJ) de contribuyentes bajo el régimen de Convenio Multilateral,
 * correspondientes a la jurisdicción 905 (artículo 8), comparando los valores del anticipo actual con los del anticipo inmediato anterior.
 * 
 * Para cada registro no procesado (`procesado_art8 = 'N'`):
 *   - Si el anticipo no es enero, busca los valores de base imponible e impuesto del anticipo anterior.
 *   - Calcula la diferencia entre los valores actuales y los anteriores (o sus versiones ajustadas por art. 8 si están disponibles).
 *   - Actualiza el registro con las diferencias y guarda el valor actual como base e impuesto ajustado por art. 8.
 *   - Si no es posible calcular diferencias (por ser enero, o no haber datos previos), simplemente marca el registro como procesado.
 *
 * También valida que las DJ pertenezcan a transacciones AFIP ya procesadas y con tratamiento CM04.
 * 
 * Incluye control de errores individual por fila, rollback parcial en caso de fallo y uso de cursores ordenados por CUIT y anticipo descendente.
 *
 * USOS:
 * - Actualización de diferencias mensuales para análisis fiscal.
 * - Preparación de datos para reportes analíticos y consistencia con artículo 8 del régimen.
 */



CREATE OR REPLACE PROCEDURE actu_activ_art8_905_incre IS

    CURSOR c1 IS
        SELECT a.*, b.fecha_presentacion AS presentacion_fecha
        FROM detalle_dj a
        JOIN cabecera_dj b ON a.cuit = b.cuit
                          AND a.anio = b.anio
                          AND a.numero_cuota = b.numero_cuota
                          AND a.numero_rectificativa = b.numero_rectificativa
        WHERE b.cm04 = 'S'
          AND a.procesado_art8 = 'N'
          AND b.transaccion_afip IN (
              SELECT transaccion_afip
              FROM mulat.transacciones_proceso@mulat.dgrcorrientes.gov.ar
              WHERE procesado = 'S'
                AND procesado_analitic = 'S'
          )
        ORDER BY a.cuit, a.anticipo DESC;

    -- Variables para diferencias
    v_base                 NUMBER(15,2);
    v_impuesto             NUMBER(15,2);
    v_baseart8             NUMBER(15,2);
    v_impuestoart8         NUMBER(15,2);
    v_base_diferencia      NUMBER(15,2);
    v_impuesto_diferencia  NUMBER(15,2);

BEGIN

    FOR c1_reg IN c1 LOOP
        -- Si no es el primer anticipo del año (enero)
        IF SUBSTR(c1_reg.anticipo, 5, 2) <> '01' THEN
            BEGIN
                -- Savepoint por cada fila para aislar errores
                SAVEPOINT fila_inicio;

                v_base := 0;
                v_impuesto := 0;
                v_baseart8 := NULL;
                v_impuestoart8 := NULL;

                BEGIN
                    SELECT base_imponible,
                           impuesto,
                           base_imponible_art8,
                           impuesto_art8
                    INTO v_base,
                         v_impuesto,
                         v_baseart8,
                         v_impuestoart8
                    FROM detalle_dj
                    WHERE cuit = c1_reg.cuit
                      AND actividad = c1_reg.actividad
                      AND regimen = c1_reg.regimen
                      AND tratamiento = c1_reg.tratamiento
                      AND TO_NUMBER(anticipo) = TO_NUMBER(c1_reg.anticipo) - 1
                      AND numero_rectificativa = (
                          SELECT MAX(numero_rectificativa)
                          FROM cabecera_dj
                          WHERE cuit = c1_reg.cuit
                            AND TO_NUMBER(anticipo) = TO_NUMBER(c1_reg.anticipo) - 1
                            AND fecha_presentacion <= c1_reg.presentacion_fecha
                      );

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_base := 0;
                        v_impuesto := 0;
                        v_baseart8 := NULL;
                        v_impuestoart8 := NULL;
                END;

                -- Diferencias usando COALESCE para evitar nulos
                v_base_diferencia := c1_reg.base_imponible - COALESCE(v_baseart8, v_base);
                v_impuesto_diferencia := c1_reg.impuesto - COALESCE(v_impuestoart8, v_impuesto);

                -- Actualización con diferencias
                UPDATE detalle_dj
                SET impuesto = v_impuesto_diferencia,
                    base_imponible = v_base_diferencia,
                    base_imponible_art8 = c1_reg.base_imponible,
                    impuesto_art8 = c1_reg.impuesto,
                    procesado_art8 = 'S'
                WHERE cuit = c1_reg.cuit
                  AND actividad = c1_reg.actividad
                  AND anticipo = c1_reg.anticipo
                  AND regimen = c1_reg.regimen
                  AND tratamiento = c1_reg.tratamiento
                  AND numero_rectificativa = c1_reg.numero_rectificativa;

            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Error en CUIT ' || c1_reg.cuit || ', ANTICIPO ' || c1_reg.anticipo || ': ' || SQLERRM);
                    ROLLBACK TO fila_inicio;
            END;

        ELSE
            -- Para anticipos iniciales: solo marcar como procesado
            UPDATE detalle_dj
            SET procesado_art8 = 'S'
            WHERE cuit = c1_reg.cuit
              AND actividad = c1_reg.actividad
              AND anticipo = c1_reg.anticipo
              AND regimen = c1_reg.regimen
              AND tratamiento = c1_reg.tratamiento
              AND numero_rectificativa = c1_reg.numero_rectificativa;
        END IF;

    END LOOP;

    COMMIT;

END actu_activ_art8_905_incre;
