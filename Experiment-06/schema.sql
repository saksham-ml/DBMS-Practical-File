-- =====================================================================
-- DBMS Practical File - Experiment 06
-- Title: Stored Procedures, Triggers & Audit Logging
-- Subtitle: Enterprise Data Validation, Transactional Error Handling, and Automated Audit Trails
-- Database: CompanyDB
-- Student: Saksham Dubey (25LBCS3326)
-- =====================================================================

USE CompanyDB;

-- =====================================================================
-- 1. AUDIT HISTORY RELATION
-- =====================================================================

CREATE TABLE IF NOT EXISTS Salary_Audit (
    Audit_ID INT AUTO_INCREMENT PRIMARY KEY,
    Emp_ID INT NOT NULL,
    Old_Salary DECIMAL(10,2) NOT NULL,
    New_Salary DECIMAL(10,2) NOT NULL,
    Changed_At TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Changed_By VARCHAR(100) NOT NULL
);

-- =====================================================================
-- 2. SALARY VALIDATION TRIGGERS (BEFORE INSERT & UPDATE)
-- =====================================================================

-- BEFORE INSERT Salary Validator
DROP TRIGGER IF EXISTS trg_employee_salary_insert;
DELIMITER $$
CREATE TRIGGER trg_employee_salary_insert
BEFORE INSERT ON Employee FOR EACH ROW
BEGIN
    IF NEW.Salary IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salary cannot be NULL';
    END IF;
    IF NEW.Salary < 30000 OR NEW.Salary > 300000 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salary must be between 30000 and 300000';
    END IF;
END$$
DELIMITER ;

-- BEFORE UPDATE Salary Validator
DROP TRIGGER IF EXISTS trg_employee_salary_update;
DELIMITER $$
CREATE TRIGGER trg_employee_salary_update
BEFORE UPDATE ON Employee FOR EACH ROW
BEGIN
    IF NEW.Salary IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salary cannot be NULL';
    END IF;
    IF NEW.Salary < 30000 OR NEW.Salary > 300000 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salary must be between 30000 and 300000';
    END IF;
END$$
DELIMITER ;

-- =====================================================================
-- 3. AUTOMATED AUDIT TRAIL TRIGGER (AFTER UPDATE)
-- =====================================================================

DROP TRIGGER IF EXISTS trg_employee_salary_audit;
DELIMITER $$
CREATE TRIGGER trg_employee_salary_audit
AFTER UPDATE ON Employee FOR EACH ROW
BEGIN
    -- NULL-Safe Equality (<=>) ensures changes are detected and identical updates ignored
    IF NOT (OLD.Salary <=> NEW.Salary) THEN
        INSERT INTO Salary_Audit (Emp_ID, Old_Salary, New_Salary, Changed_By)
        VALUES (NEW.Emp_ID, OLD.Salary, NEW.Salary, CURRENT_USER());
    END IF;
END$$
DELIMITER ;

-- =====================================================================
-- 4. TRANSACTIONAL STORED PROCEDURE IMPLEMENTATION
-- =====================================================================

DROP PROCEDURE IF EXISTS transfer_employee;
DELIMITER $$
CREATE PROCEDURE transfer_employee(
    IN p_emp_id INT,
    IN p_new_dept_id INT
)
BEGIN
    DECLARE v_old_dept_id INT;
    DECLARE v_emp_name VARCHAR(50);
    DECLARE v_dummy INT;

    -- Structured Exception Handling: Automatic Rollback on error
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Validate employee existence and acquire pessimistic row lock
    SELECT Emp_Name, Dept_ID INTO v_emp_name, v_old_dept_id
    FROM Employee WHERE Emp_ID = p_emp_id FOR UPDATE;

    IF v_emp_name IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Employee does not exist';
    END IF;

    -- Validate destination department existence
    SELECT Dept_ID INTO v_dummy 
    FROM Department 
    WHERE Dept_ID = p_new_dept_id;

    IF v_dummy IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Destination department does not exist';
    END IF;

    -- Prevent redundant department reassignment
    IF v_old_dept_id = p_new_dept_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Employee is already in the requested department';
    END IF;

    -- Execute department transfer
    UPDATE Employee SET Dept_ID = p_new_dept_id WHERE Emp_ID = p_emp_id;

    COMMIT;

    SELECT CONCAT('Employee ', v_emp_name, ' transferred successfully to Department ', p_new_dept_id) AS Message;
END$$
DELIMITER ;

-- =====================================================================
-- 5. PRACTICAL VALIDATION TESTS & VERIFICATIONS
-- =====================================================================

-- Test 1: Valid Department Transfer
-- CALL transfer_employee(101, 2);
-- SELECT Emp_ID, Emp_Name, Dept_ID FROM Employee WHERE Emp_ID = 101;

-- Test 2: Non-Existing Employee (Rollback test)
-- CALL transfer_employee(999, 2);

-- Test 3: Non-Existing Department (Rollback test)
-- CALL transfer_employee(101, 99);

-- Test 4: Redundant Transfer to Same Department
-- CALL transfer_employee(101, 2);

-- Test 5: Salary Boundary Validation Triggers
-- UPDATE Employee SET Salary = 90000 WHERE Emp_ID = 102;   -- Valid (Passes)
-- UPDATE Employee SET Salary = 25000 WHERE Emp_ID = 102;   -- < 30000 (Fails)
-- UPDATE Employee SET Salary = 500000 WHERE Emp_ID = 102;  -- > 300000 (Fails)
-- UPDATE Employee SET Salary = NULL WHERE Emp_ID = 102;    -- NULL (Fails)

-- Test 6: Audit Trail Verification
-- UPDATE Employee SET Salary = 95000 WHERE Emp_ID = 102;   -- Trigger fired
-- UPDATE Employee SET Salary = 95000 WHERE Emp_ID = 102;   -- Identical (Ignored)
-- SELECT * FROM Salary_Audit WHERE Emp_ID = 102 ORDER BY Audit_ID DESC;
