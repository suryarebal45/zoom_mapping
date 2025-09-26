{% macro audit_log_start(model_name) %}
  INSERT INTO ZOOM.SILVER_GOLD.AUDIT_LOG (
    EXECUTION_ID,
    PIPELINE_NAME,
    START_TIME,
    STATUS,
    LOAD_DATE
  )
  SELECT
    UUID_STRING(),
    '{{ model_name }}',
    CURRENT_TIMESTAMP(),
    'STARTED',
    CURRENT_DATE();
{% endmacro %}
{% macro audit_log_end(model_name, status='COMPLETED', records_processed=0, records_successful=0, records_failed=0) %}
  UPDATE ZOOM.SILVER_GOLD.AUDIT_LOG
  SET 
    END_TIME = CURRENT_TIMESTAMP(),
    STATUS = '{{ status }}',
    RECORDS_PROCESSED = {{ records_processed }},
    RECORDS_SUCCESSFUL = {{ records_successful }},
    RECORDS_FAILED = {{ records_failed }},
    PROCESSING_DURATION_SECONDS = DATEDIFF('second', START_TIME, CURRENT_TIMESTAMP()),
    UPDATE_DATE = CURRENT_TIMESTAMP()
  WHERE PIPELINE_NAME = '{{ model_name }}'
    AND STATUS = 'STARTED';
{% endmacro %}
