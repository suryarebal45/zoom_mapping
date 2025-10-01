{% macro bz_audit_log_start() %}
  {% if this.name != 'bz_audit_log' %}
    INSERT INTO {{ ref('bz_audit_log') }} (
      table_name,
      process_start_time,
      process_status,
      created_at
    )
    VALUES (
      '{{ this.name }}',
      CURRENT_TIMESTAMP(),
      'STARTED',
      CURRENT_TIMESTAMP()
    )
  {% endif %}
{% endmacro %}

-- Macro for audit log end
{% macro bz_audit_log_end() %}
  {% if this.name != 'bz_audit_log' %}
    INSERT INTO {{ ref('bz_audit_log') }} (
      table_name,
      process_end_time,
      process_status,
      updated_at
    )
    VALUES (
      '{{ this.name }}',
      CURRENT_TIMESTAMP(),
      'COMPLETED',
      CURRENT_TIMESTAMP()
    )
  {% endif %}
{% endmacro %}