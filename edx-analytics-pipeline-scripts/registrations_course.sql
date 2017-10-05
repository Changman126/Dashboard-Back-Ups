CREATE TABLE IF NOT EXISTS cnt_registrations_course (
        date DATE,
        event_type VARCHAR(255),
        course_id VARCHAR(255),
        cnt_registrations INTEGER
);

INSERT INTO cnt_registrations_course (
	SELECT 
		DATE(received_at) AS date, 
		event_type, 
		COALESCE(label, 'No associated course') AS course_id, 
		COUNT(1) AS cnt_registrations
	FROM 
		experimental_events_run14.event_records 
	WHERE 
		event_type = 'edx.bi.user.account.registered'
	AND
		TO_CHAR(DATE(TIMESTAMPADD(DAY, -1, CURRENT_TIMESTAMP(0)))) < received_at
                AND received_at < TO_CHAR(CURRENT_DATE())
	GROUP BY
		DATE(received_at),
	    	event_type,
		COALESCE(label, 'No associated course')
);
