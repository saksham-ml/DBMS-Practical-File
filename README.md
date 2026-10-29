# 🗄️ Database Management Systems (DBMS) Practical File

Welcome to the **DBMS Practical Laboratory Repository**. This repository contains detailed practical experiments, ER diagrams, relational schemas, SQL scripts, and documentation for the DBMS lab coursework.

---

## 📑 Table of Contents

| Exp No. | Experiment Title | Description | Code / Documentation |
| :---: | :--- | :--- | :---: |
| **01** | **Design an ER Diagram for an Indian E-Commerce Platform** | Entity-Relationship modeling with entities, attributes (primary key, composite, multi-valued), weak entities, specialization, and cardinality/participation constraints. | [View Experiment](./Experiment-01/README.md) &bull; [SQL Schema](./Experiment-01/schema.sql) |
| **02** | **ER Diagram to Relational Schema** | Mapping ER diagram into normalized relational tables, handling weak entities, multi-valued attributes, specialization, enforcing referential integrity (`CASCADE`, `SET NULL`), and testing constraint violations. | [View Experiment](./Experiment-02/README.md) &bull; [SQL Script](./Experiment-02/schema.sql) |
| **03** | **Employee–Department–Project Schema & Advanced SQL Queries** | Creating relational enterprise schema, populating 30 employees across 5 departments and 8 projects, and executing Selection, Projection, Aggregates, GROUP BY, HAVING, CASE, and ORDER BY queries. | [View Experiment](./Experiment-03/README.md) &bull; [SQL Script](./Experiment-03/schema.sql) |
| **04** | **Advanced SQL Queries and Execution Plans** | Implementing INNER, LEFT, SELF, and multi-table joins, correlated subqueries, EXISTS, simulated INTERSECT and EXCEPT operations, and comparing optimizer query plans using `EXPLAIN`. | [View Experiment](./Experiment-04/README.md) &bull; [SQL Script](./Experiment-04/schema.sql) |
| **05** | **SQL Views, View Updatability and Recursive CTE** | Designing summary and hierarchy views, validating view updatability rules across simple and aggregated projections, and implementing recursive CTEs to traverse organizational reporting chains. | [View Experiment](./Experiment-05/README.md) &bull; [SQL Script](./Experiment-05/schema.sql) |
| **06** | **Stored Procedures, Triggers & Audit Logging** | Implementing transactional stored procedure `transfer_employee` with exception handling, `BEFORE` boundary validation triggers, and an automated `AFTER UPDATE` salary audit trail with NULL-safe checking. | [View Experiment](./Experiment-06/README.md) &bull; [SQL Script](./Experiment-06/schema.sql) |

---

## 🛠️ Tools & Technologies Used
- **Database Engine**: MySQL Server 8.0+ / MySQL Workbench / MariaDB / PostgreSQL
- **Modeling Tool**: Mermaid.js & ER Notation
- **Language**: SQL (DDL, DML, DQL, DCL, TCL, Procedural SQL / PL-SQL)

---

## 📂 Repository Structure

```text
DBMS-Practical-File/
├── README.md
├── Experiment-01/
│   ├── README.md       # Aim, Theory, Key Components, Schema Details & ER Diagram
│   └── schema.sql      # DDL SQL Script implementing the Relational Schema
├── Experiment-02/
│   ├── README.md       # Aim, Theory, Mapping Table, DDL & 5 Verified Practical Outputs
│   └── schema.sql      # Complete SQL Script (DDL, DML, Constraint Demonstrations)
├── Experiment-03/
│   ├── README.md       # Aim, Design, ER Diagram, 18 SQL Queries & Exact Output Tables
│   └── schema.sql      # Complete SQL Script (DDL, 30 Employees DML, 18 Queries)
├── Experiment-04/
│   ├── README.md       # Aim, Joins, Subqueries, Set Operations, Outputs & EXPLAIN Plans
│   └── schema.sql      # Complete SQL Script (Joins, Correlated Subqueries, EXPLAIN)
├── Experiment-05/
│   ├── README.md       # Aim, Views, Updatability Matrix, Recursive CTEs & Output Tables
│   └── schema.sql      # Complete SQL Script (ALTER, Hierarchy Updates, Views, CTEs)
└── Experiment-06/
    ├── README.md       # Aim, Theory, Triggers, Stored Procedure, Test Matrices & Audit Logs
    └── schema.sql      # Complete SQL Script (Salary_Audit, Triggers, Procedure, Tests)
```

---

*Maintained by [@saksham-ml](https://github.com/saksham-ml) (Saksham Dubey - 25LBCS3326)*
