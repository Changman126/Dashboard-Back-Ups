
-- build country to region mapping table based on: https://github.com/lukes/ISO-3166-Countries-with-Regional-Codes

-- DROP TABLE business_intelligence.country_region_mapping;
-- CREATE TABLE business_intelligence.country_region_mapping (
-- 	country_name varchar(555), 
-- 	user_last_location_country_code varchar(555),
-- 	region varchar(555),
-- 	sub_region varchar(555)
-- 	);

-- COPY business_intelligence.country_region_mapping FROM LOCAL '/Users/adleyhemphill/ISO-3166-Countries-with-Regional-Codes/all/all.csv' WITH DELIMITER ',';

DROP TABLE IF EXISTS business_intelligence.d_user_categorized;
CREATE TABLE IF NOT EXISTS business_intelligence.d_user_categorized AS

SELECT
	d_user.user_id,
	d_user.user_year_of_birth,
	YEAR(CURRENT_DATE()) - d_user.user_year_of_birth AS user_age,
	CASE
		WHEN YEAR(CURRENT_DATE()) - d_user.user_year_of_birth BETWEEN 18 AND 34 THEN 'Millenial'
		WHEN YEAR(CURRENT_DATE()) - d_user.user_year_of_birth BETWEEN 35 AND 50 THEN 'Generation X'
		WHEN YEAR(CURRENT_DATE()) - d_user.user_year_of_birth BETWEEN 51 AND 69 THEN 'Baby Boomer'
		WHEN YEAR(CURRENT_DATE()) - d_user.user_year_of_birth BETWEEN 70 AND 87 THEN 'Silent Generation'
		ELSE 'NA'
	END AS user_age_category,
	d_user.user_level_of_education,
	CASE
		WHEN d_user.user_level_of_education = 'jhs' THEN 'Junior High School'
		WHEN d_user.user_level_of_education = 'hs' THEN 'High School'
		WHEN d_user.user_level_of_education = 'a' THEN 'Associates'
		WHEN d_user.user_level_of_education = 'b' THEN 'Bachelors'
		WHEN d_user.user_level_of_education = 'm' THEN 'Masters'
		WHEN d_user.user_level_of_education = 'p' THEN 'PhD'
		ELSE 'NA'
	END AS user_education_level_category,
	d_user.user_gender,
	CASE
		WHEN d_user.user_gender = 'm' THEN 'male'
		WHEN d_user.user_gender = 'f' THEN 'female'
		ELSE 'NA'
	END AS user_gender_category,
	d_user.user_email,
	d_user.user_username,
	d_user.user_account_creation_time,
	YEAR(d_user.user_account_creation_time) AS user_year_registered,
	d_user.user_last_location_country_code,
	d_country.country_name AS user_country,
	mapping.region AS user_region,
	mapping.sub_region AS user_subregion
FROM
	production.d_user d_user
LEFT JOIN
	production.d_country d_country
ON
	d_user.user_last_location_country_code = d_country.user_last_location_country_code
LEFT JOIN
	business_intelligence.country_region_mapping mapping
ON
	d_user.user_last_location_country_code = mapping.user_last_location_country_code;