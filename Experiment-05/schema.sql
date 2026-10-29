-- =====================================================================
-- DBMS Practical File - Experiment 05
-- Title: SQL Views, View Updatability and Recursive CTE
-- Database: CompanyDB
-- =====================================================================

USE CompanyDB;

-- =====================================================================
-- 1. EXTEND EMPLOYEE SCHEMA FOR REPORTING HIERARCHY
-- =====================================================================

-- Add self-referencing Manager_ID column
ALTER TABLE Employee
ADD COLUMN Manager_ID INT NULL;

-- Add self-referencing Foreign Key constraint
ALTER TABLE Employee
ADD CONSTRAINT fk_employee_manager
FOREIGN KEY (Manager_ID) REFERENCES Employee(Emp_ID);

-- Assign Sample Reporting Hierarchy:
-- Department 1: Artificial Intelligence
UPDATE Employee SET Manager_ID = NULL WHERE Emp_ID = 101; 
UPDATE Employee SET Manager_ID = 101 WHERE Emp_ID IN (102, 103); 
UPDATE Employee SET Manager_ID = 102 WHERE Emp_ID IN (104, 105); 
UPDATE Employee SET Manager_ID = 103 WHERE Emp_ID = 106;

-- Department 2: Software Development
UPDATE Employee SET Manager_ID = NULL WHERE Emp_ID = 110; 
UPDATE Employee SET Manager_ID = 110 WHERE Emp_ID IN (107, 108); 
UPDATE Employee SET Manager_ID = 107 WHERE Emp_ID IN (109, 111); 
UPDATE Employee SET Manager_ID = 108 WHERE Emp_ID = 112;

-- Department 3: Cyber Security
UPDATE Employee SET Manager_ID = NULL WHERE Emp_ID = 115; 
UPDATE Employee SET Manager_ID = 115 WHERE Emp_ID IN (113, 114); 
UPDATE Employee SET Manager_ID = 113 WHERE Emp_ID IN (117, 118); 
UPDATE Employee SET Manager_ID = 114 WHERE Emp_ID = 116;

-- Department 4: Data Science
UPDATE Employee SET Manager_ID = NULL WHERE Emp_ID = 119; 
UPDATE Employee SET Manager_ID = 119 WHERE Emp_ID IN (120, 121);
UPDATE Employee SET Manager_ID = 120 WHERE Emp_ID IN (122, 123); 
UPDATE Employee SET Manager_ID = 121 WHERE Emp_ID = 124;

-- Department 5: Human Resources
UPDATE Employee SET Manager_ID = NULL WHERE Emp_ID = 125; 
UPDATE Employee SET Manager_ID = 125 WHERE Emp_ID IN (126, 129);
UPDATE Employee SET Manager_ID = 126 WHERE Emp_ID IN (127, 128, 130);

-- =====================================================================
-- 2. CREATE SQL VIEWS
-- =====================================================================

-- View 1: Department Salary Summary (Aggregates + GROUP BY)
CREATE OR REPLACE VIEW Department_Salary_Summary AS 
SELECT d.Dept_ID,
       d.Dept_Name,
       COUNT(e.Emp_ID) AS Employee_Count, 
       SUM(e.Salary) AS Total_Salary, 
       AVG(e.Salary) AS Average_Salary, 
       MIN(e.Salary) AS Minimum_Salary, 
       MAX(e.Salary) AS Maximum_Salary
FROM Department d
LEFT JOIN Employee e ON d.Dept_ID = e.Dept_ID 
GROUP BY d.Dept_ID, d.Dept_Name;

-- Display View 1
SELECT * FROM Department_Salary_Summary;

-- View 2: Employee Hierarchy View (Multi-table JOINs)
CREATE OR REPLACE VIEW Employee_Hierarchy AS 
SELECT e.Emp_ID,
       e.Emp_Name AS Employee_Name, 
       e.Job_Title,
       e.Dept_ID, 
       d.Dept_Name, 
       e.Manager_ID,
       m.Emp_Name AS Manager_Name
FROM Employee e
LEFT JOIN Department d ON e.Dept_ID = d.Dept_ID 
LEFT JOIN Employee m ON e.Manager_ID = m.Emp_ID;

-- Display View 2
SELECT *
FROM Employee_Hierarchy
ORDER BY Dept_ID, Manager_ID, Emp_ID;

-- View 3: Simple Base Projection View
CREATE OR REPLACE VIEW Employee_Basic AS
SELECT Emp_ID, Emp_Name, Job_Title, Salary, Dept_ID 
FROM Employee;

-- =====================================================================
-- 3. TEST VIEW UPDATABILITY
-- =====================================================================

-- Test 1: Update through Simple View (Succeeds)
UPDATE Employee_Basic 
SET Salary = 86000 
WHERE Emp_ID = 101;

-- Verify base table reflects update
SELECT Emp_ID, Emp_Name, Salary 
FROM Employee
WHERE Emp_ID = 101;

-- Test 2: Update through Aggregate View (Fails with Error 1288)
-- Expected error: The target table Department_Salary_Summary of the UPDATE is not updatable
-- UPDATE Department_Salary_Summary 
-- SET Average_Salary = 90000 
-- WHERE Dept_ID = 1;

-- Test 3: Update through Multi-Table Join View (Fails)
-- Expected error: Cannot modify derived column from joined table
-- UPDATE Employee_Hierarchy
-- SET Manager_Name = 'Priya Verma' 
-- WHERE Emp_ID = 103;

-- Inspect View Definitions in Data Dictionary
SHOW CREATE VIEW Department_Salary_Summary; 
SHOW CREATE VIEW Employee_Hierarchy;
SHOW CREATE VIEW Employee_Basic;

-- =====================================================================
-- 4. RECURSIVE COMMON TABLE EXPRESSIONS (CTE)
-- =====================================================================

-- Query 8: Full Organization Reporting Chain
WITH RECURSIVE EmployeeChain AS ( 
    -- Anchor Member: Top-level managers with no supervisor
    SELECT
        e.Emp_ID, 
        e.Emp_Name, 
        e.Manager_ID,
        0 AS Level,
        CAST(e.Emp_Name AS CHAR(1000)) AS Reporting_Chain 
    FROM Employee e
    WHERE e.Manager_ID IS NULL

    UNION ALL

    -- Recursive Member: Subordinates referencing supervisor
    SELECT
        e.Emp_ID, 
        e.Emp_Name, 
        e.Manager_ID, 
        ec.Level + 1,
        CONCAT(ec.Reporting_Chain, ' -> ', e.Emp_Name) 
    FROM Employee e
    INNER JOIN EmployeeChain ec ON e.Manager_ID = ec.Emp_ID
)
SELECT Emp_ID, Emp_Name, Manager_ID, Level, Reporting_Chain 
FROM EmployeeChain
ORDER BY Reporting_Chain;

-- Query 9: Single Reporting Subtree (rooted at Emp_ID = 101)
WITH RECURSIVE ReportingTree AS (
    SELECT Emp_ID, Emp_Name, Manager_ID, 0 AS Level 
    FROM Employee
    WHERE Emp_ID = 101 

    UNION ALL

    SELECT e.Emp_ID, e.Emp_Name, e.Manager_ID, rt.Level + 1 
    FROM Employee e
    INNER JOIN ReportingTree rt ON e.Manager_ID = rt.Emp_ID
)
SELECT Emp_ID, Emp_Name, Manager_ID, Level 
FROM ReportingTree
ORDER BY Level, Emp_ID;

-- Query 10: Hierarchy Tree with Visual Indentation
WITH RECURSIVE EmployeeTree AS (
    SELECT Emp_ID, Emp_Name, Manager_ID, 0 AS Level 
    FROM Employee
    WHERE Manager_ID IS NULL 

    UNION ALL

    SELECT e.Emp_ID, e.Emp_Name, e.Manager_ID, et.Level + 1 
    FROM Employee e
    INNER JOIN EmployeeTree et ON e.Manager_ID = et.Emp_ID
)
SELECT Emp_ID,
       CONCAT(REPEAT('  ', Level), Emp_Name) AS Employee_Hierarchy, 
       Level
FROM EmployeeTree
ORDER BY Level, Emp_ID;

-- Query 11: Direct Verification of Employee-Manager pairs
SELECT e.Emp_Name AS Employee, 
       m.Emp_Name AS Manager
FROM Employee e
LEFT JOIN Employee m ON e.Manager_ID = m.Emp_ID 
ORDER BY e.Emp_ID;
