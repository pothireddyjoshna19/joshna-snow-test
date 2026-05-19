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

LIST @AWS_INT.ext_stages.csv_folder; 

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
SELECT * FROM AWS_INT.PUBLIC.movie_titles;

-- Create Snowpipe
CREATE OR REPLACE PIPE AWS_INT.PUBLIC.movie_pipe
  AUTO_INGEST = TRUE
  AS
  COPY INTO AWS_INT.PUBLIC.movie_titles
    FROM @AWS_INT.ext_stages.csv_folder
    ON_ERROR = 'SKIP_FILE';

    DESCRIBE PIPE AWS_INT.PUBLIC.movie_pipe;

    ALTER PIPE AWS_INT.PUBLIC.movie_pipe REFRESH;

-- Verify pipe was created
SHOW PIPES IN DATABASE AWS_INT;

-- Check pipe status
SELECT SYSTEM$PIPE_STATUS('AWS_INT.PUBLIC.movie_pipe');

-- Pause pipe
ALTER PIPE AWS_INT.PUBLIC.movie_pipe SET PIPE_EXECUTION_PAUSED = TRUE;

-- Resume pipe
ALTER PIPE AWS_INT.PUBLIC.movie_pipe SET PIPE_EXECUTION_PAUSED = FALSE;
