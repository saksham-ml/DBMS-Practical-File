# Experiment - 4

## Title
**Advanced SQL Queries and Execution Plans**

---

## Aim
To perform advanced SQL queries on the **Employee–Department–Project** database (`CompanyDB`) using **INNER JOIN, LEFT JOIN, SELF JOIN, multi-table joins, correlated subqueries, EXISTS, simulated INTERSECT and EXCEPT operations**, and to analyze and compare query execution plans using **EXPLAIN**.

---

## Software / Requirements
- **DBMS**: MySQL / MySQL Workbench
- **Database Used**: `CompanyDB` (containing `Department`, `Employee`, `Project`, and `Employee_Project` tables)
- **OS**: Windows / Linux / macOS

---

## Theory

1. **SQL Joins**:
   - Combine rows from two or more tables based on related columns.
   - **`INNER JOIN`**: Returns rows where matching values exist in both joined tables.
   - **`LEFT JOIN` (Left Outer Join)**: Preserves all rows from the left table, matching with right-table rows where possible; unmatched right columns contain `NULL`.
   - **`SELF JOIN`**: A table is joined with itself by assigning different table aliases (`e1`, `e2`) to compare rows within the same relation.
   - **Multi-Table Joins**: Joins spanning $3+$ relations, typically connecting entities through intermediate $M:N$ associative bridge tables (`Employee_Project`).

2. **Subqueries & Correlated Subqueries**:
   - A **Subquery** is a nested query embedded inside an outer statement.
   - A **Correlated Subquery** references column values from the outer query row-by-row. Consequently, the subquery re-evaluates for every candidate row of the outer query.
   - **`EXISTS`**: A boolean test returning `TRUE` if the nested subquery produces at least one row, allowing early exit upon the first matching tuple.

3. **Simulated Set Operations**:
   - MySQL (prior to v8.0.31) lacks native `INTERSECT` and `EXCEPT` keywords.
   - **Simulated INTERSECT**: Achieved by performing an `INNER JOIN` between two distinct subqueries on matching key attributes.
   - **Simulated EXCEPT (MINUS)**: Achieved using `NOT EXISTS` or `LEFT JOIN ... WHERE right_table.key IS NULL`.

4. **Query Execution Plans (`EXPLAIN`)**:
   - Displays how the database cost-based optimizer plans to execute a given `SELECT` statement.
   - Key attributes analyzed:
     - **`select_type`**: `SIMPLE`, `PRIMARY`, `SUBQUERY`, `DEPENDENT SUBQUERY`, `DERIVED`.
     - **`type` (Access Method)**: `ALL` (full table scan), `ref` (non-unique index lookup), `eq_ref` (unique/primary key lookup).
     - **`possible_keys` & `key`**: Indexes considered versus index actually chosen.
     - **`rows`**: Estimated number of rows inspected.
     - **`Extra`**: Additional algorithmic steps (e.g., `Using where`, `Using temporary`, `Using filesort`).

---

## 💻 SQL Queries & Execution

The full SQL script is provided in [`schema.sql`](./schema.sql).

### 1. INNER JOIN
Display employees along with the department to which they belong:
```sql
SELECT e.Emp_ID, e.Emp_Name, e.Job_Title, d.Dept_Name
FROM Employee e
INNER JOIN Department d ON e.Dept_ID = d.Dept_ID;
```
> *Returns only employees having an existing matching department.*

### 2. LEFT JOIN
Display all departments and their employees, including departments with no assigned employees:
```sql
SELECT d.Dept_ID, d.Dept_Name, e.Emp_Name
FROM Department d 
LEFT JOIN Employee e ON d.Dept_ID = e.Dept_ID;
```
> *Preserves all rows from the left table (`Department`).*

### 3. SELF JOIN
Find unique pairs of employees who work in the same department:
```sql
SELECT e1.Emp_Name AS Employee_1, e2.Emp_Name AS Employee_2, e1.Dept_ID
FROM Employee e1 
INNER JOIN Employee e2 ON e1.Dept_ID = e2.Dept_ID AND e1.Emp_ID < e2.Emp_ID;
```
> *The condition `e1.Emp_ID < e2.Emp_ID` eliminates duplicate combinations and prevents self-pairing.*

### 4. Multi-Table / 4-Way Join
Display employee name, department name, and assigned project name:
```sql
SELECT e.Emp_Name, d.Dept_Name, p.Project_Name
FROM Employee e
INNER JOIN Department d ON e.Dept_ID = d.Dept_ID
INNER JOIN Employee_Project ep ON e.Emp_ID = ep.Emp_ID
INNER JOIN Project p ON ep.Project_ID = p.Project_ID;
```

### 5. Correlated Subquery
Find employees whose salary exceeds their own department's average salary:
```sql
SELECT e.Emp_ID, e.Emp_Name, e.Salary, e.Dept_ID
FROM Employee e 
WHERE e.Salary > (
    SELECT AVG(e2.Salary) 
    FROM Employee e2
    WHERE e2.Dept_ID = e.Dept_ID
);
```

### 6. EXISTS
Find departments having at least one employee earning more than ₹100,000:
```sql
SELECT d.Dept_ID, d.Dept_Name
FROM Department d 
WHERE EXISTS (
    SELECT 1
    FROM Employee e
    WHERE e.Dept_ID = d.Dept_ID AND e.Salary > 100000
);
```

### 7. Simulated INTERSECT
Find employees earning > ₹80,000 **AND** belonging to AI (Dept 1) or Data Science (Dept 4):
```sql
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
```

### 8. Simulated EXCEPT
Find employees earning > ₹80,000 **EXCEPT** those in Cyber Security (Dept 3):
```sql
SELECT e.Emp_ID, e.Emp_Name 
FROM Employee e
WHERE e.Salary > 80000 
AND NOT EXISTS (
    SELECT 1
    FROM Employee e2
    WHERE e2.Emp_ID = e.Emp_ID AND e2.Dept_ID = 3
);
```

---

## 📊 Query Execution Outputs

### Output 1: INNER JOIN
```text
+--------+----------------+------------------------+-------------------------+
| Emp_ID | Emp_Name       | Job_Title              | Dept_Name               |
+--------+----------------+------------------------+-------------------------+
|    101 | Aarav Sharma   | AI Engineer            | Artificial Intelligence |
|    102 | Priya Verma    | ML Engineer            | Artificial Intelligence |
|    103 | Rohan Gupta    | AI Developer           | Artificial Intelligence |
|    104 | Ananya Singh   | Research Engineer      | Artificial Intelligence |
|    105 | Karan Mehta    | ML Engineer            | Artificial Intelligence |
|    106 | Neha Kapoor    | AI Analyst             | Artificial Intelligence |
|    107 | Rahul Kumar    | Software Engineer      | Software Development    |
|    108 | Sneha Patel    | Backend Developer      | Software Development    |
|    109 | Aditya Jain    | Frontend Developer     | Software Development    |
|    110 | Simran Kaur    | Full Stack Developer   | Software Development    |
|    111 | Vivek Mishra   | Software Engineer      | Software Development    |
|    112 | Ishita Rao     | QA Engineer            | Software Development    |
|    113 | Arjun Malhotra | Security Engineer      | Cyber Security          |
|    114 | Megha Joshi    | Cyber Security Analyst | Cyber Security          |
|    115 | Yash Thakur    | Security Consultant    | Cyber Security          |
|    116 | Pooja Nair     | SOC Analyst            | Cyber Security          |
+--------+----------------+------------------------+-------------------------+
```

---

### Output 2: LEFT JOIN
```text
+---------+-------------------------+----------------+
| Dept_ID | Dept_Name               | Emp_Name       |
+---------+-------------------------+----------------+
|       1 | Artificial Intelligence | Aarav Sharma   |
|       1 | Artificial Intelligence | Priya Verma    |
|       1 | Artificial Intelligence | Rohan Gupta    |
|       1 | Artificial Intelligence | Ananya Singh   |
|       1 | Artificial Intelligence | Karan Mehta    |
|       1 | Artificial Intelligence | Neha Kapoor    |
|       2 | Software Development    | Rahul Kumar    |
|       2 | Software Development    | Sneha Patel    |
|       2 | Software Development    | Aditya Jain    |
|       2 | Software Development    | Simran Kaur    |
|       2 | Software Development    | Vivek Mishra   |
|       2 | Software Development    | Ishita Rao     |
|       3 | Cyber Security          | Arjun Malhotra |
|       3 | Cyber Security          | Megha Joshi    |
|       3 | Cyber Security          | Yash Thakur    |
|       3 | Cyber Security          | Pooja Nair     |
+---------+-------------------------+----------------+
```

---

### Output 3: SELF JOIN (Pairs in Same Department)
```text
+----------------+----------------+---------+
| Employee_1     | Employee_2     | Dept_ID |
+----------------+----------------+---------+
| Aarav Sharma   | Priya Verma    |       1 |
| Aarav Sharma   | Rohan Gupta    |       1 |
| Aarav Sharma   | Ananya Singh   |       1 |
| Aarav Sharma   | Karan Mehta    |       1 |
| Aarav Sharma   | Neha Kapoor    |       1 |
| Priya Verma    | Rohan Gupta    |       1 |
| Priya Verma    | Ananya Singh   |       1 |
| Priya Verma    | Karan Mehta    |       1 |
| Priya Verma    | Neha Kapoor    |       1 |
| Rohan Gupta    | Ananya Singh   |       1 |
| Rohan Gupta    | Karan Mehta    |       1 |
| Rohan Gupta    | Neha Kapoor    |       1 |
| Ananya Singh   | Karan Mehta    |       1 |
| Ananya Singh   | Neha Kapoor    |       1 |
| Karan Mehta    | Neha Kapoor    |       1 |
| Rahul Kumar    | Sneha Patel    |       2 |
+----------------+----------------+---------+
```

---

### Output 4: Multi-Table / 4-Way Join
```text
+----------------+-------------------------+----------------------------+
| Emp_Name       | Dept_Name               | Project_Name               |
+----------------+-------------------------+----------------------------+
| Aarav Sharma   | Artificial Intelligence | AI Recommendation System   |
| Priya Verma    | Artificial Intelligence | AI Recommendation System   |
| Ananya Singh   | Artificial Intelligence | AI Recommendation System   |
| Rohan Gupta    | Artificial Intelligence | Computer Vision Platform   |
| Karan Mehta    | Artificial Intelligence | Computer Vision Platform   |
| Neha Kapoor    | Artificial Intelligence | Computer Vision Platform   |
| Rahul Kumar    | Software Development    | E-Commerce Platform        |
| Sneha Patel    | Software Development    | E-Commerce Platform        |
| Simran Kaur    | Software Development    | E-Commerce Platform        |
| Aditya Jain    | Software Development    | Mobile Banking Application |
| Vivek Mishra   | Software Development    | Mobile Banking Application |
| Ishita Rao     | Software Development    | Mobile Banking Application |
| Arjun Malhotra | Cyber Security          | Cyber Threat Detection     |
| Megha Joshi    | Cyber Security          | Cyber Threat Detection     |
| Dev Patel      | Cyber Security          | Cyber Threat Detection     |
| Yash Thakur    | Cyber Security          | Security Monitoring System |
| Pooja Nair     | Cyber Security          | Security Monitoring System |
+----------------+-------------------------+----------------------------+
```

---

### Output 5: Correlated Subquery (Above Department Average)
```text
+--------+---------------+-----------+---------+
| Emp_ID | Emp_Name      | Salary    | Dept_ID |
+--------+---------------+-----------+---------+
|    102 | Priya Verma   |  92000.00 |       1 |
|    104 | Ananya Singh  | 105000.00 |       1 |
|    105 | Karan Mehta   |  88000.00 |       1 |
|    108 | Sneha Patel   |  82000.00 |       2 |
|    110 | Simran Kaur   |  95000.00 |       2 |
|    111 | Vivek Mishra  |  78000.00 |       2 |
|    113 | Arjun Malhotra|  90000.00 |       3 |
|    115 | Yash Thakur   |  98000.00 |       3 |
|    117 | Dev Patel     |  87000.00 |       3 |
|    118 | Tanvi Shah    |  91000.00 |       3 |
|    119 | Akash Singh   | 100000.00 |       4 |
|    121 | Mohit Agarwal |  95000.00 |       4 |
|    123 | Nikhil Bansal |  89000.00 |       4 |
|    125 | Manish Verma  |  85000.00 |       5 |
|    129 | Varun Gupta   |  73000.00 |       5 |
+--------+---------------+-----------+---------+
```

---

### Output 6: EXISTS Query
```text
+---------+-------------------------+
| Dept_ID | Dept_Name               |
+---------+-------------------------+
|       1 | Artificial Intelligence |
+---------+-------------------------+
```

---

### Output 7: Simulated INTERSECT
```text
+--------+---------------+
| Emp_ID | Emp_Name      |
+--------+---------------+
|    101 | Aarav Sharma  |
|    102 | Priya Verma   |
|    104 | Ananya Singh  |
|    105 | Karan Mehta   |
|    119 | Akash Singh   |
|    121 | Mohit Agarwal |
|    123 | Nikhil Bansal |
+--------+---------------+
```

---

### Output 8: Simulated EXCEPT
```text
+--------+---------------+
| Emp_ID | Emp_Name      |
+--------+---------------+
|    101 | Aarav Sharma  |
|    102 | Priya Verma   |
|    104 | Ananya Singh  |
|    105 | Karan Mehta   |
|    108 | Sneha Patel   |
|    110 | Simran Kaur   |
|    119 | Akash Singh   |
|    121 | Mohit Agarwal |
|    123 | Nikhil Bansal |
|    125 | Manish Verma  |
+--------+---------------+
```

---

## ⚡ Execution Plan Comparisons (`EXPLAIN`)

### 1. EXPLAIN for Simple Selection
```sql
EXPLAIN SELECT * FROM Employee WHERE Salary > 90000;
```
- **Type**: `ALL` (Full table scan since `Salary` is unindexed).
- **Rows**: Evaluates all 30 employee tuples.
- **Extra**: `Using where`.

### 2. EXPLAIN for INNER JOIN
```sql
EXPLAIN SELECT e.Emp_Name, d.Dept_Name FROM Employee e INNER JOIN Department d ON e.Dept_ID = d.Dept_ID;
```
- **Join Strategy**: Hash Join / Nested Loop.
- **Access Type**: `ALL` on `Department` (driving table, 5 rows), `ref` on `Employee` using foreign key index on `Dept_ID`.
- **Optimization**: Uses foreign key index to join efficiently without cross-product.

### 3. EXPLAIN for Correlated Subquery
```sql
EXPLAIN SELECT e.Emp_ID, e.Emp_Name, e.Salary FROM Employee e 
WHERE e.Salary > (SELECT AVG(e2.Salary) FROM Employee e2 WHERE e2.Dept_ID = e.Dept_ID);
```
- **Select Type**: Outer query is `PRIMARY`, inner subquery is `DEPENDENT SUBQUERY`.
- **Mechanism**: The dependent subquery runs iteratively for every row processed by the primary query.

### 4. EXPLAIN for EXISTS Subquery
```sql
EXPLAIN SELECT d.Dept_Name FROM Department d 
WHERE EXISTS (SELECT 1 FROM Employee e WHERE e.Dept_ID = d.Dept_ID AND e.Salary > 100000);
```
- **Select Type**: `MATERIALIZED` / Semi-join optimization.
- **Mechanism**: Evaluates the subquery and immediately short-circuits upon encountering the first match for each department.

---

## 🎯 Result
The **Employee–Department–Project** database was successfully queried using `INNER JOIN`, `LEFT JOIN`, `SELF JOIN`, multi-table joins, correlated subqueries, `EXISTS`, and simulated `INTERSECT` and `EXCEPT` operations. Execution plans for selected queries were examined using `EXPLAIN`, and their access methods and plan characteristics were recorded and analyzed.
