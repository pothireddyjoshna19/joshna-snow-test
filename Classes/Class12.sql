CREATE DATABASE AWS_INT;
USE DATABASE AWS_INT;
CREATE SCHEMA FILE_FORMATS;
CREATE SCHEMA EXT_STAGES;

CREATE STORAGE INTEGRATION s3_int
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::291883201267:role/joshna-s3role'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('s3://joshna-snow-20/csv/','s3://joshna-snow-20/json/');

DESC INTEGRATION s3_int;

CREATE OR REPLACE FILE FORMAT AWS_INT.file_formats.csv_fileformat
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    NULL_IF = ('NULL', 'null')
    EMPTY_FIELD_AS_NULL = TRUE
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';

    CREATE OR REPLACE STAGE AWS_INT.ext_stages.csv_folder
    URL = 's3://joshna-snow-20/csv/'
    STORAGE_INTEGRATION = s3_int
    FILE_FORMAT = AWS_INT.file_formats.csv_fileformat;

LIST @AWS_INT.ext_stages.csv_folder 

CREATE OR REPLACE TABLE AWS_INT.PUBLIC.movie_titles (
  show_id STRING,
  type STRING,
  title STRING,
  director STRING,
  cast STRING,
  country STRING,
  date_added STRING,
  release_year STRING,
  rating STRING,
  duration STRING,
  listed_in STRING,
  description STRING
);

-- Copy data from S3
COPY INTO AWS_INT.PUBLIC.movie_titles
    FROM @AWS_INT.ext_stages.csv_folder
    ON_ERROR='SKIP_FILE';

-- Verify loaded data
SELECT * FROM AWS_INT.PUBLIC.movie_titles LIMIT 10;
    
CREATE OR REPLACE FILE FORMAT AWS_INT.file_formats.json_fileformat
    TYPE = JSON;

    CREATE OR REPLACE STAGE AWS_INT.ext_stages.json_folder
    URL = 's3://joshna-snow-20/json/'
    STORAGE_INTEGRATION = s3_int
    FILE_FORMAT = AWS_INT.file_formats.json_fileformat; 

CREATE OR REPLACE TABLE AWS_INT.PUBLIC.awsjson(raw_data VARIANT);

-- Load JSON data
COPY INTO AWS_INT.PUBLIC.awsjson
    FROM @AWS_INT.ext_stages.json_folder;



LIST @AWS_INT.ext_stages.json_folder;

-- Query JSON
SELECT $1:asin FROM AWS_INT.PUBLIC.awsjson;

-- Extract JSON columns with type casting and date formatting
SELECT 
    $1:asin::STRING as ASIN,
    $1:helpful as helpful,
    $1:overall as overall,
    $1:reviewText::STRING as reviewtext,
    $1:reviewerID::STRING,
    $1:reviewerName::STRING,
    $1:summary::STRING,
    DATE($1:unixReviewTime::INT) as review_date
FROM @AWS_INT.ext_stages.json_folder;

-- Complex date parsing with DATE_FROM_PARTS
SELECT 
    $1:asin::STRING as ASIN,
    $1:helpful as helpful,
    $1:overall as overall,
    $1:reviewText::STRING as reviewtext,
    TO_DATE($1:reviewTime::STRING, 'MM DD, YYYY') as parsed_review_date,
    $1:unixReviewTime::INT as unix_review_time
FROM @AWS_INT.ext_stages.json_folder;