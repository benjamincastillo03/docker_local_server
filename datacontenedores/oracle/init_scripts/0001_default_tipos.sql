ALTER SESSION SET CONTAINER       = XEPDB1;
ALTER SESSION SET CURRENT_SCHEMA  = ADMIN
/
CREATE OR REPLACE TYPE ADMIN.LIST_OF_NAMES_T IS VARRAY(10) OF VARCHAR2(100);
/
COMMIT;
/
CREATE OR REPLACE TYPE ADMIN.OBJTIPOSISTEMATOTEM AS OBJECT (
     V_EMPRESA VARCHAR2(50)
    ,V_SYSDATE_INICIO DATE
    ,V_SYSDATE_FINAL DATE
    ,CONSTRUCTOR FUNCTION OBJTIPOSISTEMATOTEM(SELF IN OUT NOCOPY OBJTIPOSISTEMATOTEM, V_EMPRESA VARCHAR2)  RETURN SELF AS RESULT
    ,MEMBER FUNCTION ALL_TOTEMS_ACTIVOS RETURN SYS_REFCURSOR
    ,MEMBER FUNCTION ALL_VENTANILLAS_ANGOL RETURN SYS_REFCURSOR
    ,MEMBER FUNCTION CONSULTA_TIKECT_NUEVOS(IND_OPCION NUMBER, V_FECHA_INICIO DATE,V_FECHA_FINAL DATE,IND_PRIORIDAD VARCHAR2) RETURN SYS_REFCURSOR
    ,MEMBER FUNCTION LAST_TICKET_PRIORIDAD(IND_OPCION NUMBER,IND_VENTANILLA VARCHAR2, V_ID_UID VARCHAR2) RETURN SYS_REFCURSOR
    ,MEMBER FUNCTION LAST_TICKET_INDIVIDUAL(V_ID_NUMFILA NUMBER) RETURN SYS_REFCURSOR
    ,MEMBER PROCEDURE ESTADISTICA_X_VENTANILLA(V_EMPRESA IN VARCHAR2,V_IND_VENTANILLA IN VARCHAR2, V_FECHA_INICIO IN DATE,  V_FECHA_FINAL IN DATE,  V_NUM_TOTAL IN OUT NUMBER,V_NUM_GENERAL IN OUT NUMBER,V_NUM_PREFERENCIAL IN OUT NUMBER)
);
/
CREATE OR REPLACE TYPE BODY ADMIN.OBJTIPOSISTEMATOTEM AS 
  CONSTRUCTOR FUNCTION OBJTIPOSISTEMATOTEM(SELF IN OUT NOCOPY OBJTIPOSISTEMATOTEM, V_EMPRESA VARCHAR2) RETURN SELF AS RESULT IS
  BEGIN
      SELF.V_EMPRESA  := V_EMPRESA;
      RETURN;
  END;
  MEMBER FUNCTION ALL_TOTEMS_ACTIVOS RETURN SYS_REFCURSOR  IS 
      V_RETUN_CURSOR SYS_REFCURSOR;
  BEGIN 
      OPEN V_RETUN_CURSOR  FOR 
      SELECT 
          H.ID_TOTEM, 
          H.IND_ESTADO, 
          H.TXT_DESCRIPCION, 
          H.COD_EMPRESA, 
          H.IND_IP, 
          H.TXT_ID, 
          H.IND_PISO, 
          H.TXT_LLAVE, 
          H.TXT_LOCATION, 
          H.IND_STATUS, 
          H.TXT_OBSERVACIONES,
          H.PC_MAC
      FROM 
          ADMIN.HO_LISTA_TOTEMANGOL H
      WHERE
          H.IND_ESTADO IN (1)
      ORDER BY ID_TOTEM;
     RETURN V_RETUN_CURSOR;
            EXCEPTION  WHEN NO_DATA_FOUND THEN  RETURN V_RETUN_CURSOR;
  END;
  
   MEMBER FUNCTION ALL_VENTANILLAS_ANGOL RETURN SYS_REFCURSOR  IS 
      V_RETUN_CURSOR SYS_REFCURSOR;
  BEGIN 
      OPEN V_RETUN_CURSOR  FOR 
      SELECT 
          T.ID_VENTANILLA                         AS IND_VENTANILLA,
          T.TXT_VENTANILLA                     AS TXT_VENTANILLA,
          T.IND_ESTADO, 
          T.COD_EMPRESA, 
          T.HEX_COLOR                              AS IND_COLOR,
          T.IND_ZONA, 
          T.ID_DEMANDA,
          NVL(D.NUM_GENERAL,1)                AS DEMANDA_PGENERAL,
          NVL(D.NUM_PREFERENCIAL,1)        AS DEMANDA_PREFERENCIA
      FROM 
          ADMIN.TO_FARMVENTANILLA T
          LEFT JOIN ADMIN.TO_DEMANDAXVENTANILLA D ON  T.ID_VENTANILLA = D.ID_VENTANILLA  AND D.IND_ESTADO IN (1)
      WHERE
          T.IND_ESTADO IN (1)
      AND
          T.COD_EMPRESA IN (100)
      AND 
          T.IND_ZONA IN (1);
     RETURN V_RETUN_CURSOR;
            EXCEPTION  WHEN NO_DATA_FOUND THEN  RETURN V_RETUN_CURSOR;
  END;
    
MEMBER FUNCTION LAST_TICKET_PRIORIDAD(IND_OPCION NUMBER,IND_VENTANILLA VARCHAR2,V_ID_UID VARCHAR2 ) RETURN SYS_REFCURSOR  IS 
    V_RETUN_CURSOR SYS_REFCURSOR;
    --VAR_LISTA_TIPOZONA   LIST_OF_NAMES_T :=  LIST_OF_NAMES_T();  
    V_NUM_FILA NUMBER;
    V_NUM_ROW NUMBER;
    
BEGIN 

  IF IND_OPCION =  1 THEN 
      SELECT ID_NUMFILA,IND_EXISTE INTO V_NUM_FILA,V_NUM_ROW FROM (
      -- PRIOPIRDAD PUBLICO PREFERENCIAL
      SELECT 
      COUNT(*) AS IND_EXISTE, T.ID_NUMFILA ,TO_CHAR(T.FEC_CREACION,'DD-MM-YYYY hh24:mi:ss')  AS FEC_CREACION, T.IND_PRIORIDAD
      FROM 
      ADMIN.TO_FILAFARMACIACENTRAL T LEFT JOIN ADMIN.TO_HISTO_FARMVENTANILLA H ON T.ID_NUMFILA = H.ID_NUMFILA
      WHERE  
          H.ID_NUMFILA IS NULL 
      AND 
          TO_CHAR(T.FEC_CREACION, 'DD-MM-YYYY') = TO_CHAR(SYSDATE, 'DD-MM-YYYY') 
      AND 
          T.IND_ZONA IN (0) 
      AND 
          T.IND_ESTADO IN (1) 
      GROUP BY T.FEC_CREACION ,T.ID_NUMFILA ,T.IND_PRIORIDAD
      ORDER BY T.IND_PRIORIDAD DESC ,T.FEC_CREACION
  ) WHERE ROWNUM = 1;
    ELSE 
          --PRIORIDAD PUBLCO GENERAL
          SELECT ID_NUMFILA,IND_EXISTE INTO V_NUM_FILA,V_NUM_ROW FROM (
            SELECT 
            COUNT(*) AS IND_EXISTE, T.ID_NUMFILA ,TO_CHAR(T.FEC_CREACION,'DD-MM-YYYY hh24:mi:ss')  AS FEC_CREACION, T.IND_PRIORIDAD
            FROM 
            ADMIN.TO_FILAFARMACIACENTRAL T LEFT JOIN ADMIN.TO_HISTO_FARMVENTANILLA H ON T.ID_NUMFILA = H.ID_NUMFILA
            WHERE  
                H.ID_NUMFILA IS NULL 
            AND 
                TO_CHAR(T.FEC_CREACION, 'DD-MM-YYYY') = TO_CHAR(SYSDATE, 'DD-MM-YYYY') 
            AND 
                T.IND_ZONA IN (0) 
            AND 
                T.IND_ESTADO IN (1) 
            GROUP BY T.FEC_CREACION ,T.ID_NUMFILA ,T.IND_PRIORIDAD
            ORDER BY T.IND_PRIORIDAD ASC ,T.FEC_CREACION
        ) WHERE ROWNUM = 1;
        
    END IF;
    
    IF V_NUM_ROW = 1 THEN 
      --HISTORIAL DE LA VENTANILLA 
      INSERT INTO ADMIN.TO_HISTO_FARMVENTANILLA 
      (ID_HISTOVENTANILLA,ID_DEMANDA,ID_VENTANILLA,IND_OPCION,ID_NUMFILA,DATE_EVENTO,ID_UID) 
      VALUES 
      (ADMIN.SEQ_HISTOVENTANILLA.NEXTVAL,0,IND_VENTANILLA,0,V_NUM_FILA,SYSDATE,V_ID_UID);
      RETURN LAST_TICKET_INDIVIDUAL(V_NUM_FILA);
    END IF;
    RETURN V_RETUN_CURSOR;
    EXCEPTION  WHEN NO_DATA_FOUND THEN  RETURN V_RETUN_CURSOR;
  END;
     

 MEMBER FUNCTION CONSULTA_TIKECT_NUEVOS(IND_OPCION NUMBER, V_FECHA_INICIO DATE,V_FECHA_FINAL DATE,IND_PRIORIDAD VARCHAR2)  RETURN SYS_REFCURSOR  IS 
        V_RETUN_CURSOR SYS_REFCURSOR;
        VAR_LISTA_TIPOZONA   LIST_OF_NAMES_T :=  LIST_OF_NAMES_T();  
    BEGIN 
    
        IF  IND_OPCION  = 1 THEN 
            VAR_LISTA_TIPOZONA.EXTEND(1);  
            VAR_LISTA_TIPOZONA (1) := IND_PRIORIDAD;
        ELSE       
            VAR_LISTA_TIPOZONA.EXTEND(5);  
            VAR_LISTA_TIPOZONA (1) := 1;
            VAR_LISTA_TIPOZONA (2) := 2;
            VAR_LISTA_TIPOZONA (3) := 3;
            VAR_LISTA_TIPOZONA (4) := 4;
            VAR_LISTA_TIPOZONA (5) := 5;
        END IF;
        
        OPEN V_RETUN_CURSOR  FOR 
        
        SELECT 
        T.ID_NUMFILA, 
        T.COD_EMPRESA, 
        TO_CHAR(T.FEC_CREACION,'DD-MM-YYYY hh24:mi:ss')                                 AS FEC_CREACION,
        TO_CHAR(T.FEC_CREACION,'hh24:mi')                                                         AS HORA_CREACION,
        T.IND_ESTADO, 
        T.TXT_SUBNUMERO                                                                                    AS TXT_SUBNUMERO, 
        T.IND_ZONA, 
        T.TXT_IP, 
        T.IND_PRIORIDAD,
        T.NUM_X_DIA,
        HISTO.NUM_TOTAL                                                                                    AS CALL_LLAMADAS,
        HISTO.TXT_VENTANILLA                                                                            AS TXT_VENTANILLA,
        HISTO.HEX_COLOR                                                                                    AS HEX_COLOR, 
        HISTO.ID_VENTANILLA                                                                               AS ID_VENTANILLA_CALL, 
        DECODE(T.IND_PRIORIDAD,
            '1','PUBLICO GENERAL',
            '2','ADULTO MAYOR',
            '3','EMBARAZADAS',
            '4','CUIDADORES',
            '5','C. DISCAPACIDAD','--')                                                                       AS NOMBRE_TIPO_PACIENTE,
          DECODE(T.IND_PRIORIDAD,
            '1','#publico_general',
            '2','#adulto_mayor',
            '3','#embarazadas',
            '4','#cuidadores',
            '5','#carnet_discapacidad','--')                                                                 AS TABS_X_PACIENTE,        
         DECODE(T.IND_PRIORIDAD,
            '1','A',
            '2','B',
            '3','C',
            '4','D',
            '5','E','--') || '-' || T.NUM_X_DIA                                                                   AS NOMBRE_TICKET,
         DECODE(T.IND_PRIORIDAD,'1','PUBLICO GENERAL','PUBLICO PREFERENCIAL')      AS TXT_TIPOPUBLICO,
         DECODE(T.IND_PRIORIDAD, '1','1','2')                                                               AS IND_TIPOPUBLICO
    FROM 
        ADMIN.TO_FILAFARMACIACENTRAL                                                             T,
        (
          SELECT 
          COUNT(*) AS NUM_TOTAL, 
          H.ID_NUMFILA , 
          V.TXT_VENTANILLA,
          V.HEX_COLOR,
          V.ID_VENTANILLA
            
          FROM 
          ADMIN.TO_HISTO_FARMVENTANILLA H,
          ADMIN.TO_FARMVENTANILLA V
          WHERE 
          H.ID_VENTANILLA = V.ID_VENTANILLA
          AND
          H.IND_OPCION IN (0) 
          GROUP BY   V.ID_VENTANILLA,H.ID_NUMFILA,V.TXT_VENTANILLA, V.HEX_COLOR ) HISTO
    WHERE
        T.FEC_CREACION BETWEEN V_FECHA_INICIO AND V_FECHA_FINAL 
        AND 
        T.ID_NUMFILA = HISTO.ID_NUMFILA  (+) 
        AND
        T.COD_EMPRESA IN (100)
        AND 
        T.IND_ESTADO IN (1)
        AND 
        T.IND_ZONA IN (0)
        AND   
        T.IND_PRIORIDAD IN  (SELECT * FROM TABLE(VAR_LISTA_TIPOZONA))   
    ORDER BY 
        T.FEC_CREACION;
        RETURN V_RETUN_CURSOR;
              EXCEPTION  WHEN NO_DATA_FOUND THEN  RETURN V_RETUN_CURSOR;
    END;
    
     MEMBER FUNCTION LAST_TICKET_INDIVIDUAL(V_ID_NUMFILA NUMBER) RETURN SYS_REFCURSOR  IS 
        V_RETUN_CURSOR SYS_REFCURSOR;
     BEGIN 
        OPEN V_RETUN_CURSOR  FOR  
        SELECT 
            T.ID_NUMFILA, 
            T.COD_EMPRESA, 
            TO_CHAR(T.FEC_CREACION,'DD-MM-YYYY hh24:mi:ss')                            AS FEC_CREACION,
            TO_CHAR(T.FEC_CREACION,'hh24:mi')                                                    AS HORA_CREACION,
            T.IND_ESTADO, 
            T.TXT_SUBNUMERO, 
            T.IND_ZONA, 
            T.TXT_IP, 
            T.IND_PRIORIDAD AS IND_PRIORIDAD,
            T.NUM_X_DIA,
        DECODE(T.IND_PRIORIDAD,
            '1','PUBLICO GENERAL',
            '2','ADULTO MAYOR',
            '3','EMBARAZADAS',
            '4','CUIDADORES',
            '5','C. DISCAPACIDAD','--')                                                                       AS NOMBRE_TIPO_PACIENTE,
        DECODE(T.IND_PRIORIDAD,
            '1','#publico_general',
            '2','#adulto_mayor',
            '3','#embarazadas',
            '4','#cuidadores',
            '5','#carnet_discapacidad','--')                                                                 AS TABS_X_PACIENTE,     
        DECODE(T.IND_PRIORIDAD,
            '1','A',
            '2','B',
            '3','C',
            '4','D',
            '5','E','--') || T.NUM_X_DIA                                                                           AS NOMBRE_TICKET,
         DECODE(T.IND_PRIORIDAD, '1','PUBLICO GENERAL','PUBLICO PREFERENCIAL')      AS TXT_TIPOPUBLICO,
         DECODE(T.IND_PRIORIDAD, '1','1','2')                                                               AS IND_TIPOPUBLICO
    FROM 
        ADMIN.TO_FILAFARMACIACENTRAL T
    WHERE
        T.IND_ESTADO IN (1)
        AND 
        T.IND_ZONA IN (0)
        AND 
        T.ID_NUMFILA IN (V_ID_NUMFILA);
      RETURN V_RETUN_CURSOR;
              EXCEPTION  WHEN NO_DATA_FOUND THEN  RETURN V_RETUN_CURSOR;
      END;
      
      
      MEMBER PROCEDURE ESTADISTICA_X_VENTANILLA(V_EMPRESA IN VARCHAR2,V_IND_VENTANILLA IN VARCHAR2, V_FECHA_INICIO IN DATE,  V_FECHA_FINAL IN DATE,  V_NUM_TOTAL IN OUT NUMBER,V_NUM_GENERAL IN OUT NUMBER,V_NUM_PREFERENCIAL IN OUT NUMBER) IS
      
      BEGIN 
        --ESTADISTICA POR DIA SOBRE PRODUCCION EN VENTANILLA
        SELECT
            COUNT(*),                                                                                                     
            NVL(SUM(CASE WHEN T.IND_PRIORIDAD  IN (1) THEN 1 ELSE 0 END),0),
            NVL(SUM(CASE WHEN T.IND_PRIORIDAD  NOT IN  (1) THEN 1 ELSE 0 END),0)
        INTO 
            V_NUM_TOTAL,
            V_NUM_GENERAL,
            V_NUM_PREFERENCIAL
        FROM
            ADMIN.TO_FILAFARMACIACENTRAL T
        WHERE
            T.FEC_CREACION BETWEEN  V_FECHA_INICIO AND V_FECHA_FINAL  AND 
            T.COD_EMPRESA IN (V_EMPRESA) AND 
            T.ID_VENTANILLA IN (V_IND_VENTANILLA) AND                              -- INDICAR VENTANILLA DE BUSQUEDA
            T.IND_ZONA IN (1) AND                                      -- SOLO TICKET RESUELTOS
            T.IND_ESTADO IN (1)                                         -- TICKET VALIDO
        ORDER BY T.DATE_CITACION DESC;
      END;
END;
/
/
CREATE OR REPLACE PACKAGE ADMIN.HOSP_GESTION_TOTEMS AS
  
  PROCEDURE LOAD_INFORMACION_TOTEM (
      VAL_ID_TOTEM IN VARCHAR2,
      VAL_COD_EMPRESA IN VARCHAR2,  
      VAL_IND_OPCION IN VARCHAR2,  
      P_LISTADO_EVENTOS OUT SYS_REFCURSOR
  );

  PROCEDURE LISTA_TOTEMS_ANGOL (
      V_RUN IN VARCHAR2,
      V_IND_OPTION IN VARCHAR2,
      DATA_LISTA_TOTEMS OUT SYS_REFCURSOR
  );

  PROCEDURE LOAD_FORMULARIO_EVENTO(
    V_IND_OPCION  IN VARCHAR2,
    DATA_OPCIONES OUT SYS_REFCURSOR,  
    DATA_LISTA_FUNCIONARIOS OUT SYS_REFCURSOR
  );

  PROCEDURE LOAD_FILA_FARMACIA_CENTRAL(
    V_COD_EMPRESA IN VARCHAR2,
    V_ID_UID IN VARCHAR2,
    V_IND_VENTANILLA IN VARCHAR2,
    VAL_FECHA IN VARCHAR2,
    V_INDPRIMERO IN VARCHAR2,
    C_LISTADO_VENTANILLAS OUT SYS_REFCURSOR,  
    C_LISTADO_TOTEMSFAR OUT SYS_REFCURSOR,  
    C_LISTADO_FILAS OUT SYS_REFCURSOR,
    C_ESTADISTICAS OUT SYS_REFCURSOR
  );

  PROCEDURE LOAD_TICKES_POR_PRIORIDAD(
    V_COD_EMPRESA IN VARCHAR2,
    V_FECHA_TICKET IN VARCHAR2,
    V_PRIORIDAD IN VARCHAR2,
    C_LISTADO_FILAS OUT SYS_REFCURSOR
  );

  PROCEDURE NUEVO_TICKET_FARMACIA(
    V_IND_PRIORIDAD IN VARCHAR2,
    C_LISTADO_FILAS OUT SYS_REFCURSOR
  );

  PROCEDURE RETURN_CALL_DEMANDA(
    V_EMPRESA IN VARCHAR2,
    V_DATE_FILA IN VARCHAR2,
    V_DEM_GENERAL IN VARCHAR2,
    V_DEM_PREFERENCIAL IN VARCHAR2,
    V_IND_VENTANILLA IN VARCHAR2,
    V_ID_UID IN VARCHAR2,
    C_CALL_TICKET OUT SYS_REFCURSOR,
    C_ESTADISTICAS OUT SYS_REFCURSOR,
    C_STATUS OUT SYS_REFCURSOR,
    C_ERROR OUT SYS_REFCURSOR
  );

  PROCEDURE RECORD_DEMANDAXVENTANILLA(
    V_CODEMPRESA IN VARCHAR2,
    V_NGENERAL IN VARCHAR2,
    V_NPREFERENCIAL IN VARCHAR2,
    V_VENTANILLA IN VARCHAR2,
    DATA_OUT OUT SYS_REFCURSOR
  );

  PROCEDURE RECORD_GESTIONTICKET(
    V_CODEMPRESA IN VARCHAR2,
    V_ID_TICKET IN VARCHAR2,
    V_IND_VENTANILLA IN VARCHAR2,
    V_OPCION IN VARCHAR2,
    V_NUM_CODIFICACION IN VARCHAR2,
    V_ID_UID IN VARCHAR2,
    DATA_OUT OUT SYS_REFCURSOR
  );

  PROCEDURE RECORD_HISTO_CALL(
    V_EMPRESA IN VARCHAR2,
    V_NUM_FILA IN VARCHAR2,
    V_IND_VENTANILLA IN VARCHAR2,
    V_ID_UID IN VARCHAR2,
    C_STATUS OUT SYS_REFCURSOR
);
END HOSP_GESTION_TOTEMS;

/
CREATE OR REPLACE PACKAGE BODY ADMIN.HOSP_GESTION_TOTEMS AS
  PROCEDURE LOAD_INFORMACION_TOTEM (
    VAL_ID_TOTEM IN VARCHAR2,
    VAL_COD_EMPRESA IN VARCHAR2,  
    VAL_IND_OPCION IN VARCHAR2,  
    P_LISTADO_EVENTOS OUT SYS_REFCURSOR
  ) IS 
BEGIN
  OPEN P_LISTADO_EVENTOS  FOR 
  SELECT 
    H.ID_TOTEM, 
    H.IND_ESTADO, 
    H.TXT_DESCRIPCION, 
    H.COD_EMPRESA, 
    H.IND_IP, 
    H.TXT_ID, 
    H.IND_PISO, 
    H.TXT_LLAVE, 
    H.TXT_LOCATION, 
    H.IND_STATUS, 
    H.TXT_OBSERVACIONES,
    H.PC_MAC
  FROM 
    ADMIN.HO_LISTA_TOTEMANGOL H
  WHERE
    H.IND_ESTADO IN (1) AND H.ID_TOTEM IN (VAL_ID_TOTEM);
  END;

  PROCEDURE LISTA_TOTEMS_ANGOL (
    V_RUN IN VARCHAR2,
    V_IND_OPTION IN VARCHAR2,
    DATA_LISTA_TOTEMS OUT SYS_REFCURSOR
  ) IS 
    V_DATE_INICIO_EVENTO DATE          :=   TO_DATE(TO_CHAR(SYSDATE,'DD-MM-YYYY')||' 00:00:00','DD-MM-YYYY hh24:mi:ss');  
    V_DATE_FINAL_EVENTO DATE        :=  TO_DATE(TO_CHAR(SYSDATE,'DD-MM-YYYY')||' 23:59:59','DD-MM-YYYY hh24:mi:ss'); 
    OBJ_TOTEM OBJTIPOSISTEMATOTEM  := NEW OBJTIPOSISTEMATOTEM('100');
  BEGIN
    DATA_LISTA_TOTEMS :=  OBJ_TOTEM.ALL_TOTEMS_ACTIVOS;
  END;


  PROCEDURE LOAD_FORMULARIO_EVENTO (
    V_IND_OPCION IN VARCHAR2,
    DATA_OPCIONES OUT SYS_REFCURSOR,  
    DATA_LISTA_FUNCIONARIOS OUT SYS_REFCURSOR
  ) IS 
  BEGIN
    OPEN DATA_OPCIONES  FOR  SELECT '1' AS V_KEY, 'PANTALLA RCE' AS V_VALUE  FROM SYS.DUAL;
    OPEN DATA_LISTA_FUNCIONARIOS  FOR  SELECT '1' AS V_KEY, 'PANTALLA RCE' AS V_VALUE  FROM SYS.DUAL;
  END;
   
PROCEDURE LOAD_FILA_FARMACIA_CENTRAL(
    V_COD_EMPRESA                IN VARCHAR2,
    V_ID_UID                            IN VARCHAR2,
    V_IND_VENTANILLA             IN VARCHAR2,
    VAL_FECHA                        IN VARCHAR2,
    V_INDPRIMERO                   IN VARCHAR2,
    C_LISTADO_VENTANILLAS   OUT SYS_REFCURSOR,  
    C_LISTADO_TOTEMSFAR     OUT SYS_REFCURSOR,  
    C_LISTADO_FILAS               OUT SYS_REFCURSOR,
    C_ESTADISTICAS                OUT SYS_REFCURSOR
) IS
    V_FECHA_INICIO DATE                 := TO_DATE(VAL_FECHA||' 00:00:00','DD-MM-YYYY hh24:mi:ss');
    V_FECHA_FINAL DATE                  := TO_DATE(VAL_FECHA||' 23:59:59','DD-MM-YYYY hh24:mi:ss');
    V_NUM_TOTAL NUMBER               :=0;
    V_NUM_GENERAL NUMBER            :=0;
    V_NUM_PREFERENCIAL NUMBER   :=0;
    OBJ_TOTEM_ANGOL OBJTIPOSISTEMATOTEM  := NEW OBJTIPOSISTEMATOTEM('100');
BEGIN
    OBJ_TOTEM_ANGOL.ESTADISTICA_X_VENTANILLA(V_COD_EMPRESA,V_IND_VENTANILLA,V_FECHA_INICIO,V_FECHA_FINAL,V_NUM_TOTAL,V_NUM_GENERAL,V_NUM_PREFERENCIAL);
    C_LISTADO_VENTANILLAS    := OBJ_TOTEM_ANGOL.ALL_VENTANILLAS_ANGOL;
    C_LISTADO_TOTEMSFAR     := OBJ_TOTEM_ANGOL.ALL_TOTEMS_ACTIVOS;
    C_LISTADO_FILAS               := OBJ_TOTEM_ANGOL.CONSULTA_TIKECT_NUEVOS(0,V_FECHA_INICIO,V_FECHA_FINAL,'');
    OPEN C_ESTADISTICAS  FOR  
    SELECT 
    V_NUM_TOTAL                 AS V_NUM_TOTAL ,
    V_NUM_GENERAL              AS V_NUM_GENERAL,
    V_NUM_PREFERENCIAL      AS V_NUM_PREFERENCIAL,
    '' AS TXT_OPCION_DETECTADA
    
    FROM SYS.DUAL;
END;

PROCEDURE LOAD_TICKES_POR_PRIORIDAD(
    V_COD_EMPRESA           IN VARCHAR2,
    V_FECHA_TICKET           IN VARCHAR2,
    V_PRIORIDAD                 IN VARCHAR2,
    C_LISTADO_FILAS          OUT SYS_REFCURSOR
) IS 
    V_FECHA_INICIO DATE                                   := TO_DATE(V_FECHA_TICKET||' 00:00:00','DD-MM-YYYY hh24:mi:ss');
    V_FECHA_FINAL DATE                                    := TO_DATE(V_FECHA_TICKET||' 23:59:59','DD-MM-YYYY hh24:mi:ss');
    OBJ_TOTEM_ANGOL OBJTIPOSISTEMATOTEM  := NEW OBJTIPOSISTEMATOTEM('100');
BEGIN 
    C_LISTADO_FILAS                                         :=  OBJ_TOTEM_ANGOL.CONSULTA_TIKECT_NUEVOS(1,V_FECHA_INICIO,V_FECHA_FINAL,V_PRIORIDAD);
END;

--NUEVO TICKET 
PROCEDURE NUEVO_TICKET_FARMACIA(
     V_IND_PRIORIDAD            IN VARCHAR2,
    C_LISTADO_FILAS           OUT SYS_REFCURSOR
) IS 
    V_UNICO_FARMACIA  NUMBER;
    V_NUMERO_X_DIA  NUMBER;
    V_LETRA_TICKET VARCHAR(255);
    V_SUB_NUMERO  VARCHAR(255);
BEGIN 
        
        -----------------------------------------------------
        ----------- LEYENDA PRIOPIDAD -----------------
        ---------- 1 - PUBLICO GENERAL -----------------
        ---------- 2 - ADULTO MAYOR -------------------
        ---------- 3 - EMBARAZADAS --------------------
        ---------- 4  - CUIDADORES ----------------------
        ---------- 5  - CARNET DISCAPACIDAD ---------
        -----------------------------------------------------
        
        V_UNICO_FARMACIA := ADMIN.SEQ_FILAFARMACIACENTRAL.NEXTVAL;
        SELECT 
        COUNT (T.ID_NUMFILA)+1, DECODE(V_IND_PRIORIDAD,'1','A','2','B','3','C','4','D','5','E') INTO V_NUMERO_X_DIA, V_LETRA_TICKET
        FROM ADMIN.TO_FILAFARMACIACENTRAL T
        WHERE
        T.IND_ESTADO IN (1)
        AND
        T.COD_EMPRESA IN ('100')
        AND
        TRUNC(T.FEC_CREACION) =TRUNC(SYSDATE)
        AND
        T.IND_PRIORIDAD IN (V_IND_PRIORIDAD);
        V_SUB_NUMERO :=  V_LETRA_TICKET ||'-'||V_NUMERO_X_DIA;
        INSERT INTO ADMIN.TO_FILAFARMACIACENTRAL(ID_NUMFILA,COD_EMPRESA,IND_ESTADO,TXT_SUBNUMERO,IND_ZONA,FEC_CREACION,TXT_IP,IND_PRIORIDAD,NUM_X_DIA) VALUES (V_UNICO_FARMACIA,'100',1,V_SUB_NUMERO,0,SYSDATE,'',V_IND_PRIORIDAD,V_NUMERO_X_DIA); 
        COMMIT;
        OPEN C_LISTADO_FILAS     FOR   
        SELECT 
            V_IND_PRIORIDAD                                           AS IND_PRIORIDAD,
            V_UNICO_FARMACIA                                        AS V_UNICO_FARMACIA,
            V_SUB_NUMERO                                               AS V_SUB_NUMERO,
            TO_CHAR(SYSDATE,'DD-MM-YYYY hh24:mi')       AS FECHA_TICKET
        FROM SYS.DUAL;
END;


PROCEDURE RECORD_DEMANDAXVENTANILLA(
    V_CODEMPRESA           IN VARCHAR2,
    V_NGENERAL                IN VARCHAR2,
    V_NPREFERENCIAL        IN VARCHAR2,
    V_VENTANILLA             IN VARCHAR2,
    DATA_OUT                   OUT SYS_REFCURSOR
) IS 

BEGIN 
    --VUELVE A 0
    UPDATE ADMIN.TO_DEMANDAXVENTANILLA SET   IND_ESTADO = 0  WHERE ID_VENTANILLA IN (V_VENTANILLA);
    --RECORD DEMANDAXVENTANILLA
    INSERT INTO ADMIN.TO_DEMANDAXVENTANILLA (ID_DEMANDA,ID_VENTANILLA,IND_ESTADO,NUM_GENERAL,NUM_PREFERENCIAL,DATE_EVENTO) VALUES (ADMIN.SEQ_DEMANDAXVENTANILLA.NEXTVAL,V_VENTANILLA,1,V_NGENERAL,V_NPREFERENCIAL,SYSDATE);
    COMMIT;
    OPEN DATA_OUT FOR SELECT TO_CHAR(SYSDATE,'DD-MM-YYYY hh24:mi')      AS UPD  FROM SYS.DUAL;
END;

PROCEDURE RECORD_GESTIONTICKET(
    V_CODEMPRESA           IN VARCHAR2,
    V_ID_TICKET                IN VARCHAR2,
    V_IND_VENTANILLA       IN VARCHAR2,
    V_OPCION                    IN VARCHAR2,
    V_NUM_CODIFICACION  IN VARCHAR2,
    V_ID_UID                      IN VARCHAR2,
    DATA_OUT                   OUT SYS_REFCURSOR
) IS
    V_COUNT_ROW NUMBER;
    E_TICKET_NOUPDATE EXCEPTION;
BEGIN 
    IF V_OPCION = 1 THEN 
        UPDATE ADMIN.TO_FILAFARMACIACENTRAL SET IND_ZONA = 1,  DATE_CITACION = SYSDATE,   ID_UID = V_ID_UID , ID_VENTANILLA =V_IND_VENTANILLA  WHERE  ID_NUMFILA IN (V_ID_TICKET) AND IND_ZONA IN (0);
    ELSE 
        UPDATE ADMIN.TO_FILAFARMACIACENTRAL SET IND_ZONA = 2,  DATE_CANCELACION = SYSDATE,    ID_UID = V_ID_UID,  ID_VENTANILLA =V_IND_VENTANILLA  WHERE  ID_NUMFILA IN (V_ID_TICKET) AND IND_ZONA IN (0);
    END IF;
   V_COUNT_ROW := SQL%ROWCOUNT;
    IF V_COUNT_ROW = 1 THEN COMMIT; ELSE RAISE E_TICKET_NOUPDATE; END IF;
EXCEPTION
    WHEN E_TICKET_NOUPDATE THEN
           OPEN DATA_OUT FOR   SELECT '1' AS COD_ERROR, V_COUNT_ROW AS NUM_ROW, T.* FROM ADMIN.TO_FILAFARMACIACENTRAL T WHERE T.ID_NUMFILA  IN (V_ID_TICKET);    
END;


PROCEDURE RETURN_CALL_DEMANDA(
    V_EMPRESA                  IN VARCHAR2,
    V_DATE_FILA                IN VARCHAR2,
    V_DEM_GENERAL           IN VARCHAR2,
    V_DEM_PREFERENCIAL   IN VARCHAR2,
    V_IND_VENTANILLA       IN VARCHAR2,
    V_ID_UID                      IN VARCHAR2,
    C_CALL_TICKET            OUT SYS_REFCURSOR,
    C_ESTADISTICAS          OUT SYS_REFCURSOR,
    C_STATUS                    OUT SYS_REFCURSOR,
    C_ERROR                       OUT SYS_REFCURSOR
    
) IS 

    V_FECHA_INICIO DATE                    := TO_DATE(V_DATE_FILA||' 00:00:00','DD-MM-YYYY hh24:mi:ss');
    V_FECHA_FINAL DATE                     := TO_DATE(V_DATE_FILA||' 23:59:59','DD-MM-YYYY hh24:mi:ss');
    OBJ_TOTEM_ANGOL OBJTIPOSISTEMATOTEM    := NEW OBJTIPOSISTEMATOTEM(V_EMPRESA);
    V_UNICO_HISTO_VENTANILLA NUMBER;
    V_DEMANDA_GENERAL NUMBER                           :=0;
    V_DEMANDA_PREFERENCIA NUMBER                    :=0;
    V_ALL_ATENCION_VENTANILLA NUMBER              :=  0;
    V_ALL_ATENCION_GENERAL NUMBER                   :=  0;
    V_ALL_ATENCION_PREFERENCIAL NUMBER           :=  0;
    TXT_OPCION_DETECTADA VARCHAR2(256);
    V_NUM_TOTAL NUMBER                                      :=0;
    V_NUM_GENERAL NUMBER                                   :=0;
    V_NUM_PREFERENCIAL NUMBER                           :=0;
    V_IND_LUZ_ESTADISTICA NUMBER                       :=-1;
    V_RESTUL_DIVISION NUMBER;
BEGIN

    --ESTADISTICA DE VENTANILLA
    OBJ_TOTEM_ANGOL.ESTADISTICA_X_VENTANILLA(V_EMPRESA,V_IND_VENTANILLA,V_FECHA_INICIO,V_FECHA_FINAL,V_NUM_TOTAL,V_NUM_GENERAL,V_NUM_PREFERENCIAL);

    SELECT 
    D.NUM_GENERAL,
    D.NUM_PREFERENCIAL
    INTO 
    V_DEMANDA_GENERAL,
    V_DEMANDA_PREFERENCIA
    FROM
    ADMIN.TO_DEMANDAXVENTANILLA D
    where
    D.ID_VENTANILLA IN (1)
    AND 
    D.IND_ESTADO IN (1);

    --AND MOD(V_DEMANDA_GENERAL,V_NUM_GENERAL)  = 0
    
    
    V_RESTUL_DIVISION := (V_NUM_TOTAL/V_DEMANDA_PREFERENCIA);
    
    
    
     IF  MOD(V_RESTUL_DIVISION, 1) <> 0  THEN
       TXT_OPCION_DETECTADA    := ' 1.- PÚBLICO PREFERENCIAL, 2- PÚBLICO GENERAL | NO ES ENTERO | ->VAL1 ->'||V_NUM_TOTAL || ' -VAL2 -> '|| V_DEMANDA_PREFERENCIA||'  =  '||V_RESTUL_DIVISION  ;
        C_CALL_TICKET                   :=  OBJ_TOTEM_ANGOL.LAST_TICKET_PRIORIDAD(1,V_IND_VENTANILLA,V_ID_UID);
        V_IND_LUZ_ESTADISTICA     := 1;
     ELSE
        TXT_OPCION_DETECTADA    := ' 1.-  DE PÚBLICO GENERAL, 2- PÚBLICO PREFERENCIAL | ES ENTERO -> VAL1 ->'||V_NUM_TOTAL || ' -VAL2 -> '|| V_DEMANDA_PREFERENCIA||'  =  '||V_RESTUL_DIVISION  ;
        C_CALL_TICKET                   :=  OBJ_TOTEM_ANGOL.LAST_TICKET_PRIORIDAD(0,V_IND_VENTANILLA,V_ID_UID);
        V_IND_LUZ_ESTADISTICA     := 0;
     END IF;
    
    OPEN C_ESTADISTICAS  FOR  
    SELECT 
        TXT_OPCION_DETECTADA        AS TXT_OPCION_DETECTADA,
        V_NUM_TOTAL                         AS V_NUM_TOTAL,
        V_NUM_GENERAL                     AS V_NUM_GENERAL,
        V_NUM_PREFERENCIAL             AS V_NUM_PREFERENCIAL
    FROM SYS.DUAL;
    
    OPEN C_STATUS  FOR  
        SELECT 
        TXT_OPCION_DETECTADA        AS TXT_OPCION_DETECTADA,
        V_IND_LUZ_ESTADISTICA  AS V_IND_LUZ_ESTADISTICA
     FROM SYS.DUAL;
    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        OPEN C_ERROR  FOR  SELECT 'SIN DATOS DE PLANIFICACIÓN'  AS TXT_ERROR FROM SYS.DUAL;
END;


PROCEDURE RECORD_HISTO_CALL(
    V_EMPRESA               IN VARCHAR2,
    V_NUM_FILA              IN VARCHAR2,
    V_IND_VENTANILLA    IN VARCHAR2,
    V_ID_UID                  IN VARCHAR2,
    C_STATUS               OUT SYS_REFCURSOR
) IS 
BEGIN
  --HISTORIAL DE LA VENTANILLA 
    INSERT INTO ADMIN.TO_HISTO_FARMVENTANILLA 
    (ID_HISTOVENTANILLA,ID_DEMANDA,ID_VENTANILLA,IND_OPCION,ID_NUMFILA,DATE_EVENTO,ID_UID) 
    VALUES 
    (ADMIN.SEQ_HISTOVENTANILLA.NEXTVAL,0,V_IND_VENTANILLA,0,V_NUM_FILA,SYSDATE,V_ID_UID);
    COMMIT;
END;
END HOSP_GESTION_TOTEMS;
/


COMMIT;