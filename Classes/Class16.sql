CREATE DATABASE OS_JO;
CREATE SCHEMA GOLD;

CREATE OR REPLACE TABLE OS_JO.GOLD.ORDERS (
    ORDER_ID NUMBER AUTOINCREMENT PRIMARY KEY,
    CUSTOMER_NAME VARCHAR(100),
    PRODUCT_NAME VARCHAR(100),
    QUANTITY NUMBER,
    PRICE DECIMAL(10,2),
    ORDER_DATE DATE DEFAULT CURRENT_DATE
);

INSERT INTO OS_JO.GOLD.ORDERS (CUSTOMER_NAME, PRODUCT_NAME, QUANTITY, PRICE, ORDER_DATE)
VALUES
    ('Alice Johnson', 'Laptop', 1, 999.99, '2025-01-15'),
    ('Bob Smith', 'Keyboard', 3, 49.99, '2025-02-10'),
    ('Charlie Brown', 'Mouse', 2, 29.99, '2025-02-20'),
    ('Diana Prince', 'Monitor', 1, 349.99, '2025-03-05'),
    ('Edward Norton', 'Headphones', 5, 79.99, '2025-03-18');

select * from OS_JO.GOLD.ORDERS ;

CREATE OR REPLACE TABLE OS_JO.GOLD.ORDERS_J (
    ORDER_ID NUMBER AUTOINCREMENT PRIMARY KEY,
    CUSTOMER_NAME VARCHAR(100),
    PRODUCT_NAME VARCHAR(100),
    QUANTITY NUMBER,
    PRICE DECIMAL(10,2),
    ORDER_DATE DATE DEFAULT CURRENT_DATE
);

INSERT INTO OS_JO.GOLD.ORDERS_J (CUSTOMER_NAME, PRODUCT_NAME, QUANTITY, PRICE, ORDER_DATE)
VALUES
    ('John Doe', 'Tablet', 2, 499.99, '2025-04-01'),
    ('Jane Smith', 'Printer', 1, 199.99, '2025-04-10'),
    ('James Wilson', 'Webcam', 3, 89.99, '2025-04-15'),
    ('Julia Roberts', 'Speaker', 4, 59.99, '2025-05-02'),
    ('Jack Turner', 'Charger', 6, 24.99, '2025-05-12');

--create shared object
CREATE SHARE oms_share;

--grant permissions to DATABASE schema tables (OMS_DEV.BRONZE.ORDERS)
GRANT USAGE ON DATABASE OS_JO TO SHARE oms_share;
GRANT USAGE ON SCHEMA OS_JO.GOLD TO SHARE oms_share;
GRANT SELECT ON TABLE OS_JO.GOLD.ORDERS TO SHARE oms_share;
GRANT SELECT ON TABLE OS_JO.GOLD.ORDERS_J TO SHARE oms_share;

show shares ;

--provide access to consumer
ALTER SHARE oms_share ADD ACCOUNTS = IDNZXJB.JOTECH_READER_ACCT


--delete from  OS_JO.GOLD.ORDERS where quantity < 10 ;




---------------------------from consumer account need to perform below ---------------

show shares ;


describe share IDNZXJB.WB73357.OMS_SHARE;


create database  OS_JO  from  share IDNZXJB.WB73357.OMS_SHARE;


select * from OS_JO.GOLD.ORDERS ;


-------------------very first step create accounts------------------------

CREATE MANAGED ACCOUNT jotech_reader_acct
    ADMIN_NAME = jotech_reader_admin,
    ADMIN_PASSWORD = 'Test@123456789',
    TYPE = READER;


CREATE MANAGED ACCOUNT jotech_reader_acct1
    ADMIN_NAME = jotech_reader_admin1,
    ADMIN_PASSWORD = 'Test@123456789',
    TYPE = READER;


show managed accounts;

--https://afzhtdg-vitech_reader_acct.snowflakecomputing.com/



---------------------------------------------------------------

-- Prepare table --
create or replace table customers(
  id number,
  full_name varchar,
  email varchar,
  phone varchar,
  spent number,
  create_date DATE DEFAULT CURRENT_DATE);

-- insert values in table --
insert into customers (id, full_name, email,phone,spent)
values
  (1,'Lewiss MacDwyer','lmacdwyer0@un.org','262-665-9168',140),
  (2,'Ty Pettingall','tpettingall1@mayoclinic.com','734-987-7120',254),
  (3,'Marlee Spadazzi','mspadazzi2@txnews.com','867-946-3659',120),
  (4,'Heywood Tearney','htearney3@patch.com','563-853-8192',1230),
  (5,'Odilia Seti','oseti4@globo.com','730-451-8637',143),
  (6,'Meggie Washtell','mwashtell5@rediff.com','568-896-6138',600);

select * from customers;
-- set up roles
CREATE OR REPLACE ROLE ANALYST_MASKED;
CREATE OR REPLACE ROLE ANALYST_FULL;

GRANT USAGE ON DATABASE OS_JO TO ROLE ANALYST_MASKED;
GRANT USAGE ON DATABASE OS_JO TO ROLE ANALYST_FULL;

-- grant select on table to roles
GRANT SELECT ON TABLE OS_JO.GOLD.CUSTOMERS TO ROLE ANALYST_MASKED;
GRANT SELECT ON TABLE OS_JO.GOLD.CUSTOMERS TO ROLE ANALYST_FULL;

GRANT USAGE ON SCHEMA OS_JO.GOLD TO ROLE ANALYST_MASKED;
GRANT USAGE ON SCHEMA OS_JO.GOLD TO ROLE ANALYST_FULL;

-- grant warehouse access to roles
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ANALYST_MASKED;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ANALYST_FULL;


-- assign roles to a user
GRANT ROLE ANALYST_MASKED TO USER JOSHNAPOTHIREDDY19;
GRANT ROLE ANALYST_FULL TO USER JOSHNAPOTHIREDDY19;

select current_user() ;

-- Set up masking policy

create or replace masking policy phone
    as (val varchar) returns varchar ->
            case        
            when current_role() in ('ANALYST_FULL', 'ACCOUNTADMIN') then val
            else '##-###-##'
            end;
 

-- Apply policy on a specific column
ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN phone
SET MASKING POLICY PHONE;


ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN email
SET MASKING POLICY PHONE;

-- Validating policies

USE ROLE ANALYST_FULL;
SELECT * FROM CUSTOMERS;

USE ROLE ANALYST_MASKED;
SELECT * FROM CUSTOMERS;




-- replace policy

use role accountadmin;

create or replace masking policy names as (val varchar) returns varchar ->
            case
            when current_role() in ('ANALYST_FULL', 'ACCOUNTADMIN') then val
            else CONCAT(LEFT(val,2),'*******')
            end;

-- apply policy
ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN full_name
SET MASKING POLICY names;


-- Validating policies
USE ROLE ANALYST_FULL;
SELECT * FROM CUSTOMERS;

USE ROLE ANALYST_MASKED;
SELECT * FROM CUSTOMERS;


-- Apply policy on a specific column
ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN phone
UNSET MASKING POLICY;


********9168
********7120


select * from customers;


select   id ,full_name ,email from customers;

use role accountadmin;


create table cust_ency  as
 select   id ,
    full_name ,
    ENCRYPT(email, 'MySecretPassphrase') AS encrypted_email from customers
;


select   id ,full_name ,TO_VARCHAR(DECRYPT(encrypted_email, 'MySecretPassphrase'), 'UTF-8') AS decrypted_email from cust_ency;


--h256 --
