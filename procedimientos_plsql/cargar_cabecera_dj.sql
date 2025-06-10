CREATE OR REPLACE PROCEDURE carga_cab_djcm_incre_test IS

  -- Declaración de variables
  v_existe NUMBER;
  v_bif NUMBER(20,2);
  v_impf NUMBER(20,2);
  v_fecha_vencimiento DATE;

  -- Cursor principal
  CURSOR c1 IS
    SELECT a.cuit, SUBSTR(a.anticipo,1,6) AS anticipo, a.codigo_rectificativa,
           a.transaccion_afip, b.fecha_registro AS fecha_presentacion
      FROM mv_DISQUETE_REG_1@dgrcorrientes a
      JOIN transaccion@dgrcorrientes b ON a.transaccion_afip = b.transaccion_afip
      JOIN mv_DISQUETE_REG_15@dgrcorrientes c ON a.transaccion_afip = c.transaccion_afip
     WHERE SUBSTR(a.anticipo,1,6) >= 202501
       AND c.jurisdiccion = 905
       AND (a.formulario BETWEEN 5800 AND 5824 OR a.formulario IN ('5851','5850','5852','5862','5866','5863','5867'))
       AND a.transaccion_afip IN (
             SELECT transaccion_afip
               FROM transacciones_proceso@dgrcorrientes
              WHERE procesado = 'S'
                AND (procesado_analitic IS NULL OR procesado_analitic NOT IN ('S','C'))
           );

BEGIN
  -- Iteración sobre cada registro del cursor
  FOR c1_reg IN c1 LOOP
    BEGIN
      -- Verificar si ya existe en cabecera_dj
      SELECT COUNT(0) INTO v_existe
        FROM analitic.cabecera_dj
       WHERE transaccion_afip = c1_reg.transaccion_afip;

      IF v_existe = 0 THEN
        v_bif := 0;
        v_impf := 0;

        -- Insertar en cabecera_dj
        INSERT INTO analitic.cabecera_dj
        SELECT 'Convenio', c1_reg.cuit,
               (SELECT razon_social || ' ' || nombre FROM analitic.vw_tbl_personas WHERE cuit = c1_reg.cuit),
               c1_reg.anticipo,
               TO_DATE('01' || SUBSTR(c1_reg.anticipo,5,2) || SUBSTR(c1_reg.anticipo,1,4), 'DDMMYYYY'),
               TO_NUMBER(SUBSTR(c1_reg.anticipo,1,4)),
               TO_NUMBER(SUBSTR(c1_reg.anticipo,5,2)),
               DECODE(a.signo_impuesto, '1', '-', NULL) || a.impuesto_determinado,
               a.saldo_favor,
               DECODE(a.signo_percepciones_soportadas, '1', '-', NULL) || a.percepciones_soportadas,
               a.compensacion_percepcion,
               DECODE(a.signo_percepciones_deducir, '1', '-', NULL) || a.percepciones_deducir,
               DECODE(a.signo_retenciones_banc, '1', '-', NULL) || a.retenciones_bancarias,
               DECODE(a.signo_retenciones, '1', '-', NULL) || a.retenciones,
               a.percepciones_aduaneras, a.recargo_intereses, a.otros_debitos,
               a.creditos_anticipo, a.pagos_no_bancarios, a.otros_creditos,
               a.diferencia_favor_fisco, a.diferencia_favor_contri,
               a.deposita_importe, NULL, NULL,
               c1_reg.codigo_rectificativa, c1_reg.fecha_presentacion,
               NULL, NULL, c1_reg.transaccion_afip, NULL, NULL, NULL, NULL,
               0, 0, 'I'
          FROM mv_DISQUETE_REG_15@dgrcorrientes a
         WHERE transaccion_afip = c1_reg.transaccion_afip
           AND a.jurisdiccion = 905;

        -- Calcular montos
        SELECT SUM(DECODE(a.signo_base_imponible_total, '1', '-', NULL) || a.base_imponible_total),
               SUM(DECODE(a.signo_impuesto_total, '1', '-', NULL) || a.impuesto_total)
          INTO v_bif, v_impf
          FROM disquete_reg_6@dgrcorrientes a
         WHERE transaccion_afip = c1_reg.transaccion_afip;

        BEGIN
          SELECT DISTINCT(fecha_primer_vencimiento) INTO v_fecha_vencimiento
            FROM tbl_vencimientos@dgrcorrientes c
           WHERE c.contribuyente = tcscorrientes.pa_persona.get_persona_id_x_cuit@dgrcorrientes(c1_reg.cuit)
             AND c.impuesto = '0035'
             AND c.concepto_obligacion = '0015'
             AND c.anio = TO_NUMBER(SUBSTR(c1_reg.anticipo,1,4))
             AND c.numero_cuota = TO_NUMBER(SUBSTR(c1_reg.anticipo,5,2));
        EXCEPTION
          WHEN OTHERS THEN NULL;
        END;

        COMMIT;

        -- Actualización de cabecera_dj
        UPDATE analitic.cabecera_dj
           SET base_imponible_pais = v_bif,
               impuesto_pais = v_impf,
               fecha_vencimiento = v_fecha_vencimiento,
               cm04 = (
                 SELECT DECODE(articulo8, 0, 'N', 'S')
                   FROM disquete_reg_2@dgrcorrientes
                  WHERE transaccion_afip = c1_reg.transaccion_afip
               )
         WHERE transaccion_afip = c1_reg.transaccion_afip;

        COMMIT;

        -- Marcar última presentación
        UPDATE analitic.cabecera_dj a
           SET ultima_presentacion = DECODE(((
             (SELECT COUNT(0)
                FROM analitic.cabecera_dj b
               WHERE a.cuit = b.cuit AND a.anticipo = b.anticipo) - 1
           ) - a.numero_rectificativa, '0', 'S', 'N')
         WHERE cuit = c1_reg.cuit
           AND anticipo = c1_reg.anticipo
           AND tipo_contri = 'Convenio';

        COMMIT;

        -- Marcar procesado como correcto
        UPDATE transacciones_proceso@dgrcorrientes
           SET procesado_analitic = 'C',
               fecha_proceso_analitic = SYSDATE
         WHERE procesado = 'S'
           AND (procesado_analitic IS NULL OR procesado_analitic NOT IN ('S','C'))
           AND transaccion_afip = c1_reg.transaccion_afip;

        COMMIT;

      ELSE
        -- Marcar como ya existente
        UPDATE transacciones_proceso@dgrcorrientes
           SET procesado_analitic = 'S',
               fecha_proceso_analitic = SYSDATE
         WHERE procesado = 'S'
           AND (procesado_analitic IS NULL OR procesado_analitic NOT IN ('S','C'))
           AND transaccion_afip = c1_reg.transaccion_afip;

        COMMIT;
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        UPDATE transacciones_proceso@dgrcorrientes
           SET procesado_analitic = 'X',
               fecha_proceso_analitic = SYSDATE
         WHERE procesado = 'S'
           AND (procesado_analitic IS NULL OR procesado_analitic NOT IN ('S','C'))
           AND transaccion_afip = c1_reg.transaccion_afip;
        COMMIT;
    END;
  END LOOP;
END;
