CREATE TABLE IF NOT EXISTS business_intelligence.experiment_exposure (
    received_at TIMESTAMPTZ,
    timestamp TIMESTAMPTZ,
    anonymous_id VARCHAR(255),
    raw_user_id VARCHAR(255),
    user_id INT,
    experiment_id INT,
    experiment_name VARCHAR(255),
    variation_id INT,
    variation_name VARCHAR(255),
    course_id VARCHAR(2047),
    path VARCHAR(2047),
    url VARCHAR(2047)
);

--dummy insert to initialize the table

INSERT INTO business_intelligence.experiment_exposure (received_at)
SELECT
    '2012-08-31'::TIMESTAMPTZ
FROM 
    business_intelligence.experiment_exposure
HAVING 
    COUNT(received_at)=0;

INSERT INTO business_intelligence.experiment_exposure (

SELECT
    event.received_at::TIMESTAMPTZ,
    timestamp::TIMESTAMPTZ,
    anonymous_id,
    user_id AS raw_user_id,
    CASE
        WHEN REGEXP_LIKE(user_id, '^\d+$') THEN user_id::INT
        ELSE NULL
    END AS user_id,
    experimentid::INT AS experiment_id,
    experimentname AS experiment_name,
    variationid::INT AS variation_id,
    variationname AS variation_name,
    CASE 
        WHEN STRPOS(path, '%') = 0 THEN REGEXP_SUBSTR(path, '/courses/([^/+]+(/|\+)[^/+]+(/|\+)[^/?]+)/', 1, 1, '', 1)
        ELSE URI_PERCENT_DECODE(REGEXP_SUBSTR(path, '/courses/([^/+]+(/|\+)[^/+]+(/|\+)[^/?]+)/', 1, 1, '', 1))
    END AS course_id,
    path,
    url
FROM
    experimental_events_run14.event_records event
JOIN
    (
        SELECT
            MAX(received_at) AS received_at
        FROM
            business_intelligence.experiment_exposure    
    ) latest
ON
    event.received_at::TIMESTAMPTZ > latest.received_at::TIMESTAMPTZ
AND
    event_type = 'Experiment Viewed');
