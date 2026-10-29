-- =====================================================================
-- DBMS Practical File - Experiment 02
-- Title: ER Diagram to Relational Schema
-- Database: ECOMMERCE
-- =====================================================================

DROP DATABASE IF EXISTS ECOMMERCE;
CREATE DATABASE ECOMMERCE;
USE ECOMMERCE;

-- =====================================================================
-- 1. TABLE CREATION (DDL)
-- =====================================================================

-- Table 1: CUSTOMER
CREATE TABLE CUSTOMER (
    CustomerID INT PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Password VARCHAR(100) NOT NULL,
    DateOfBirth DATE NOT NULL
);

-- Table 2: CUSTOMER_PHONE (Multi-valued Attribute)
CREATE TABLE CUSTOMER_PHONE (
    CustomerID INT,
    Phone VARCHAR(15),
    PRIMARY KEY (CustomerID, Phone),
    FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID) ON DELETE CASCADE
);

-- Table 3: CUSTOMER_ALT_PHONE (Multi-valued Attribute)
CREATE TABLE CUSTOMER_ALT_PHONE (
    CustomerID INT,
    AltPhone VARCHAR(15),
    PRIMARY KEY (CustomerID, AltPhone),
    FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID) ON DELETE CASCADE
);

-- Table 4: SELLER
CREATE TABLE SELLER (
    SellerID INT PRIMARY KEY,
    SellerName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    GSTIN VARCHAR(20) UNIQUE NOT NULL,
    AccountNo VARCHAR(20),
    IFSCCode VARCHAR(20),
    BankName VARCHAR(50)
);

-- Table 5: SELLER_PHONE (Multi-valued Attribute)
CREATE TABLE SELLER_PHONE (
    SellerID INT,
    Phone VARCHAR(15),
    PRIMARY KEY (SellerID, Phone),
    FOREIGN KEY (SellerID) REFERENCES SELLER(SellerID) ON DELETE CASCADE
);

-- Table 6: CATEGORY (Self-referencing Foreign Key)
CREATE TABLE CATEGORY (
    CategoryID INT PRIMARY KEY,
    CategoryName VARCHAR(50) NOT NULL,
    Description VARCHAR(100),
    ParentCategoryID INT,
    FOREIGN KEY (ParentCategoryID) REFERENCES CATEGORY(CategoryID) ON DELETE SET NULL
);

-- Table 7: PRODUCT
CREATE TABLE PRODUCT (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(50) NOT NULL,
    Description VARCHAR(100),
    Price DECIMAL(10,2) NOT NULL,
    StockQty INT NOT NULL,
    Weight DECIMAL(8,2),
    SellerID INT NOT NULL,
    CategoryID INT,
    FOREIGN KEY (SellerID) REFERENCES SELLER(SellerID) ON DELETE CASCADE,
    FOREIGN KEY (CategoryID) REFERENCES CATEGORY(CategoryID) ON DELETE SET NULL
);

-- Table 8: PRODUCT_IMAGE (Multi-valued Attribute)
CREATE TABLE PRODUCT_IMAGE (
    ProductID INT,
    Image VARCHAR(200),
    PRIMARY KEY (ProductID, Image),
    FOREIGN KEY (ProductID) REFERENCES PRODUCT(ProductID) ON DELETE CASCADE
);

-- Table 9: ELECTRONICS (Specialization of PRODUCT)
CREATE TABLE ELECTRONICS (
    ProductID INT PRIMARY KEY,
    Brand VARCHAR(50),
    Warranty VARCHAR(30),
    PowerRating VARCHAR(30),
    FOREIGN KEY (ProductID) REFERENCES PRODUCT(ProductID) ON DELETE CASCADE
);

-- Table 10: CLOTHING (Specialization of PRODUCT)
CREATE TABLE CLOTHING (
    ProductID INT PRIMARY KEY,
    Size VARCHAR(20),
    Colour VARCHAR(20),
    Material VARCHAR(30),
    FOREIGN KEY (ProductID) REFERENCES PRODUCT(ProductID) ON DELETE CASCADE
);

-- Table 11: BOOKS (Specialization of PRODUCT)
CREATE TABLE BOOKS (
    ProductID INT PRIMARY KEY,
    ISBN VARCHAR(20) UNIQUE,
    Author VARCHAR(50),
    Publisher VARCHAR(50),
    FOREIGN KEY (ProductID) REFERENCES PRODUCT(ProductID) ON DELETE CASCADE
);

-- Table 12: ADDRESS (Decomposed Composite Attribute)
CREATE TABLE ADDRESS (
    AddressID INT PRIMARY KEY,
    DoorNo VARCHAR(10),
    Street VARCHAR(50),
    Area VARCHAR(50),
    City VARCHAR(30),
    State VARCHAR(30),
    Pincode VARCHAR(10) NOT NULL,
    AddressType VARCHAR(20),
    CustomerID INT NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID) ON DELETE CASCADE
);

-- Table 13: ADDRESS_MOBILE (Multi-valued Attribute)
CREATE TABLE ADDRESS_MOBILE (
    AddressID INT,
    MobileNo VARCHAR(15),
    PRIMARY KEY (AddressID, MobileNo),
    FOREIGN KEY (AddressID) REFERENCES ADDRESS(AddressID) ON DELETE CASCADE
);

-- Table 14: ORDERS
CREATE TABLE ORDERS (
    OrderID INT PRIMARY KEY,
    OrderDate DATE NOT NULL,
    OrderStatus VARCHAR(20) NOT NULL,
    TotalAmount DECIMAL(10,2) NOT NULL,
    CustomerID INT NOT NULL,
    AddressID INT,
    FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID) ON DELETE CASCADE,
    FOREIGN KEY (AddressID) REFERENCES ADDRESS(AddressID) ON DELETE SET NULL
);

-- Table 15: ORDER_COUPON
CREATE TABLE ORDER_COUPON (
    OrderID INT,
    CouponCode VARCHAR(30),
    PRIMARY KEY (OrderID, CouponCode),
    FOREIGN KEY (OrderID) REFERENCES ORDERS(OrderID) ON DELETE CASCADE
);

-- Table 16: ORDERITEM (Weak Entity dependent on ORDERS)
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

-- Table 17: PAYMENT (1:1 with ORDERS)
CREATE TABLE PAYMENT (
    PaymentID INT PRIMARY KEY,
    PaymentDate DATE NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentMethod VARCHAR(30) NOT NULL,
    TransactionID VARCHAR(30) UNIQUE,
    PaymentStatus VARCHAR(20) NOT NULL,
    OrderID INT UNIQUE NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES ORDERS(OrderID) ON DELETE CASCADE
);

-- Table 18: DELIVERY (1:1 with ORDERS)
CREATE TABLE DELIVERY (
    DeliveryID INT PRIMARY KEY,
    DeliveryDate DATE,
    DeliveryStatus VARCHAR(20) NOT NULL,
    TrackingID VARCHAR(30) UNIQUE,
    DeliveryPartner VARCHAR(50),
    ShippingCharge DECIMAL(8,2),
    OrderID INT UNIQUE NOT NULL,
    AddressID INT,
    FOREIGN KEY (OrderID) REFERENCES ORDERS(OrderID) ON DELETE CASCADE,
    FOREIGN KEY (AddressID) REFERENCES ADDRESS(AddressID) ON DELETE CASCADE
);

-- =====================================================================
-- 2. SAMPLE DATA INSERTION (DML)
-- =====================================================================

-- Customer & Phone records
INSERT INTO CUSTOMER VALUES
(1, 'Priyanshu', 'priyanshumishra02007@gmail.com', 'pass123', '2007-01-20');

INSERT INTO CUSTOMER_PHONE VALUES
(1, '6388046065');

INSERT INTO CUSTOMER_ALT_PHONE VALUES
(1, '6388046065');

-- Seller & Phone records
INSERT INTO SELLER VALUES
(101, 'TechStore', 'tech@gmail.com', 'GST123', '123456', 'SBIN002', 'SBI');

INSERT INTO SELLER_PHONE VALUES
(101, '7897897919');

-- Category records (Hierarchical)
INSERT INTO CATEGORY VALUES
(201, 'Electronics', 'Electronic Items', NULL);

INSERT INTO CATEGORY VALUES
(202, 'Mobiles', 'Mobile Phones', 201);

-- Product records & Specialization
INSERT INTO PRODUCT VALUES
(301, 'Laptop', 'Gaming Laptop', 75000, 10, 2.5, 101, 201);

INSERT INTO ELECTRONICS VALUES
(301, 'ASUS', '2 Years', '180W');

INSERT INTO PRODUCT_IMAGE VALUES
(301, 'laptop.jpg');

-- Address & Mobile
INSERT INTO ADDRESS VALUES
(401, '121', 'Nawabganj', 'Unnao', 'Uttar Pradesh', '209859', 'Work', 1);

INSERT INTO ADDRESS_MOBILE VALUES
(401, '9192958085');

-- Orders & Order Items
INSERT INTO ORDERS VALUES
(501, '2026-08-14', 'Placed', 75000, 1, 401);

INSERT INTO ORDERITEM VALUES
(501, 1, 301, 75000, 1, 1000, 9000);

INSERT INTO ORDER_COUPON VALUES
(501, 'WELCOME10');

-- Payment & Delivery
INSERT INTO PAYMENT VALUES
(601, '2026-08-14', 74000, 'UPI', 'TXN123', 'Paid', 501);

INSERT INTO DELIVERY VALUES
(701, NULL, 'Processing', 'TRK123', 'Delhivery', 100, 501, 401);

-- =====================================================================
-- 3. INTEGRITY CONSTRAINT DEMONSTRATIONS
-- =====================================================================

-- DEMONSTRATION 1: REFERENTIAL INTEGRITY VIOLATION
-- Fails with ERROR 1452 because CustomerID 999 does not exist in CUSTOMER table:
-- INSERT INTO ORDERS VALUES (502, '2026-08-14', 'Placed', 50000, 999, 401);

-- DEMONSTRATION 2: ON DELETE SET NULL
-- Check Category before delete:
SELECT ProductID, ProductName, CategoryID FROM PRODUCT;
-- Delete parent category:
DELETE FROM CATEGORY WHERE CategoryID = 201;
-- Check Category after delete (CategoryID becomes NULL):
SELECT ProductID, ProductName, CategoryID FROM PRODUCT;

-- DEMONSTRATION 3: ON DELETE CASCADE
-- Check Orders before deleting Customer:
SELECT * FROM ORDERS;
-- Delete parent customer:
DELETE FROM CUSTOMER WHERE CustomerID = 1;
-- Check Orders after deleting Customer (All child records automatically deleted):
SELECT * FROM ORDERS;
SELECT * FROM CUSTOMER_PHONE;
