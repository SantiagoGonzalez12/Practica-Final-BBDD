--- Santiago González González

CREATE OR REPLACE VIEW vistaEmpPres AS
SELECT e.emp_no, e.apellido, e.salario, e.comision, e.dept_no, (p.importe * 0.5) AS limiteSalarioDept
FROM empleados e, presupuestos p
WHERE e.dept_no = p.dept_no;


CREATE OR REPLACE TRIGGER gestionEmpPresupuesto
    INSTEAD OF INSERT OR UPDATE
    ON vistaEmpPres
    FOR EACH ROW
DECLARE 
    vSumaSalariosAnuales NUMBER;
    vPresupuesto NUMBER;
BEGIN

    IF INSERTING THEN
        IF :NEW.emp_no IS NOT NULL THEN
            INSERT INTO empleados (emp_no, apellido, salario, comision, dept_no)
            VALUES (:NEW.emp_no, :NEW.apellido, :NEW.salario, :NEW.comision, :NEW.dept_no);
        END IF;

        IF :NEW.limiteSalarioDept IS NOT NULL THEN
            INSERT INTO presupuestos (dept_no, anio, importe)
            VALUES (:NEW.dept_no, TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY')), :NEW.limiteSalarioDept / 0.5);
        END IF;

    ELSIF UPDATING THEN
        IF UPDATING('salario') THEN
            UPDATE empleados SET salario = :NEW.salario WHERE emp_no = :NEW.emp_no;
        END IF;
        
        IF UPDATING('comision') THEN
            UPDATE empleados SET comision = :NEW.comision WHERE emp_no = :NEW.emp_no;
        END IF;
        
        IF UPDATING('limiteSalarioDept') THEN
            UPDATE presupuestos
            SET importe = :NEW.limiteSalarioDept / 0.5
            WHERE dept_no = :NEW.dept_no
              AND anio = TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'));
        END IF;
    END IF;

    SELECT NVL(SUM(salario * 14 + NVL(comision, 0)), 0) INTO vSumaSalariosAnuales
    FROM empleados
    WHERE dept_no = :NEW.dept_no;

    SELECT NVL(importe, 0) INTO vPresupuesto
    FROM presupuestos
    WHERE dept_no = :NEW.dept_no
      AND anio = TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'));

    IF vSumaSalariosAnuales > (vPresupuesto * 0.5) THEN 
        RAISE_APPLICATION_ERROR(-20006, 'Operación denegada: El coste anual supera el 50% del presupuesto.');
    END IF;
END;
/
