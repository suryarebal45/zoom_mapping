{{ config(
    materialized='incremental',
    unique_key='billing_fact_id',
    schema='FACT',
    pre_hook="{{ fact_audit_log_start('go_billing_facts') }}",
    post_hook="{{ fact_audit_log_end('go_billing_facts', 0) }}",
    cluster_by=['load_date']
) }}

with base_billing as (
    select
        be.event_id,
        be.user_id,
        coalesce(u.company, 'INDIVIDUAL') as organization_id,
        upper(trim(be.event_type)) as event_type,
        round(be.amount, 2) as amount,
        be.event_date,
        date_trunc('month', be.event_date) as billing_period_start,
        last_day(be.event_date) as billing_period_end,
        'Credit Card' as payment_method,
        case when be.amount > 0 then 'Completed' else 'Refunded' end as transaction_status,
        'USD' as currency_code,
        round(be.amount * 0.08, 2) as tax_amount,
        0.00 as discount_amount,
        be.load_date,
        be.source_system
    from {{ source('silver', 'sv_billing_events') }} be
    left join {{ source('silver', 'sv_users') }} u on be.user_id = u.user_id
    where be.record_status = 'VALID'
),

final as (
    select
        concat('BF_', event_id, '_', user_id) as billing_fact_id,
        event_id,
        user_id,
        organization_id,
        event_type,
        amount,
        event_date,
        billing_period_start,
        billing_period_end,
        payment_method,
        transaction_status,
        currency_code,
        tax_amount,
        discount_amount,
        load_date,
        current_date() as update_date,
        source_system
    from base_billing
)

select * from final
