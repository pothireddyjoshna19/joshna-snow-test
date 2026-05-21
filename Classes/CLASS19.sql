use oms_dev.bronze;


CREATE OR REPLACE FUNCTION calc_sum( a int , b int )
RETURNS int
LANGUAGE SQL
AS
   $$
      a + b
   $$
;


///call function 
select calc_sum (30,20) ;

select calc_sum (303,204) ;


CREATE OR REPLACE FUNCTION calc_sim_int( p int , t int, r int )
RETURNS int
LANGUAGE SQL
AS
   $$
      (p * T * R) / 100 
   $$
;


select calc_sim_int(100000 , 10 , 2) ;

select sysdate() ;

CREATE OR REPLACE FUNCTION get_date(business_date timestamp)
RETURNS DATE
LANGUAGE SQL
AS
$$
    TO_DATE(SUBSTR(TO_CHAR(business_date),1,10))
$$;



select get_date(sysdate() ) ;



CREATE OR REPLACE TABLE sales_by_country(
year NUMBER(4),
country VARCHAR(50),
sale_amount NUMBER
);


INSERT INTO SALES_BY_COUNTRY VALUES
('2022','US','90000'),
('2022','UK','75000'),
('2022','FR','55000'),
('2023','US','100000'),
('2023','UK','80000'),
('2023','FR','70000');

CREATE OR REPLACE TABLE currency(
country VARCHAR(50),
currency VARCHAR(3)
);	

INSERT INTO CURRENCY VALUES
('US','USD'),
('UK','GBP'),
('FR','EUR');




CREATE OR REPLACE FUNCTION get_sales(country_name VARCHAR)
RETURNS TABLE (year NUMBER, sale_amount NUMBER, country VARCHAR)
AS
$$
SELECT year, sale_amount, country
FROM sales_by_country
WHERE country = country_name
$$
;


SELECT * FROM TABLE(get_sales('US'));

----------------------------------------------------------

CREATE or replace TABLE OMS_DEV.BRONZE.EMPLOYEE (
    emp_id NUMBER AUTOINCREMENT START 100 INCREMENT 1,
    emp_name VARCHAR,
    emp_dept VARCHAR,
    emp_status VARCHAR,
    emp_salary NUMBER
);

INSERT INTO OMS_DEV.BRONZE.EMPLOYEE (emp_name, emp_dept, emp_status, emp_salary)
VALUES
    ('John Smith', 'Engineering', 'Active', 85000),
    ('Jane Doe', 'Marketing', 'Active', 72000);


CREATE OR REPLACE PROCEDURE OMS_DEV.BRONZE.INSERT_EMPLOYEE(
    p_emp_name VARCHAR,
    p_emp_dept VARCHAR,
    p_emp_status VARCHAR,
    p_emp_salary NUMBER
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    INSERT INTO OMS_DEV.BRONZE.EMPLOYEE (emp_name, emp_dept, emp_status, emp_salary)
    VALUES (:p_emp_name, :p_emp_dept, :p_emp_status, :p_emp_salary);
    RETURN 'Employee inserted successfully';
END;
$$;

CALL OMS_DEV.BRONZE.INSERT_EMPLOYEE('John Smith', 'Engineering', 'Active', 85000);
CALL OMS_DEV.BRONZE.INSERT_EMPLOYEE('Jane Doe', 'Marketing', 'Active', 72000);

SELECT * FROM OMS_DEV.BRONZE.EMPLOYEE;


delete from employee;

///using stored proc 
CALL OMS_DEV.BRONZE.INSERT_EMPLOYEE('Vamsi ', 'IT', 'Active', 85000);


---employee is going to resign from org 

CREATE OR REPLACE PROCEDURE OMS_DEV.BRONZE.DEACTIVATE_EMPLOYEE(
    p_emp_id NUMBER
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    UPDATE OMS_DEV.BRONZE.EMPLOYEE
    SET emp_status = 'Inactive'
    WHERE emp_id = :p_emp_id;
    RETURN 'Employee status updated to Inactive';
END;
$$;

CALL OMS_DEV.BRONZE.DEACTIVATE_EMPLOYEE(200);

SELECT * FROM OMS_DEV.BRONZE.EMPLOYEE;

CREATE OR REPLACE PROCEDURE OMS_DEV.BRONZE.DELETE_INACTIVE_EMPLOYEES()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    DELETE FROM OMS_DEV.BRONZE.EMPLOYEE
    WHERE emp_status = 'Inactive';
    RETURN 'Inactive employees deleted successfully';
END;
$$;

CALL OMS_DEV.BRONZE.DELETE_INACTIVE_EMPLOYEES();

SELECT * FROM OMS_DEV.BRONZE.EMPLOYEE;



CREATE OR REPLACE TASK OMS_DEV.BRONZE.TASK_DELETE_INACTIVE_EMPLOYEES
    WAREHOUSE = 'COMPUTE_WH'
    SCHEDULE = 'USING CRON 0 19 * * * America/New_York'
AS
    CALL OMS_DEV.BRONZE.DELETE_INACTIVE_EMPLOYEES();

ALTER TASK OMS_DEV.BRONZE.TASK_DELETE_INACTIVE_EMPLOYEES RESUME;


---procedure to load data from AWS to snowflake 
--input --s3 url , table name    

CREATE OR REPLACE PROCEDURE OMS_DEV.BRONZE.LOAD_FROM_S3(
    p_s3_url VARCHAR,
    p_table_name VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE STAGE OMS_DEV.BRONZE.TEMP_S3_STAGE
        URL = ''' || :p_s3_url || '''
        STORAGE_INTEGRATION = S3_INT
        FILE_FORMAT = (TYPE = ''CSV'' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = ''"'')';

    EXECUTE IMMEDIATE 'COPY INTO OMS_DEV.BRONZE.' || :p_table_name ||
        ' FROM @OMS_DEV.BRONZE.TEMP_S3_STAGE';

    RETURN 'Data loaded successfully into ' || :p_table_name;
END;
$$;

CALL OMS_DEV.BRONZE.LOAD_FROM_S3('s3://joshna-snow-20/csv/employee_data_1.csv/', 'EMPLOYEE');


select * from OMS_DEV.BRONZE.ORDERS;

