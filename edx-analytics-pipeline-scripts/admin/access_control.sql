CREATE ROLE standard;
GRANT USAGE ON SCHEMA curated TO standard;
GRANT SELECT ON ALL TABLES IN SCHEMA curated TO standard;
GRANT USAGE ON SCHEMA ed_services TO standard;
GRANT SELECT ON ALL TABLES IN SCHEMA ed_services TO standard;
GRANT USAGE ON SCHEMA finance TO standard;
GRANT SELECT ON finance.f_orderitem_transactions TO standard;
-- SELECT is granted programmatically for these
GRANT USAGE ON SCHEMA production TO standard;
GRANT USAGE ON SCHEMA business_intelligence TO standard;

CREATE ROLE restricted;
GRANT standard TO restricted;
GRANT USAGE ON SCHEMA experimental TO restricted;
GRANT USAGE ON SCHEMA experimental_events_run14 TO restricted;
GRANT USAGE ON SCHEMA marketing TO restricted;
