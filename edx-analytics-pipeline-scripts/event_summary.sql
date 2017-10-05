CREATE TABLE IF NOT EXISTS event_summary (
        project VARCHAR(255),
        event_type VARCHAR(255),
        event_count INTEGER,
        event_date DATE
);
INSERT INTO event_summary (
        SELECT
                project,
                event_type,
                COUNT(*) AS event_count,
                DATE(received_at) AS event_date
        FROM
                experimental_events_run14.event_records
        WHERE
                TO_CHAR(DATE(TIMESTAMPADD(DAY, -1, CURRENT_TIMESTAMP(0)))) < received_at
                AND received_at < TO_CHAR(CURRENT_DATE())
        GROUP BY
                project,
                event_type,
                DATE(received_at)
);
