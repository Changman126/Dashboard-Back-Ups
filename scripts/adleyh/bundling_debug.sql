select
user_id,
received_at,
path,
event_type,
experimentname,
experimentid,
variationname,
variationid

 from experimental_events_run14.event_records
where user_id::varchar IN
(
'14784663',
'15221730',
'11407682',
'11061942',
'8026772'

) and date(received_at) >= '2017-06-01'
--and event_type = 'Experiment Viewed'
--and experimentid = '8447410169'
and experimentname LIKE '%Program Purchase Test%'

select
user_id,
anonymous_id,
received_at,
path,
event_type,
experimentname,
experimentid,
variationname,
variationid

 from experimental_events_run14.event_records
where date(received_at) >= '2017-06-20'
--and event_type = 'Experiment Viewed'
--and experimentid = '8447410169'
AND (path like '%EDX-28536009%'
or path like '%EDX-27176757%'
or path like '%EDX-27215559%'
or path like '%EDX-28434454%'
or path like '%EDX-28519743%')