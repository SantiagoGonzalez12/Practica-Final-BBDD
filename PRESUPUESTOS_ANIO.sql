--- Santiago González González

CREATE OR REPLACE VIEW vistaEmpPres AS
SELECT e.emp_no, e.apellido, (e.salario * 14 + e.comision) AS salarioAnual, e.dept_no, (p.importe * 0.5) AS limiteSalarioDept
FROM empleados e, presupuestos p
WHERE e.dept_no = p.dept_no;

CREATE OR REPLACE TRIGGER empPresupuesto
    INSTEAD OF INSERT
    ON vistaEmpPres
    FOR EACH ROW
DECLARE 
    vSumaSalarios NUMBER;
    vPresupuesto NUMBER;
BEGIN
    SELECT NVL(SUM(salario * 14 + NVL(comision, 0)), 0) INTO vSumaSalarios
    FROM empleados
    WHERE dept_no = :NEW.dept_no;

    SELECT NVL(importe, 0) INTO vPresupuesto
    FROM presupuestos
    WHERE dept_no = :NEW.dept_no
      AND anio = TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'));

    IF vSumaSalarios > (vPresupuesto * 0.5) THEN 
        RAISE_APPLICATION_ERROR(-20006, 'El salario no puede exceder el 50% del presupuesto actual.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER presLimite
    INSTEAD OF UPDATE
    ON vistaEmpPres
    FOR EACH ROW
DECLARE 
    vSumaSalarios NUMBER;
    vPresupuesto NUMBER;
BEGIN
    SELECT NVL(SUM(salario * 14 + NVL(comision, 0)), 0) INTO vSumaSalarios
    FROM empleados
    WHERE dept_no = :NEW.dept_no;

    SELECT NVL(importe, 0) INTO vPresupuesto
    FROM presupuestos
    WHERE dept_no = :NEW.dept_no
      AND anio = TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'));

    IF vSumaSalarios > (vPresupuesto * 0.5) THEN 
        RAISE_APPLICATION_ERROR(-20007, 'El nuevo presupuesto no cubre el doble de los salarios actuales.');
    END IF;
END;
/
