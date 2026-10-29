# Experiment - 6

## Title
**Stored Procedures, Triggers & Audit Logging**

### Subtitle
*Enterprise Data Validation, Transactional Error Handling, and Automated Audit Trails*

**Author**: Saksham Dubey  
**Roll No**: 25LBCS3326  

---

## 1. Aim & System Requirements

### Aim
To implement an enterprise stored procedure `transfer_employee(emp_id, new_dept_id)` with transactional consistency and exception handling, enforce business validation constraints via `BEFORE INSERT` and `BEFORE UPDATE` triggers, and establish an automated audit trail using an `AFTER UPDATE` trigger on employee salary changes.

### Software Environment
- **Database Engine**: MySQL Server 8.0+ / MySQL Workbench
- **Operating Systems**: Windows, Linux, or macOS
- **Database Architecture**: `CompanyDB` schema containing `Employee`, `Department`, and `Salary_Audit` tables.

---

## 2. Theoretical Foundation

- **Stored Procedures**: Precompiled collections of SQL statements stored directly in the database catalog. They support input/output parameters, procedural flow control (`IF-ELSE`), transactional boundary management (`START TRANSACTION`, `COMMIT`, `ROLLBACK`), and structured exception handling (`DECLARE ... HANDLER`).
- **BEFORE Triggers**: Event-driven procedural blocks executed automatically *before* data persistence occurs. Ideal for intercepting data mutations, enforcing domain-specific validation constraints, and raising exceptions (`SIGNAL SQLSTATE '45000'`) to prevent illegal database states.
- **AFTER Triggers**: Procedural logic executed immediately *after* a successful mutation has been applied. Best suited for creating immutable, tamper-resistant historical audit logs without interfering with the primary mutation logic.
- **NULL-Safe Equality Operator (`<=>`)**: Performs an equality comparison that evaluates to `TRUE` even if both compared values are `NULL`, preventing false triggers and properly detecting genuine delta transitions.

---

## 3. Schema Verification & Initial Benchmark State

```sql
USE CompanyDB;
DESC Employee;
DESC Department;
SELECT Emp_ID, Emp_Name, Salary, Dept_ID FROM Employee ORDER BY Emp_ID;
SELECT Dept_ID, Dept_Name FROM Department ORDER BY Dept_ID;
```

### Initial Employee Benchmark Records

| Emp_ID | Emp_Name | Salary (INR) | Dept_ID |
| :---: | :--- | :---: | :--- |
| **101** | Aditi Rathore | 88,000.00 | 1 (Artificial Intelligence) |
| **102** | Kabir Malhotra | 96,000.00 | 1 (Artificial Intelligence) |
| **103** | Ishaan Trivedi | 91,000.00 | 1 (Artificial Intelligence) |
| **104** | Meera Iyer | 112,000.00 | 1 (Artificial Intelligence) |
| **105** | Pranav Deshmukh | 84,000.00 | 1 (Artificial Intelligence) |
| **130** | Deepak Chawla | 82,000.00 | 5 (Human Resources) |

---

## 4. Database Trigger & Audit Implementation

The complete SQL script is available in [`schema.sql`](./schema.sql).

### 4.1 Salary Audit History Relation

```sql
CREATE TABLE IF NOT EXISTS Salary_Audit (
    Audit_ID INT AUTO_INCREMENT PRIMARY KEY,
    Emp_ID INT NOT NULL,
    Old_Salary DECIMAL(10,2) NOT NULL,
    New_Salary DECIMAL(10,2) NOT NULL,
    Changed_At TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Changed_By VARCHAR(100) NOT NULL
);
```

### 4.2 Salary Validation Triggers (`BEFORE INSERT` & `BEFORE UPDATE`)

Ensures that no employee salary is persisted as `NULL` or outside the acceptable corporate boundary of **₹30,000 to ₹300,000**:

```sql
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
```

### 4.3 Automated Audit Trail Trigger (`AFTER UPDATE`)

Captures every genuine change in an employee's salary and records the previous salary, updated salary, timestamp, and executing database user:

```sql
DROP TRIGGER IF EXISTS trg_employee_salary_audit;
DELIMITER $$
CREATE TRIGGER trg_employee_salary_audit
AFTER UPDATE ON Employee FOR EACH ROW
BEGIN
    IF NOT (OLD.Salary <=> NEW.Salary) THEN
        INSERT INTO Salary_Audit (Emp_ID, Old_Salary, New_Salary, Changed_By)
        VALUES (NEW.Emp_ID, OLD.Salary, NEW.Salary, CURRENT_USER());
    END IF;
END$$
DELIMITER ;
```

---

## 5. Transactional Stored Procedure Implementation

The stored procedure `transfer_employee` implements:
1. **Pessimistic Row Locking** (`FOR UPDATE`) to prevent race conditions during department reassignment.
2. **Defensive Validation Checks**:
   - Ensures the specified employee exists.
   - Ensures the target department exists.
   - Prevents redundant reassignment to the employee's current department.
3. **Atomic Execution**: An `EXIT HANDLER FOR SQLEXCEPTION` automatically executes a `ROLLBACK` and resignals the error if any statement fails.

```sql
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

    -- Error Handling: Rollback on exception
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Validate employee existence and lock row
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

    -- Prevent redundant reassignment
    IF v_old_dept_id = p_new_dept_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Employee is already in the requested department';
    END IF;

    -- Execute transfer
    UPDATE Employee SET Dept_ID = p_new_dept_id WHERE Emp_ID = p_emp_id;

    COMMIT;

    SELECT CONCAT('Employee ', v_emp_name, ' transferred successfully to Department ', p_new_dept_id) AS Message;
END$$
DELIMITER ;
```

---

## 6. Practical Validation, Edge Cases & Execution Outputs

### 6.1 Stored Procedure Execution Tests (Normal & Edge Cases)

```sql
-- Test 1: Valid Transfer (Employee 101 to Dept 2)
CALL transfer_employee(101, 2);
SELECT Emp_ID, Emp_Name, Dept_ID FROM Employee WHERE Emp_ID = 101;

-- Test 2: Edge Case - Non-Existing Employee (Emp_ID = 999)
CALL transfer_employee(999, 2);

-- Test 3: Edge Case - Non-Existing Department (Dept_ID = 99)
CALL transfer_employee(101, 99);

-- Test 4: Edge Case - Redundant Transfer to Same Department
CALL transfer_employee(101, 2);
```

#### Results Summary:

| Test Case | Invoked Statement | Observed System Message | Status |
| :--- | :--- | :--- | :---: |
| **Valid Transfer** | `CALL transfer_employee(101, 2);` | `Employee Aditi Rathore transferred successfully to Department 2` | **Success** |
| **Invalid Employee** | `CALL transfer_employee(999, 2);` | `Error Code: 1644. Employee does not exist` | **Rolled Back** |
| **Invalid Dept** | `CALL transfer_employee(101, 99);` | `Error Code: 1644. Destination department does not exist` | **Rolled Back** |
| **Same Dept** | `CALL transfer_employee(101, 2);` | `Error Code: 1644. Employee is already in the requested department` | **Rolled Back** |

---

### 6.2 Salary Validation Trigger Boundary Tests

```sql
-- Test Valid Update
UPDATE Employee SET Salary = 90000 WHERE Emp_ID = 102;

-- Test Below Minimum Threshold (< 30,000)
UPDATE Employee SET Salary = 25000 WHERE Emp_ID = 102;

-- Test Above Maximum Threshold (> 300,000)
UPDATE Employee SET Salary = 500000 WHERE Emp_ID = 102;

-- Test NULL Violation
UPDATE Employee SET Salary = NULL WHERE Emp_ID = 102;
```

#### Results Summary:

| Validation Scenario | SQL Mutation Statement | Engine Response | Verdict |
| :--- | :--- | :--- | :---: |
| **Valid Range (₹90,000)** | `UPDATE Employee SET Salary = 90000 WHERE Emp_ID = 102;` | `1 row(s) updated successfully` | **Passed** |
| **Below Minimum (₹25,000)** | `UPDATE Employee SET Salary = 25000 WHERE Emp_ID = 102;` | `Error Code: 1644. Salary must be between 30000 and 300000` | **Rejected** |
| **Above Maximum (₹500,000)**| `UPDATE Employee SET Salary = 500000 WHERE Emp_ID = 102;` | `Error Code: 1644. Salary must be between 30000 and 300000` | **Rejected** |
| **NULL Value Constraint** | `UPDATE Employee SET Salary = NULL WHERE Emp_ID = 102;` | `Error Code: 1644. Salary cannot be NULL` | **Rejected** |

---

### 6.3 Salary Audit Trail Verification

```sql
-- Trigger salary change and verify audit logging
UPDATE Employee SET Salary = 95000 WHERE Emp_ID = 102;

-- Redundant update to ensure unchanged salaries are ignored
UPDATE Employee SET Salary = 95000 WHERE Emp_ID = 102;

-- Inspect audit log
SELECT Audit_ID, Emp_ID, Old_Salary, New_Salary, Changed_At, Changed_By
FROM Salary_Audit WHERE Emp_ID = 102 ORDER BY Audit_ID DESC;
```

#### Output:

```text
+----------+--------+------------+------------+---------------------+----------------+
| Audit_ID | Emp_ID | Old_Salary | New_Salary | Changed_At          | Changed_By     |
+----------+--------+------------+------------+---------------------+----------------+
|        2 |    102 |   90000.00 |   95000.00 | 2026-10-07 21:30:15 | root@localhost |
|        1 |    102 |   96000.00 |   90000.00 | 2026-10-07 21:28:42 | root@localhost |
+----------+--------+------------+------------+---------------------+----------------+
```

> **Key Verification**: The redundant mutation (`UPDATE Employee SET Salary = 95000 ...`) when the salary was already `95000` did **not** generate a superfluous audit record, confirming that the NULL-safe condition `IF NOT (OLD.Salary <=> NEW.Salary)` successfully suppresses redundant log entries.

---

## 7. Conclusion & Key Observations

- The stored procedure `transfer_employee` successfully implemented **transactional control with structured exception handling**, guaranteeing atomic execution and immediate rollback upon encountering invalid inputs or unexpected exceptions.
- The **`BEFORE` triggers** rigorously intercepted and prevented invalid salary mutations outside prescribed business thresholds (`₹30,000 - ₹300,000`) and disbarred `NULL` inputs prior to storage.
- The **`AFTER UPDATE` trigger** maintained an accurate, tamper-resistant historical log in `Salary_Audit`, ensuring full enterprise compliance and auditability while ignoring duplicate, zero-delta modifications.
