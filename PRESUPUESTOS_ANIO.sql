--- Santiago González González

CREATE OR REPLACE VIEW vistaEmplePres AS
SELECT e.emp_no, e.apellido, e.salario, e.comision,
       e.dept_no, (p.importe * 0.5) AS limiteSalariosDept
FROM EMPLEADOS E, PRESUPUESTOS P
WHERE e.dept_no = p.dept_no
  AND p.anio = TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'));


CREATE OR REPLACE TRIGGER gestionEmplePres
    INSTEAD OF INSERT OR UPDATE
    ON vistaEmplePres
    FOR EACH ROW
DECLARE
    vGastoActual NUMBER;
    vPresupuesto NUMBER;
    vGastoNuevo NUMBER;
BEGIN
    SELECT NVL(SUM(salario * 14 + NVL(comision, 0)), 0)
    INTO vGastoActual
    FROM EMPLEADOS
    WHERE dept_no = :NEW.dept_no;

    SELECT NVL(MAX(IMPORTE), 0)
    INTO vPresupuesto
    FROM PRESUPUESTOS
    WHERE dept_no = :NEW.dept_no
      AND anio = TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'));

    IF INSERTING THEN
        vGastoNuevo := vGastoActual + (:NEW.salario * 14 + NVL(:NEW.comision, 0));
    ELSIF UPDATING THEN
        vGastoNuevo := vGastoActual
                     - (:OLD.salario * 14 + NVL(:OLD.comision, 0))
                     + (:NEW.salario * 14 + NVL(:NEW.comision, 0));
    END IF;

    IF vGastoNuevo > (vPresupuesto * 0.5) THEN
        RAISE_APPLICATION_ERROR(-20006, 'El gasto salarial supera el 50% del presupuesto del departamento.');
    END IF;

    IF INSERTING THEN
        INSERT INTO EMPLEADOS (emp_no, apellido, salario, comision, dept_no)
        VALUES (:NEW.emp_no, :NEW.apellido, :NEW.salario, :NEW.comision, :NEW.dept_no);
    ELSIF UPDATING THEN
        UPDATE EMPLEADOS
        SET salario = :NEW.salario, comision = :NEW.comision
        WHERE emp_no = :NEW.emp_no;
    END IF;
END;
/
