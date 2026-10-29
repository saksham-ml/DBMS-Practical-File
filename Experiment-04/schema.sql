-- =====================================================================
-- DBMS Practical File - Experiment 04
-- Title: Advanced SQL Queries and Execution Plans
-- Database: CompanyDB
-- =====================================================================

USE CompanyDB;

-- =====================================================================
-- 1. ADVANCED JOINS
-- =====================================================================

-- 1. INNER JOIN: Display employees along with their department names
SELECT e.Emp_ID, e.Emp_Name, e.Job_Title, d.Dept_Name
FROM Employee e
INNER JOIN Department d ON e.Dept_ID = d.Dept_ID;

-- 2. LEFT JOIN: Display all departments and employees (preserving unassigned departments)
SELECT d.Dept_ID, d.Dept_Name, e.Emp_Name
FROM Department d 
LEFT JOIN Employee e ON d.Dept_ID = e.Dept_ID;

-- 3. SELF JOIN: Find pairs of employees working in the same department
-- Condition e1.Emp_ID < e2.Emp_ID eliminates duplicate combinations and self-pairing
SELECT e1.Emp_Name AS Employee_1, e2.Emp_Name AS Employee_2, e1.Dept_ID
FROM Employee e1 
INNER JOIN Employee e2 ON e1.Dept_ID = e2.Dept_ID AND e1.Emp_ID < e2.Emp_ID;

-- 4. MULTI-TABLE / 4-WAY JOIN: Employee, Department, Bridge Table & Project
SELECT e.Emp_Name, d.Dept_Name, p.Project_Name
FROM Employee e
INNER JOIN Department d ON e.Dept_ID = d.Dept_ID
INNER JOIN Employee_Project ep ON e.Emp_ID = ep.Emp_ID
INNER JOIN Project p ON ep.Project_ID = p.Project_ID;

-- =====================================================================
-- 2. SUBQUERIES & SET SIMULATIONS
-- =====================================================================

-- 5. CORRELATED SUBQUERY: Employees earning above their own department's average salary
SELECT e.Emp_ID, e.Emp_Name, e.Salary, e.Dept_ID
FROM Employee e 
WHERE e.Salary > (
    SELECT AVG(e2.Salary) 
    FROM Employee e2
    WHERE e2.Dept_ID = e.Dept_ID
);

-- 6. EXISTS: Departments having at least one employee earning > 100,000
SELECT d.Dept_ID, d.Dept_Name
FROM Department d 
WHERE EXISTS (
    SELECT 1
    FROM Employee e
    WHERE e.Dept_ID = d.Dept_ID 
    AND e.Salary > 100000
);

-- 7. SIMULATED INTERSECT (using INNER JOIN between subqueries):
-- Employees earning > 80,000 INTERSECT belonging to AI (Dept 1) or Data Science (Dept 4)
SELECT a.Emp_ID, a.Emp_Name
FROM (
    SELECT Emp_ID, Emp_Name 
    FROM Employee
    WHERE Salary > 80000
) a
INNER JOIN (
    SELECT Emp_ID, Emp_Name 
    FROM Employee
    WHERE Dept_ID IN (1, 4)
) b ON a.Emp_ID = b.Emp_ID;

-- 8. SIMULATED EXCEPT (using NOT EXISTS):
-- Employees earning > 80,000 EXCEPT those in Cyber Security (Dept 3)
SELECT e.Emp_ID, e.Emp_Name 
FROM Employee e
WHERE e.Salary > 80000 
AND NOT EXISTS (
    SELECT 1
    FROM Employee e2
    WHERE e2.Emp_ID = e.Emp_ID 
    AND e2.Dept_ID = 3
);

-- =====================================================================
-- 3. QUERY EXECUTION PLANS (EXPLAIN)
-- =====================================================================

-- Query 1: EXPLAIN for simple selection
EXPLAIN 
SELECT *
FROM Employee
WHERE Salary > 90000;

-- Query 2: EXPLAIN for INNER JOIN
EXPLAIN
SELECT e.Emp_Name, d.Dept_Name 
FROM Employee e
INNER JOIN Department d ON e.Dept_ID = d.Dept_ID;

-- Query 3: EXPLAIN for correlated subquery
EXPLAIN
SELECT e.Emp_ID, e.Emp_Name, e.Salary
FROM Employee e 
WHERE e.Salary > (
    SELECT AVG(e2.Salary) 
    FROM Employee e2
    WHERE e2.Dept_ID = e.Dept_ID
);

-- Query 4: EXPLAIN for EXISTS subquery
EXPLAIN
SELECT d.Dept_Name 
FROM Department d 
WHERE EXISTS (
    SELECT 1
    FROM Employee e
    WHERE e.Dept_ID = d.Dept_ID 
    AND e.Salary > 100000
);
