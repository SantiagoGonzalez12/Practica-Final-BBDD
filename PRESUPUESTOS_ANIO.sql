CREATE OR REPLACE TRIGGER empPresupuesto
    BEFORE INSERT OR UPDATE 
    OF SALARIO, DEPT_NO
    ON EMPLEADOS
    FOR EACH ROW
DECLARE 
    limite NUMBER;
    actual NUMBER;

BEGIN
    BEGIN
        SELECT (importe * 0.5) INTO limite
        FROM PRESUPUESTOS
        WHERE DEPT_NO = :new.DEPT_NO
            AND anio = TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'));
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                limite := 0;
    END;

    SELECT NVL(SUM(salario), 0) INTO actual
    FROM EMPLEADOS 
    WHERE DEPT_NO = :new.DEPT_NO
        AND EMP_NO <> NVL(:new.EMP_NO, -1);

    IF (actual + new.salario) > limite THEN 
        RAISE_APPLICATION_ERROR()

END;





CREATE OR REPLACE TRIGGER empPresupuesto
    AFTER INSERT OR UPDATE 
    ON EMPLEADOS
DECLARE 
    errores NUMBER;

BEGIN
    SELECT COUNT(*) INTO errores
    FROM (
        SELECT e.dept_no
        FROM empleados e, presupuestos p
        WHERE e.dept_no = p.dept_no
            AND p.anio = TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'))
        GROUP BY e.dept_no, p.importe
        HAVING SUM(e.salario) > (p.importe * 0.5)
    );

    IF errores > 0 THEN 
        RAISE_APPLICATION_ERROR(-2001, 'El salario no puede exceder el 50% del presupuesto actual.')
    END IF;
END;

CREATE OR REPLACE VIEW vistaEmpPres AS
SELECT e.emp_no, e.apellido, e.salario, e.dept_no, (p.importe * 0.5) AS limiteSalarioDept
FROM empleados e, presupuestos p
WHERE e.dept_no = p.dept_no


CREATE OR REPLACE TRIGGER presLimite
    AFTER INSERT OR UPDATE 
    ON PRESUPUESTOS
DECLARE 
    errores NUMBER;

BEGIN
    SELECT COUNT(*) INTO errores
    FROM (
        SELECT e.dept_no
        FROM empleados e, presupuestos p
        WHERE e.dept_no = p.dept_no
            AND p.anio = TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'))
        GROUP BY e.dept_no, p.importe
        HAVING SUM(e.salario) > (p.importe * 0.5)
    );

    IF errores > 0 THEN 
        RAISE_APPLICATION_ERROR(-2002, 'El nuevo presupuesto no cubre el doble de los salarios actuales.')
    END IF;
END;