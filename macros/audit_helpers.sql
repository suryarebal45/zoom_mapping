-- macros/audit_helpers.sql

{% macro audit_model_start(model_name, audit_table) %}
  {% if execute %}
    {% set audit_sql %}
      INSERT INTO {{ audit_table }} (
        execution_id, pipeline_name, process_type, start_time, status, 
        source_system, target_system, load_date
      ) VALUES (
        '{{ invocation_id }}', '{{ model_name }}', 'DBT_MODEL_EXECUTION',
        CURRENT_TIMESTAMP(), 'STARTED', 'Silver', 'Dim', CURRENT_DATE()
      )
    {% endset %}
    {% do run_query(audit_sql) %}
  {% endif %}
{% endmacro %}


{% macro audit_model_end(model_name, audit_table, record_count=0) %}
  {% if execute %}
    {% set audit_sql %}
      UPDATE {{ audit_table }}
      SET 
        end_time = CURRENT_TIMESTAMP(),
        status = 'COMPLETED',
        processing_duration_seconds = DATEDIFF(second, start_time, CURRENT_TIMESTAMP()),
        records_processed = {{ record_count }},
        records_successful = {{ record_count }},
        records_failed = 0,
        update_date = CURRENT_DATE()
      WHERE execution_id = '{{ invocation_id }}'
        AND pipeline_name = '{{ model_name }}'
        AND status = 'STARTED'
    {% endset %}
    {% do run_query(audit_sql) %}
  {% endif %}
{% endmacro %}


-- -------------------------------------------------------------------
-- Wrappers for backwards compatibility (so models can call log_* macros)
-- These always write to the dim.go_process_audit table
-- -------------------------------------------------------------------

{% macro dim_audit_log_start(model_name) %}
  {{ audit_model_start(model_name, 'silver_dim.go_process_audit') }}
{% endmacro %}


{% macro dim_audit_log_end(model_name, status='SUCCESS', rec_processed=0, rec_success=0, rec_failed=0) %}
  {{ audit_model_end(model_name, 'silver_dim.go_process_audit', rec_processed) }}
{% endmacro %}
