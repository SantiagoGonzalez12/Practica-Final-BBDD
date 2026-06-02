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
    WHERE dept_no = :new.dept_no;

    SELECT NVL(MAX(IMPORTE), 0)
    INTO vPresupuesto
    FROM PRESUPUESTOS
    WHERE dept_no = :new.dept_no
      AND anio = TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'));

    IF INSERTING THEN
        vGastoNuevo := vGastoActual + (:new.salario * 14 + NVL(:new.comision, 0));
    ELSIF UPDATING THEN
        vGastoNuevo := vGastoActual
                     - (:old.salario * 14 + NVL(:old.comision, 0))
                     + (:new.salario * 14 + NVL(:new.comision, 0));
    END IF;

    IF vGastoNuevo > (vPresupuesto * 0.5) THEN
        RAISE_APPLICATION_ERROR(-20006, 'El gasto salarial supera el 50% del presupuesto del departamento.');
    END IF;

    IF INSERTING THEN
        INSERT INTO EMPLEADOS (emp_no, apellido, salario, comision, dept_no)
        VALUES (:new.emp_no, :new.apellido, :new.salario, :new.comision, :new.dept_no);
    ELSIF UPDATING THEN
        UPDATE EMPLEADOS
        SET salario = :new.salario, comision = :new.comision
        WHERE emp_no = :new.emp_no;
    END IF;
END;
/
