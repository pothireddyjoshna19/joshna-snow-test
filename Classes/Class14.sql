CREATE DATABASE AW_INT;
USE DATABASE AW_INT;
CREATE SCHEMA FILE_FORMAT;
CREATE SCHEMA EXT_STAGE;


CREATE STORAGE INTEGRATION s3_ext
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::291883201267:role/joshna-s3role'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('s3://joshna-snow-20/csv/','s3://joshna-snow-20/json/','s3://joshna-snow-20/parquet/');

DESC INTEGRATION s3_ext;

CREATE OR REPLACE FILE FORMAT AW_INT.file_format.csv_fileformat
    TYPE = csv
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    NULL_IF = ('NULL', 'null')
    EMPTY_FIELD_AS_NULL = TRUE
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';

    CREATE OR REPLACE STAGE AW_INT.ext_stage.csv_folder
    URL = 's3://joshna-snow-20/parquet/'
    STORAGE_INTEGRATION = s3_ext
    FILE_FORMAT = AW_INT.file_format.csv_fileformat;
    
    LIST @AW_INT.ext_stage.csv_folder;

CREATE OR REPLACE TABLE AW_INT.file_format.cinema_titles (
  show_id STRING,
  type STRING,
  title STRING,
  director STRING,
  "cast" STRING,
  country STRING,
  date_added STRING,
  release_year STRING,
  rating STRING,
  duration STRING,
  listed_in STRING,
  description STRING
);

COPY INTO AW_INT.file_format.cinema_titles (show_id, type, title, director, "cast", country, date_added, release_year, rating, duration, listed_in, description)
    FROM (SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12 FROM @AW_INT.ext_stage.csv_folder)
    ON_ERROR='SKIP_FILE';

SELECT * FROM AW_INT.file_format.cinema_titles ;

ALTER TABLE AW_INT.file_format.cinema_titles 
     SET DATA_RETENTION_TIME_IN_DAYS = 10;


DELETE FROM AW_INT.file_format.cinema_titles;
--offset
SELECT * FROM  AW_INT.file_format.cinema_titles AT(OFFSET => -60*5);

--timestamp
SELECT * FROM AW_INT.file_format.cinema_titles AT(TIMESTAMP => DATEADD(MINUTES, -5, CURRENT_TIMESTAMP())::TIMESTAMP_LTZ);

--query id
SELECT * FROM AW_INT.file_format.cinema_titles BEFORE(STATEMENT => '01c455d5-0001-b55f-000e-9f1e000727a2');




create table  cinema_t1  as
(
  SELECT * FROM  AW_INT.file_format.cinema_titles AT(OFFSET => -60*5)
)
;


select * from AW_INT.ext_stage.cinema_t1 ;

insert into AW_INT.file_format.cinema_titles (
  select * from AW_INT.ext_stage.cinema_t1
)
;

update AW_INT.file_format.cinema_titles
   set release_year = '0'  
   ;


   select * from AW_INT.file_format.cinema_titles ;


   SELECT * FROM  AW_INT.file_format.cinema_titles AT(OFFSET => -60*1) ;


select sysdate() ;
   --timestamp
SELECT * FROM  AW_INT.file_format.cinema_titles AT(TIMESTAMP => '2026-05-13 04:40:00.000'::TIMESTAMP);

--query id
SELECT * FROM  AW_INT.file_format.cinema_titles BEFORE(STATEMENT => '01c45565-0001-b928-000e-9b02000eb6fa');



delete from cinema_titles where profit < 100 ;



------------------------------

  create or replace table etl.public.orders_c1    
        clone   AW_INT.file_format.cinema_titles;



  create or replace table etl.public.orders_c2    
        clone   AW_INT.file_format.cinema_titles ;


delete from etl.public.orders_c2 ;

 create or replace database   our_first_dbcopy
       clone   our_first_db  ;



   drop database     our_first_dbcopy;

   undrop database our_first_dbcopy ;

