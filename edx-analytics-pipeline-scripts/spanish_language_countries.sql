--based on list provided here: https://openedx.atlassian.net/browse/BI-191

DROP TABLE IF EXISTS business_intelligence.spanish_language_countries;
CREATE TABLE IF NOT EXISTS business_intelligence.spanish_language_countries AS

SELECT
	country_name,
	user_last_location_country_code
FROM 
	production.d_country
WHERE 
	country_name IN
(
	'Argentina',
	'Bolivia',
	'Chile',
	'Colombia',
	'Costa Rica',
	'Cuba',
	'Dominican Republic',
	'Ecuador',
	'El Salvador',
	'Equatorial Guinea',
	'Guatemala',
	'Honduras',
	'Mexico',
	'Nicaragua',
	'Panama',
	'Paraguay',
	'Peru',
	'Spain',
	'Uruguay',
	'Venezuela'
);
