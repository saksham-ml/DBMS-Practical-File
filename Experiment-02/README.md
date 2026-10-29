# Experiment - 2

## Title
**ER Diagram to Relational Schema**

---

## Aim
To convert an **Entity-Relationship (ER) Diagram** into a **Relational Schema** for an E-Commerce platform, identify Primary Keys and Foreign Keys, handle multi-valued attributes and specialization hierarchies, enforce referential integrity constraints (`ON DELETE CASCADE` and `ON DELETE SET NULL`), insert sample records, and demonstrate:
1. Verification of created relational tables (`SHOW TABLES`).
2. Sample data insertion.
3. Referential integrity violation upon inserting invalid foreign keys.
4. `ON DELETE SET NULL` behavior.
5. `ON DELETE CASCADE` behavior.

---

## Theory & ER-to-Relational Mapping Rules

1. **Mapping Strong Entity Types**:
   - For each strong entity type $E$, create a relation $R$ containing all simple attributes of $E$.
   - Choose one key attribute as the Primary Key ($PK$).

2. **Mapping Weak Entity Types**:
   - For each weak entity $W$ with owner entity $E$, create a relation $R$ including all simple attributes of $W$.
   - The primary key of $R$ is the composite of the primary key of the owner entity $E$ and the partial key (discriminator) of $W$.
   - *Example*: `ORDERITEM` has composite primary key `(OrderID, ItemNo)` where `OrderID` references `ORDERS`.

3. **Mapping Multi-Valued Attributes**:
   - For each multi-valued attribute $A$ of entity $E$, create a separate relation $R$.
   - $R$ includes an attribute corresponding to $A$, plus the primary key $K$ of $E$ as a foreign key.
   - The primary key of $R$ is the combination of $(K, A)$.
   - *Examples*: `CUSTOMER_PHONE(CustomerID, Phone)`, `CUSTOMER_ALT_PHONE(CustomerID, AltPhone)`, `SELLER_PHONE(SellerID, Phone)`, `ADDRESS_MOBILE(AddressID, MobileNo)`, `PRODUCT_IMAGE(ProductID, Image)`.

4. **Mapping Composite Attributes**:
   - Flatten composite attributes into their individual atomic components.
   - *Example*: `ADDRESS` decomposes into `DoorNo`, `Street`, `Area`, `City`, `State`, and `Pincode`.

5. **Mapping Specialization / Generalization Hierarchies**:
   - Create a relation for the generalized superclass (`PRODUCT`) containing common attributes.
   - Create separate relations for each subclass (`ELECTRONICS`, `CLOTHING`, `BOOKS`) containing subclass-specific attributes and the superclass primary key (`ProductID`) acting simultaneously as both **Primary Key** and **Foreign Key**.

6. **Referential Integrity Constraints**:
   - **`ON DELETE CASCADE`**: When a referenced record in the parent table is deleted, all corresponding child rows in the referencing table are automatically deleted.
   - **`ON DELETE SET NULL`**: When a referenced record in the parent table is deleted, the foreign key column values in matching child rows are automatically updated to `NULL`.

---

## 📋 Relational Schema Mapping Table

| Table Name | Primary Key | Foreign Keys & References | Description / Mapping Role |
| :--- | :--- | :--- | :--- |
| **`CUSTOMER`** | `CustomerID` | None | Strong entity representing buyers |
| **`CUSTOMER_PHONE`** | `(CustomerID, Phone)` | `CustomerID &rarr; CUSTOMER(CustomerID)` | Multi-valued contact numbers |
| **`CUSTOMER_ALT_PHONE`** | `(CustomerID, AltPhone)` | `CustomerID &rarr; CUSTOMER(CustomerID)` | Multi-valued alternate phone numbers |
| **`SELLER`** | `SellerID` | None | Merchant entity |
| **`SELLER_PHONE`** | `(SellerID, Phone)` | `SellerID &rarr; SELLER(SellerID)` | Multi-valued merchant phone numbers |
| **`ADDRESS`** | `AddressID` | `CustomerID &rarr; CUSTOMER(CustomerID)` | Composite shipping/billing address |
| **`ADDRESS_MOBILE`** | `(AddressID, MobileNo)` | `AddressID &rarr; ADDRESS(AddressID)` | Multi-valued address contact numbers |
| **`CATEGORY`** | `CategoryID` | `ParentCategoryID &rarr; CATEGORY(CategoryID)` | Self-referencing category tree |
| **`PRODUCT`** | `ProductID` | `SellerID &rarr; SELLER(SellerID)`<br>`CategoryID &rarr; CATEGORY(CategoryID)` | Marketplace product catalogue |
| **`PRODUCT_IMAGE`** | `(ProductID, Image)` | `ProductID &rarr; PRODUCT(ProductID)` | Multi-valued gallery image URLs |
| **`ELECTRONICS`** | `ProductID` | `ProductID &rarr; PRODUCT(ProductID)` | Product specialization (Warranty, PowerRating) |
| **`CLOTHING`** | `ProductID` | `ProductID &rarr; PRODUCT(ProductID)` | Product specialization (Size, Colour, Material) |
| **`BOOKS`** | `ProductID` | `ProductID &rarr; PRODUCT(ProductID)` | Product specialization (ISBN, Author, Publisher) |
| **`ORDERS`** | `OrderID` | `CustomerID &rarr; CUSTOMER(CustomerID)`<br>`AddressID &rarr; ADDRESS(AddressID)` | Purchase order header |
| **`ORDER_COUPON`** | `(OrderID, CouponCode)` | `OrderID &rarr; ORDERS(OrderID)` | Multi-valued promotional vouchers |
| **`ORDERITEM`** | `(OrderID, ItemNo)` | `OrderID &rarr; ORDERS(OrderID)`<br>`ProductID &rarr; PRODUCT(ProductID)` | Weak entity line item |
| **`PAYMENT`** | `PaymentID` | `OrderID &rarr; ORDERS(OrderID)` | 1:1 transaction record |
| **`DELIVERY`** | `DeliveryID` | `OrderID &rarr; ORDERS(OrderID)`<br>`AddressID &rarr; ADDRESS(AddressID)` | 1:1 shipment tracking record |

---

## 💻 SQL Implementation

The complete SQL DDL and DML scripts are available in [`schema.sql`](./schema.sql).

### Table Creation Highlights

```sql
-- Weak Entity Table: ORDERITEM
CREATE TABLE ORDERITEM (
    OrderID INT,
    ItemNo INT,
    ProductID INT NOT NULL,
    ItemPrice DECIMAL(10,2) NOT NULL,
    Quantity INT NOT NULL,
    Discount DECIMAL(10,2),
    TaxAmount DECIMAL(10,2),
    PRIMARY KEY (OrderID, ItemNo),
    FOREIGN KEY (OrderID) REFERENCES ORDERS(OrderID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES PRODUCT(ProductID) ON DELETE CASCADE
);

-- Subclass Specialization Table: ELECTRONICS
CREATE TABLE ELECTRONICS (
    ProductID INT PRIMARY KEY,
    Brand VARCHAR(50),
    Warranty VARCHAR(30),
    PowerRating VARCHAR(30),
    FOREIGN KEY (ProductID) REFERENCES PRODUCT(ProductID) ON DELETE CASCADE
);
```

---

## 📊 Practical Outputs & Execution Results

### Output 1: Verifying Table Generation (`SHOW TABLES`)

```sql
SHOW TABLES;
```

**Result (18 tables created successfully):**
```text
+-------------------------+
| Tables_in_ecommerce     |
+-------------------------+
| ADDRESS                 |
| ADDRESS_MOBILE          |
| BOOKS                   |
| CATEGORY                |
| CLOTHING                |
| CUSTOMER                |
| CUSTOMER_ALT_PHONE      |
| CUSTOMER_PHONE          |
| DELIVERY                |
| ELECTRONICS             |
| ORDERS                  |
| ORDERITEM               |
| ORDER_COUPON            |
| PAYMENT                 |
| PRODUCT                 |
| PRODUCT_IMAGE           |
| SELLER                  |
| SELLER_PHONE            |
+-------------------------+
18 rows in set (0.00 sec)
```
> *Proves that the relational schema has been created with all 18 normalized relations.*

---

### Output 2: Sample Data Verification

```sql
SELECT * FROM CUSTOMER;
```
```text
+------------+-----------+--------------------------------+----------+---------------+
| CustomerID | Name      | Email                          | Password | DateOfBirth   |
+------------+-----------+--------------------------------+----------+---------------+
|          1 | Priyanshu | priyanshumishra02007@gmail.com | pass123  | 2007-01-20    |
+------------+-----------+--------------------------------+----------+---------------+
1 row in set (0.00 sec)
```

```sql
SELECT * FROM PRODUCT;
```
```text
+-----------+-------------+---------------+----------+----------+--------+----------+------------+
| ProductID | ProductName | Description   | Price    | StockQty | Weight | SellerID | CategoryID |
+-----------+-------------+---------------+----------+----------+--------+----------+------------+
|       301 | Laptop      | Gaming Laptop | 75000.00 |       10 |   2.50 |      101 |        201 |
+-----------+-------------+---------------+----------+----------+--------+----------+------------+
1 row in set (0.00 sec)
```

```sql
SELECT * FROM ORDERS;
```
```text
+---------+------------+-------------+-------------+------------+-----------+
| OrderID | OrderDate  | OrderStatus | TotalAmount | CustomerID | AddressID |
+---------+------------+-------------+-------------+------------+-----------+
|     501 | 2026-08-14 | Placed      |    75000.00 |          1 |       401 |
+---------+------------+-------------+-------------+------------+-----------+
1 row in set (0.00 sec)
```
> *Proves successful sample data insertion into parent and dependent child tables.*

---

### Output 3: Referential Integrity Violation Demonstration

Attempting to insert an order referencing a non-existent `CustomerID = 999`:

```sql
INSERT INTO ORDERS VALUES (502, '2026-08-14', 'Placed', 50000.00, 999, 401);
```

**Output:**
```text
ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails
(`ecommerce`.`orders`, CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`CustomerID`) REFERENCES `customer` (`CustomerID`) ON DELETE CASCADE)
```
- **Reason**: `CustomerID = 999` does not exist in the parent `CUSTOMER` table.
- **Verification**: Satisfies the requirement to demonstrate foreign key constraint enforcement and referential integrity protection.

---

### Output 4: Demonstration of `ON DELETE SET NULL`

The foreign key from `PRODUCT` to `CATEGORY` is configured with `ON DELETE SET NULL`.

#### Step 1: Check product before deletion
```sql
SELECT ProductID, ProductName, CategoryID FROM PRODUCT;
```
```text
+-----------+-------------+------------+
| ProductID | ProductName | CategoryID |
+-----------+-------------+------------+
|       301 | Laptop      |        201 |
+-----------+-------------+------------+
1 row in set (0.00 sec)
```

#### Step 2: Delete parent category
```sql
DELETE FROM CATEGORY WHERE CategoryID = 201;
```
```text
Query OK, 1 row affected (0.01 sec)
```

#### Step 3: Check product after category deletion
```sql
SELECT ProductID, ProductName, CategoryID FROM PRODUCT;
```
```text
+-----------+-------------+------------+
| ProductID | ProductName | CategoryID |
+-----------+-------------+------------+
|       301 | Laptop      | NULL       |
+-----------+-------------+------------+
1 row in set (0.00 sec)
```
> **Conclusion**: `ON DELETE SET NULL` successfully updated `CategoryID` to `NULL` without deleting or corrupting the dependent product record.

---

### Output 5: Demonstration of `ON DELETE CASCADE`

Foreign keys referencing `CUSTOMER` in `ORDERS` and `CUSTOMER_PHONE` are configured with `ON DELETE CASCADE`.

#### Step 1: Check existing orders before deleting customer
```sql
SELECT * FROM ORDERS;
```
```text
+---------+------------+-------------+-------------+------------+-----------+
| OrderID | OrderDate  | OrderStatus | TotalAmount | CustomerID | AddressID |
+---------+------------+-------------+-------------+------------+-----------+
|     501 | 2026-08-14 | Placed      |    75000.00 |          1 |       401 |
+---------+------------+-------------+-------------+------------+-----------+
1 row in set (0.00 sec)
```

#### Step 2: Delete parent customer record
```sql
DELETE FROM CUSTOMER WHERE CustomerID = 1;
```
```text
Query OK, 1 row affected (0.01 sec)
```

#### Step 3: Verify automatic cascade deletion in child tables
```sql
SELECT * FROM ORDERS;
```
```text
Empty set (0.00 sec)
```

```sql
SELECT * FROM CUSTOMER_PHONE;
```
```text
Empty set (0.00 sec)
```
> **Conclusion**: Deleting the parent `CUSTOMER` automatically deleted corresponding dependent child rows from `ORDERS`, `CUSTOMER_PHONE`, `ADDRESS`, and other child tables. `ON DELETE CASCADE` demonstrated successfully.
