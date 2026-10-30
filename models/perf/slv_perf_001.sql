{{ config(
    materialized         = 'incremental',
    incremental_strategy = 'merge',
    unique_key           = 'Id',
    file_format          = 'delta',
    database             = 'lh_silver',
    schema               = 'dbt_perf',
    tags                 = ['perf', 'n01', 'n05', 'n10', 'n20', 'n50', 'n100'],
    post_hook            = "delete from {{ this }} where IsDeleted = true"
) }}

with src as (
    select
        Id,
        Name                                    as OpportunityName,
        try_cast(Amount as decimal(18,2))       as Amount,
        StageName,
        sha2(cast(Email as string), 256)        as Email,
        cast(IsDeleted as boolean)              as IsDeleted,
        try_cast(LastModifiedDate as timestamp) as LastModifiedDate,
        _ingested_at_brz
    from {{ source('bronze_perf', 'brz_perf_001') }}
    {% if is_incremental() %}
    where try_cast(LastModifiedDate as timestamp)
          >= (select max(LastModifiedDate) from {{ this }}) - interval 1 day
    {% endif %}
),
ranked as (
    select *, row_number() over (partition by Id order by LastModifiedDate desc, _ingested_at_brz desc) as rn
    from src
)
select Id, OpportunityName, Amount, StageName, Email, IsDeleted, LastModifiedDate,
       current_timestamp() as _ingested_at_silver
from ranked
where rn = 1
