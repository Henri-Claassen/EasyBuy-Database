# EasyBuy Database Project

## 📌 Overview
The **EasyBuy Database Project** is a relational database system designed to simulate a retail store environment. It models customers, employees, suppliers, products, stock, orders, and audit logs. The project demonstrates database creation, normalization, and population with sample data for testing and academic purposes.

This repository includes:
- SQL script to **create and populate** the EasyBuy database.
- An **Entity-Relationship Diagram (ERD)** illustrating the schema in 3NF.

---

## 🛠 Features
- **Automated Database Creation**  
  - Drops existing `EasyBuy` database if present.  
  - Creates new database files (`EasyBuyMainData.mdf`, `EasyBuyLog.ldf`).  

- **Schema Design**  
  - Tables: `Customers`, `Branches`, `Employees`, `Orders`, `Audit Log`, `Categories`, `Suppliers`, `Products`, `Stock`, `Order Details`.  
  - Constraints: Primary keys, foreign keys, unique constraints, and check constraints.  
  - Referential integrity enforced across all relationships.  

- **Sample Data Population**  
  - Suppliers, categories, products, customers, branches, employees, audit logs, and stock entries.  
  - Realistic South African context (names, provinces, cities).  

- **Normalization**  
  - ERD demonstrates progression from **1NF → 2NF → 3NF**.  
  - Final schema ensures minimal redundancy and strong relational integrity.  

---

## 📂 Project Structure
📦 EasyBuy-Database
┣ 📜 Run to create the database.sql   # SQL script to build & populate DB
┣ 📜 DBD 281 Project ERD.pdf           # Entity-Relationship Diagram (3NF)


---

## 🗄️ Database Schema (Summary)

| Table          | Key(s) | Description |
|----------------|--------|-------------|
| **Customers**  | CustomerID (PK) | Stores customer details & loyalty points |
| **Branches**   | BranchID (PK)   | Retail branch information |
| **Employees**  | EmployeeID (PK) | Employee details, roles, reporting hierarchy |
| **Orders**     | OrderID (PK)    | Customer orders linked to employees & branches |
| **Audit Log**  | AuditID (PK)    | Tracks employee actions (Insert, Update, Delete, Access) |
| **Categories** | CategoryID (PK) | Product categories |
| **Suppliers**  | SupplierID (PK) | Supplier details & contact info |
| **Products**   | ProductID (PK)  | Product catalog linked to categories & suppliers |
| **Stock**      | StockID (PK)    | Stock levels per branch, expiry dates |
| **Order Details** | (OrderID, StockID) (PK) | Line items for each order |

---

## 📊 ERD (3NF)
The ERD illustrates:
- Relationships between **Customers, Orders, Products, Stock, Employees, Branches, Suppliers, Categories, and Audit Log**.  
- Normalization up to **Third Normal Form (3NF)** to eliminate redundancy.  

*(See `DBD 281 Project ERD.pdf` for full diagram.)*

---

## 🚀 Getting Started
### Prerequisites
- Microsoft SQL Server (2019 or later recommended).
- SQL Server Management Studio (SSMS).

### Setup Instructions
1. Clone this repository using GitHub Desktop:
   or use bash: git clone https://github.com/Henri-Claassen/SQL-Server-Script.git
2. Open SQL Server Management Studio
3. Run the script in SQL server
4. Verify tables and sample data using:
  USE EasyBuy;
  SELECT * FROM Customers;
  SELECT * FROM Products;

