DROP TABLE business_intelligence.calendar_stg;
CREATE table business_intelligence.calendar_stg
(
    date DATE primary key
);

Insert into business_intelligence.calendar_stg (select '2014-01-01' from production.f_user_activity);
Insert into business_intelligence.calendar_stg (select '2019-01-01' from production.f_user_activity);

DROP TABLE business_intelligence.calendar;
CREATE TABLE business_intelligence.calendar AS

SELECT CAST(slice_time AS DATE) date
  FROM business_intelligence.calendar_stg mtc
  TIMESERIES slice_time as '1 day'
  OVER (ORDER BY CAST(mtc.date as TIMESTAMP));
DROP TABLE business_intelligence.calendar_stg;
  