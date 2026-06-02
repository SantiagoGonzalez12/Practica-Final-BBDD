--- Santiago González González

CREATE OR REPLACE VIEW vistaEmpPres AS
SELECT e.emp_no, e.apellido, (e.salario * 14 + e.comision) AS salarioAnual, e.dept_no, (p.importe * 0.5) AS limiteSalarioDept
FROM empleados e, presupuestos p
WHERE e.dept_no = p.dept_no;

CREATE OR REPLACE TRIGGER gestionEmpPresupuesto
    INSTEAD OF INSERT OR UPDATE
    ON vistaEmpPres
    FOR EACH ROW
DECLARE 
    vSumaSalarios NUMBER;
    vPresupuesto NUMBER;
BEGIN
    
    IF INSERTING THEN
        IF :NEW.emp_no IS NOT NULL THEN
            INSERT INTO empleados (emp_no, apellido, salario, comision, dept_no)
            VALUES (:NEW.emp_no, :NEW.apellido, :NEW.salarioAnual / 14, 0, :NEW.dept_no);
        END IF;

        IF :NEW.limiteSalarioDept IS NOT NULL THEN
            INSERT INTO presupuestos (dept_no, anio, importe)
            VALUES (:NEW.dept_no, TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY')), :NEW.limiteSalarioDept / 0.5);
        END IF;

    ELSIF UPDATING THEN
        IF UPDATING('salarioAnual') THEN
            UPDATE empleados
            SET salario = :NEW.salarioAnual / 14
            WHERE emp_no = :NEW.emp_no;
        END IF;
        
        IF UPDATING('limiteSalarioDept') THEN
            UPDATE presupuestos
            SET importe = :NEW.limiteSalarioDept / 0.5
            WHERE dept_no = :NEW.dept_no
              AND anio = TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'));
        END IF;
    END IF;

    SELECT NVL(SUM(salario * 14 + NVL(comision, 0)), 0) INTO vSumaSalarios
    FROM empleados
    WHERE dept_no = :NEW.dept_no;

    SELECT NVL(importe, 0) INTO vPresupuesto
    FROM presupuestos
    WHERE dept_no = :NEW.dept_no
      AND anio = TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'));

    IF vSumaSalarios > (vPresupuesto * 0.5) THEN 
        RAISE_APPLICATION_ERROR(-20006, 'Operación denegada: Los salarios del departamento superan el 50% del presupuesto disponible.');
    END IF;
END;
/
