--attempting to map anonymous_id to user_id and user_name
--always looking over the last 3 days in case we fall behind, the pipeline fails, etc. 
--we de-dupe later so no concern about data integrity, this is just a bit more robust.

DROP TABLE IF EXISTS tmp_identify_daily;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_identify_daily ON COMMIT PRESERVE ROWS AS 

SELECT
    id.anonymous_id,
    COALESCE(du0.user_id, du1.user_id) AS user_id,
    COALESCE(du0.user_username, du1.user_username) AS username,
    id.domain
FROM 
(
    SELECT DISTINCT
        anonymous_id,
        user_id, 
        CASE
            WHEN POSITION('http' in url) > 0 THEN (
                CASE WHEN POSITION('.edx.org' IN SPLIT_PART(url, '/', 3)) > 0 THEN 'edx.org' 
                ELSE SPLIT_PART(url, '/', 3) END) 
            ELSE 'unknown' 
        END AS domain
    FROM 
        experimental_events_run14.event_records
    WHERE
        event_category = 'identify'
    AND 
        anonymous_id IS NOT NULL
    AND 
        user_id IS NOT NULL
    AND 
        DATE(timestamp) > CURRENT_DATE() - 3
) id
LEFT JOIN 
    production.d_user du0 
ON
    CAST(du0.user_id AS VARCHAR) = id.user_id
LEFT JOIN 
    production.d_user du1 
ON
    du1.user_username = id.user_id;

DROP TABLE IF EXISTS tmp_identify;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_identify ON COMMIT PRESERVE ROWS AS 

SELECT
    anonymous_id,
    user_id,
    username,
    domain
FROM
    business_intelligence.identify

UNION DISTINCT

SELECT
    anonymous_id,
    user_id,
    username,
    domain
FROM
    tmp_identify_daily    
;

DROP TABLE IF EXISTS identify;
CREATE TABLE IF NOT EXISTS identify AS

SELECT
    anonymous_id,
    user_id,
    username,
    domain
FROM
     tmp_identify;

DROP TABLE tmp_identify_daily;
DROP TABLE tmp_identify;

GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO standard;
GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO analyst;