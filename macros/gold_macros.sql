{% macro audit_log_start(table_name) %}
    {% set table_name_val = table_name if table_name is not none else 'UNKNOWN' %}
    INSERT INTO ZOOM.silver.sv_audit_log (
        process_id,
        table_name,
        process_start_time,
        status,
        created_at
    )
    VALUES (
        UUID_STRING(),
        '{{ table_name_val }}',
        CURRENT_TIMESTAMP(),
        'STARTED',
        CURRENT_TIMESTAMP()
    );
{% endmacro %}

{% macro audit_log_end(table_name, status='SUCCESS', records_processed=null, records_successful=null, records_failed=null) %}
    {% set table_name_val = table_name if table_name is not none else 'UNKNOWN' %}
    UPDATE ZOOM.silver.sv_audit_log
    SET 
        process_end_time = CURRENT_TIMESTAMP(),
        status = '{{ status }}',
        records_processed = {{ records_processed if records_processed is not none else 'records_processed' }},
        records_successful = {{ records_successful if records_successful is not none else 'records_successful' }},
        records_failed = {{ records_failed if records_failed is not none else 'records_failed' }}
    WHERE table_name = '{{ table_name_val }}'
      AND status = 'STARTED'
      AND process_end_time IS NULL;
{% endmacro %}
