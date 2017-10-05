-- Intent of this pipeline is to get a daily log of trackable users (valid user_id) who have visited edX and how they arrived on the platform
-- Most of this is based on Gabe's work: https://openedx.atlassian.net/wiki/display/AN/UTM+Code+Attribution+Model

-- This is very important since we are doing a bunch of casting of strings to timestamps. This tells vertica what timezone the string is from.
SET TIME ZONE TO UTC;

-- Find all page views that contain UTM parameters in the first part of the union.
-- AdWords Campaign clicks do not include UTM parameters in the URL, instead they append a "gclid" parameter,
-- so we have to grab those touches from the referral data and manufacture UTM parameters for them. (2nd union)

DROP TABLE IF EXISTS tmp_utm_touch_daily;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_utm_touch_daily ON COMMIT PRESERVE ROWS AS 

SELECT 
    DATE(timestamp) AS date,
    timestamp,
    utm.user_id,
    anonymous_id,
    project,
    path,
    search,
    referrer,
    referring_domain,
    agent_type,
    agent_os,
    domain,
    campaign_source,
    campaign_medium,
    campaign_content,
    campaign_name
FROM
(
    SELECT   
        CAST(e.received_at AS TIMESTAMPTZ) AS timestamp, 
        e.user_id,
        e.anonymous_id,
        e.project,
        e.path,
        e.search,
        e.referrer,   -- This is different for tracking log events.
        SPLIT_PART(e.referrer, '/', 3) AS referring_domain,
        e.agent_type,
        e.agent_os, 
        CASE 
            WHEN POSITION('http' in e.url) > 0 THEN SPLIT_PART(e.url, '/', 3) 
            ELSE 'unknown' 
        END AS domain, 
        e.campaign_source,  
        e.campaign_medium,
        e.campaign_content,  
        e.campaign_name 
    FROM
        experimental_events_run14.event_records e
    JOIN
        (
            SELECT
                MAX(date) AS latest_date
            FROM
                business_intelligence.utm_touch
        ) latest
    ON
        DATE(e.timestamp) > latest.latest_date
    AND   
        e.event_type = 'page'  
    AND 
        (e.campaign_source IS NOT NULL
        OR e.campaign_medium IS NOT NULL        
        OR e.campaign_content IS NOT NULL        
        OR e.campaign_name IS NOT NULL) 

    UNION ALL

    SELECT
        CAST(e.received_at AS TIMESTAMPTZ) AS timestamp,
        e.user_id,
        e.anonymous_id,
        e.project,
        e.path,
        e.search,
        e.referrer,
        SPLIT_PART(e.referrer, '/', 3) AS referring_domain,
        e.agent_type,
        e.agent_os,
        CASE 
            WHEN POSITION('http' in e.url) > 0 THEN SPLIT_PART(e.url, '/', 3) 
            ELSE 'unknown' 
        END AS domain,
        'google' AS campaign_source,
        'cpc' AS campaign_medium,
        NULL AS campaign_content,
        NULL AS campaign_name
    FROM 
        experimental_events_run14.event_records e
    JOIN
        (
            SELECT
                MAX(date) AS latest_date
            FROM
                business_intelligence.utm_touch
        ) latest
    ON
        DATE(e.timestamp) > latest.latest_date
    AND
        e.event_type = 'page'
    AND 
        SPLIT_PART(e.referrer, '/', 3) NOT ILIKE '%edx.org%'
    AND 
        SPLIT_PART(e.referrer, '/', 3) NOT IN ('mitprofessionalx.mit.edu', 
            'courses.harvardxplus.harvard.edu', 
            'digital.juilliard.edu',
            'online.wharton.upenn.edu',
            'globalacademy.hms.harvard.edu')
    AND 
        e.referrer IS NOT NULL
    AND 
        e.referrer != ''
    AND 
        e.campaign_source IS NULL
    AND 
        REGEXP_SUBSTR(e.search, 'gclid=([^&]+)', 1, 1, '', 1) IS NOT NULL
) utm;

-- Unsure of what attribution window/model we care about, so aggregating all UTM touches.

DROP TABLE IF EXISTS tmp_utm_touch;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_utm_touch ON COMMIT PRESERVE ROWS AS 

SELECT 
    DISTINCT date,
    COALESCE(CAST(identify.user_id AS VARCHAR), CAST(raw.user_id AS VARCHAR)) AS user_id,
    raw.anonymous_id,
    timestamp,
    raw.domain,
    campaign_source,
    campaign_medium,
    campaign_content,
    campaign_name
FROM
(
    SELECT
        date,
        anonymous_id,
        user_id,
        timestamp,
        domain,
        campaign_source,
        campaign_medium,
        campaign_content,
        campaign_name
    FROM 
        utm_touch

    UNION ALL

    SELECT
        date,
        anonymous_id,
        user_id,
        timestamp,
        domain,
        campaign_source,
        campaign_medium,
        campaign_content,
        campaign_name
    FROM 
        tmp_utm_touch_daily
) raw
LEFT JOIN
    business_intelligence.identify identify
ON
    raw.anonymous_id = identify.anonymous_id;

DROP TABLE IF EXISTS utm_touch;
CREATE TABLE IF NOT EXISTS utm_touch AS

SELECT
    date,
    user_id,
    anonymous_id,
    timestamp,
    domain,
    campaign_source,
    campaign_medium,
    campaign_content,
    campaign_name
FROM
     tmp_utm_touch;

DROP TABLE tmp_utm_touch;
DROP TABLE tmp_utm_touch_daily;

GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO standard;
GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO analyst;