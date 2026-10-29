# Experiment - 5

## Title
**SQL Views, View Updatability and Recursive CTE**

---

## Aim
To create **SQL views** for department salary summaries and employee hierarchies, evaluate and verify the **updatability of views** across different query constructs, and implement a **recursive Common Table Expression (CTE)** to traverse and display organizational reporting hierarchies.

---

## Software / Requirements
- **DBMS**: MySQL 8.0 or later (required for `WITH RECURSIVE` support)
- **Tools**: MySQL Workbench / Command Line Client
- **Database**: `CompanyDB` (built in Experiments 3 and 4)

---

## Theory

### 1. SQL Views
A **view** is a virtual table defined by an underlying SQL `SELECT` statement. Unlike base tables, a view does not physically store data redundantly; instead, the DBMS executes the view's query definition dynamically whenever the view is queried.
- **Benefits**:
  - Encapsulates and simplifies complex queries (joins, aggregations).
  - Implements role-based security and data abstraction by exposing only authorized columns to specific users.
  - Ensures a consistent, logical layer over changing physical schemas.

### 2. View Updatability Rules
A view is updatable (i.e., permits `INSERT`, `UPDATE`, `DELETE` statements that propagate to the underlying base table) only if the DBMS can unambiguously map rows in the view to unique rows in a single base table.
- **Updatable Views**: Simple 1:1 column projections from a single base table without row aggregation.
- **Non-Updatable Views**: Views containing any of the following cannot be updated:
  - Aggregate functions (`SUM()`, `AVG()`, `MIN()`, `MAX()`, `COUNT()`)
  - `GROUP BY` or `HAVING` clauses
  - `DISTINCT` keyword
  - `UNION` or `UNION ALL`
  - Multi-table joins where updates modify derived or non-key preserved columns.

### 3. Recursive Common Table Expressions (CTE)
A **Recursive CTE** is an iterative query construct defined using `WITH RECURSIVE`. It is specifically designed to query recursive or hierarchical data models (e.g., self-referencing employee-manager hierarchies, bill-of-materials, network trees).
- **Structure**:
  1. **Anchor Member**: The base query executed once to establish the initial result set (e.g., top-level managers with `Manager_ID IS NULL`).
  2. **`UNION ALL`**: Combines the anchor results with successive recursive iterations.
  3. **Recursive Member**: Iteratively queries the CTE itself, joining base tables with results from previous iterations until an empty set is produced (termination condition).

---

## 💻 Step-by-Step Implementation

The full SQL script is available in [`schema.sql`](./schema.sql).

### 1. Extend Employee Schema for Reporting Hierarchy
Introduce a self-referencing foreign key column `Manager_ID` referencing `Emp_ID` within the same `Employee` table:

```sql
ALTER TABLE Employee
ADD COLUMN Manager_ID INT NULL;

ALTER TABLE Employee
ADD CONSTRAINT fk_employee_manager
FOREIGN KEY (Manager_ID) REFERENCES Employee(Emp_ID);
```

#### Hierarchical Assignments Across Departments:
- **Artificial Intelligence**:
  - `Emp_ID = 101` (Aarav Sharma - Head / No Manager)
  - `101` manages `102` (Priya Verma) and `103` (Rohan Gupta)
  - `102` manages `104` (Ananya Singh) and `105` (Karan Mehta)
  - `103` manages `106` (Neha Kapoor)
- **Software Development**: `110` (Simran Kaur - Lead) &rarr; `107`, `108` &rarr; `109`, `111`, `112`.
- **Cyber Security**: `115` (Yash Thakur - Lead) &rarr; `113`, `114` &rarr; `116`, `117`, `118`.
- **Data Science**: `119` (Akash Singh - Lead) &rarr; `120`, `121` &rarr; `122`, `123`, `124`.
- **Human Resources**: `125` (Manish Verma - Lead) &rarr; `126`, `129` &rarr; `127`, `128`, `130`.

---

### 2. Create Department Salary Summary View (Aggregates + GROUP BY)
```sql
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
```

---

### 3. Create Employee Hierarchy View (Multi-Table Outer Joins)
```sql
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
```

---

### 4. Test View Updatability

#### A. Updatable Simple View (`Employee_Basic`)
```sql
CREATE OR REPLACE VIEW Employee_Basic AS
SELECT Emp_ID, Emp_Name, Job_Title, Salary, Dept_ID 
FROM Employee;

-- Test update through simple view:
UPDATE Employee_Basic 
SET Salary = 86000 
WHERE Emp_ID = 101;
```
> **Observation**: Update **succeeds**. Base table reflects the new salary (₹86,000) because `Employee_Basic` maps 1:1 to a single base table.

#### B. Non-Updatable Aggregate View (`Department_Salary_Summary`)
```sql
UPDATE Department_Salary_Summary 
SET Average_Salary = 90000 
WHERE Dept_ID = 1;
```
> **Observation**: **Rejected** with:  
> `ERROR 1288 (HY000): The target table Department_Salary_Summary of the UPDATE is not updatable`  
> (Rows represent aggregated groups, not individual base rows).

#### C. Non-Updatable Multi-Table Joined View (`Employee_Hierarchy`)
```sql
UPDATE Employee_Hierarchy
SET Manager_Name = 'Priya Verma' 
WHERE Emp_ID = 103;
```
> **Observation**: **Rejected** because `Manager_Name` is derived from a joined relation.

---

### 5. Recursive Common Table Expressions (CTE)

#### A. Full Reporting Chain (`Root -> Level 1 -> Level 2`)
```sql
WITH RECURSIVE EmployeeChain AS ( 
    -- Anchor Member: Top-level managers
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
```

#### B. Subtree for a Specific Department Lead (`Emp_ID = 101`)
```sql
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
```

#### C. Hierarchy Indentation
```sql
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
```

---

## 📊 Practical Execution Outputs

### Output 1: Department Salary Summary View
```sql
SELECT * FROM Department_Salary_Summary;
```
```text
+---------+-------------------------+----------------+--------------+----------------+----------------+----------------+
| Dept_ID | Dept_Name               | Employee_Count | Total_Salary | Average_Salary | Minimum_Salary | Maximum_Salary |
+---------+-------------------------+----------------+--------------+----------------+----------------+----------------+
|       1 | Artificial Intelligence |              6 |    520000.00 |   86666.666667 |       72000.00 |      105000.00 |
|       2 | Software Development    |              6 |    465000.00 |   77500.000000 |       65000.00 |       95000.00 |
|       3 | Cyber Security          |              6 |    516000.00 |   86000.000000 |       68000.00 |       98000.00 |
|       4 | Data Science            |              6 |    506000.00 |   84333.333333 |       72000.00 |      100000.00 |
|       5 | Human Resources         |              6 |    403000.00 |   67166.666667 |       58000.00 |       85000.00 |
+---------+-------------------------+----------------+--------------+----------------+----------------+----------------+
```

---

### Output 2: Employee Hierarchy View
```sql
SELECT * FROM Employee_Hierarchy ORDER BY Dept_ID, Manager_ID, Emp_ID;
```
```text
+--------+---------------+----------------------+---------+-------------------------+------------+--------------+
| Emp_ID | Employee_Name | Job_Title            | Dept_ID | Dept_Name               | Manager_ID | Manager_Name |
+--------+---------------+----------------------+---------+-------------------------+------------+--------------+
|    101 | Aarav Sharma  | AI Engineer          |       1 | Artificial Intelligence |       NULL | NULL         |
|    102 | Priya Verma   | ML Engineer          |       1 | Artificial Intelligence |        101 | Aarav Sharma |
|    103 | Rohan Gupta   | AI Developer         |       1 | Artificial Intelligence |        101 | Aarav Sharma |
|    104 | Ananya Singh  | Research Engineer    |       1 | Artificial Intelligence |        102 | Priya Verma  |
|    105 | Karan Mehta   | ML Engineer          |       1 | Artificial Intelligence |        102 | Priya Verma  |
|    106 | Neha Kapoor   | AI Analyst           |       1 | Artificial Intelligence |        103 | Rohan Gupta  |
|    110 | Simran Kaur   | Full Stack Developer |       2 | Software Development    |       NULL | NULL         |
|    109 | Aditya Jain   | Frontend Developer   |       2 | Software Development    |        107 | Rahul Kumar  |
|    120 | Kriti Sharma  | Data Analyst         |       4 | Data Science            |        119 | Akash Singh  |
|    121 | Mohit Agarwal | Data Scientist       |       4 | Data Science            |        119 | Akash Singh  |
|    122 | Riya Das      | Data Analyst         |       4 | Data Science            |        120 | Kriti Sharma |
|    123 | Nikhil Bansal | ML Data Scientist    |       4 | Data Science            |        120 | Kriti Sharma |
|    124 | Sakshi Roy    | BI Analyst           |       4 | Data Science            |        121 | Mohit Agarwal|
|    125 | Manish Verma  | HR Manager           |       5 | Human Resources         |       NULL | NULL         |
|    126 | Divya Mehta   | HR Executive         |       5 | Human Resources         |        125 | Manish Verma |
|    129 | Varun Gupta   | Training Manager     |       5 | Human Resources         |        125 | Manish Verma |
|    127 | Suresh Kumar  | Recruiter            |       5 | Human Resources         |        126 | Divya Mehta  |
|    128 | Ayesha Khan   | HR Executive         |       5 | Human Resources         |        126 | Divya Mehta  |
|    130 | Nandini Sharma| HR Analyst           |       5 | Human Resources         |        126 | Divya Mehta  |
+--------+---------------+----------------------+---------+-------------------------+------------+--------------+
```

---

### Output 3: Simple View Update Verification
```sql
SELECT Emp_ID, Emp_Name, Salary FROM Employee WHERE Emp_ID = 101;
```
```text
+--------+--------------+----------+
| Emp_ID | Emp_Name     | Salary   |
+--------+--------------+----------+
|    101 | Aarav Sharma | 86000.00 |
+--------+--------------+----------+
1 row in set (0.00 sec)
```

---

### Output 4: Non-Updatable Aggregate Error
```text
ERROR 1288 (HY000) at line 201: The target table Department_Salary_Summary of the UPDATE is not updatable
```

---

## 📋 View Updatability Comparison Matrix

| View Name | Query Composition | Directly Updatable? | Reason / DBMS Rule |
| :--- | :--- | :---: | :--- |
| **`Employee_Basic`** | Single base table projection | **Yes** | 1:1 mapping directly to base table rows and primary key. |
| **`Department_Salary_Summary`** | `GROUP BY` + Aggregates (`SUM`, `AVG`, etc.) | **No** | Rows represent grouped metrics rather than single base rows. |
| **`Employee_Hierarchy`** | Multi-table outer joins | **No** | Contains derived columns (`Manager_Name`) from multiple joined tables. |

---

## 💡 Important Observations
1. **Views Store Query Definitions**: A view stores the query SQL metadata in the database catalog rather than a separate duplicate physical copy of the table data.
2. **Aggregates Break Bijectivity**: Views with aggregate functions and `GROUP BY` cannot be updated because an update to an aggregate value (such as average salary) cannot be unambiguously mapped back to individual rows.
3. **Single-Table Projections are Modifiable**: Simple views selecting non-computed columns from a single table permit full DML manipulation (`INSERT`, `UPDATE`, `DELETE`).
4. **Self-Referencing Foreign Keys**: Setting `Manager_ID` as a foreign key pointing to `Emp_ID` in the same table successfully models recursive organizational hierarchies.
5. **Recursive CTE Termination**: A recursive CTE terminates naturally as soon as the recursive query produces no new rows (leaf nodes reached).

---

## 🎯 Result
SQL views for department salary summary and employee hierarchy were successfully created and analyzed. View updatability was systematically tested and verified across simple and aggregated views. A recursive Common Table Expression (CTE) was implemented to traverse self-referencing employee-manager hierarchies and output complete multi-level reporting chains.
