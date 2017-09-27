https://github.com/annexare/Countries/blob/master/countries.json

  DROP TABLE IF EXISTS ahemphill.university_learner_demographics_content;
  CREATE TABLE IF NOT EXISTS ahemphill.university_learner_demographics_content AS
 SELECT
        g.country_code AS learner_country,
        b.course_id,
        g.language AS learner_language,
        b.content_language,
        CASE WHEN g.language = REGEXP_SUBSTR(b.content_language,'\w\w',1,1)  THEN 'Learner Language Matches Content Language' ELSE 'Learner Language Does Not Match Content Language' END AS within_country,
        count(1) as cnt_enrolls,
        count(first_verified_enrollment_time) as cnt_verifs
 from d_user_course a
 join d_course b
 on a.course_id = b.course_id
 and b.start_time > '2016-01-01'
 and b.content_language IS NOT NULL
 join d_user c
 on a.user_id = c.user_id
 join ahemphill.country_language_mapping g
 ON c.user_last_location_country_code = g.country_code
 GROUP BY 1,2,3,4;

 


  DROP TABLE IF EXISTS ahemphill.university_learner_demographics;
  CREATE TABLE IF NOT EXISTS ahemphill.university_learner_demographics AS

  SELECT
         d.country_code AS university_country,
         d.continent_code AS university_continent,
         g.language AS university_language,
         2016 - c.user_year_of_birth AS learner_age,
         c.user_level_of_education AS learner_level_of_education,
         c.user_gender AS learner_gender,
         e.country_code AS learner_country,
         e.continent_code AS learner_continent,
         h.language AS learner_language,
         f.subject_title,
         CASE WHEN d.country_code = e.country_code THEN 'Learner within Country' ELSE 'Learner out of Country' END AS within_country,
         CASE WHEN d.continent_code = e.continent_code THEN 'Learner within Continent' ELSE 'Learner out of Continent' END AS within_continent,
         CASE WHEN g.language = h.language THEN 'Learner Language Matches University Language' ELSE 'Learner Language Doesnt Match University Language' END AS within_language,
         count(1) as cnt_enrolls,
         count(first_verified_enrollment_time) as cnt_verifs
  from d_user_course a
  join d_course b
  on a.course_id = b.course_id
  and b.start_time > '2016-01-01'
  join d_user c
  on a.user_id = c.user_id
  join ahemphill.university_country_mapping d
  on b.org_id = d.university
  join ahemphill.country_region_mapping e
  on c.user_last_location_country_code = e.country_code
  join ahemphill.subjects_deduped  f
  on a.course_id = f.course_id
  join ahemphill.country_language_mapping g
  ON d.country_code = g.country_code
  join ahemphill.country_language_mapping h
  ON e.country_code = h.country_code
  GROUP BY 1,2,3,4,5,6,7,8,9,10,11;

CREATE TABLE IF NOT EXISTS ahemphill.university_country_mapping (
university VARCHAR(32),
country_code VARCHAR(2),
continent_code VARCHAR(2),
is_eu INT(1),
is_eu_non_GB(1)
);

INSERT INTO ahemphill.university_country_mapping (
SELECT 'TsinghuaX'	,'CN'	,'AS'	,0	,0
UNION
SELECT 'TokyoTechX'	,'JP'	,'AS'	,0	,0
UNION
SELECT 'WellesleyX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'HarvardXPLUS'	,'US'	,'NA'	,0	,0
UNION
SELECT 'DartmouthX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'KIx'	,'SE'	,'EU'	,1	,1
UNION
SELECT 'OsakaUx'	,'JP'	,'AS'	,0	,0
UNION
SELECT 'LouvainX'	,'BE'	,'EU'	,1	,1
UNION
SELECT 'MITProfessionalX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'AdelaideX'	,'AU'	,'OC'	,0	,0
UNION
SELECT 'UTHealthSPHx'	,'US'	,'NA'	,0	,0
UNION
SELECT 'ANUx'	,'AU'	,'OC'	,0	,0
UNION
SELECT 'CornellX_UQx'	,'US'	,'NA'	,0	,0
UNION
SELECT 'BabsonX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'PekingX'	,'CN'	,'AS'	,0	,0
UNION
SELECT 'BAx'	,'EG'	,'AF'	,0	,0
UNION
SELECT 'IITBombayX'	,'IN'	,'AS'	,0	,0
UNION
SELECT 'Peking'	,'CN'	,'AS'	,0	,0
UNION
SELECT 'BUx'	,'US'	,'NA'	,0	,0
UNION
SELECT 'VictoriaX'	,'AU'	,'OC'	,0	,0
UNION
SELECT 'KyotoX'	,'JP'	,'AS'	,0	,0
UNION
SELECT 'PrincetonX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'ChalmersX'	,'SE'	,'EU'	,1	,1
UNION
SELECT 'DelftWageningenX'	,'NL'	,'EU'	,1	,1
UNION
SELECT 'HarvardMedGlobalAcademy'	,'US'	,'NA'	,0	,0
UNION
SELECT 'MichiganX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'UTAustinX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'ColgateX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'MexicoX'	,'MX'	,'NA'	,0	,0
UNION
SELECT 'MandarinX'	,'CN'	,'AS'	,0	,0
UNION
SELECT 'ColumbiaX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'CooperUnion'	,'US'	,'NA'	,0	,0
UNION
SELECT 'CurtinX'	,'AU'	,'OC'	,0	,0
UNION
SELECT 'DavidsonNext'	,'US'	,'NA'	,0	,0
UNION
SELECT 'DavidsonX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'PurdueX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'MITProfX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'Delftx'	,'NL'	,'EU'	,1	,1
UNION
SELECT 'EdinburghX'	,'GB'	,'EU'	,1	,0
UNION
SELECT 'EFPLx'	,'CH'	,'EU'	,1	,1
UNION
SELECT 'DelftX'	,'NL'	,'EU'	,1	,1
UNION
SELECT 'EPFLx'	,'CH'	,'EU'	,1	,1
UNION
SELECT 'ETHx'	,'CH'	,'EU'	,1	,1
UNION
SELECT 'UTennesseeX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'GalileoX'	,'GT'	,'NA'	,0	,0
UNION
SELECT 'GeorgetownX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'NotreDameX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'GTx'	,'US'	,'NA'	,0	,0
UNION
SELECT 'HamiltonX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'HarvardX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'harvardx'	,'US'	,'NA'	,0	,0
UNION
SELECT 'HarveyMuddX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'HKPolyUx'	,'HK'	,'AS'	,0	,0
UNION
SELECT 'HKPolyUX'	,'HK'	,'AS'	,0	,0
UNION
SELECT 'HKUSTx'	,'HK'	,'AS'	,0	,0
UNION
SELECT 'HKUx'	,'HK'	,'AS'	,0	,0
UNION
SELECT 'IIMBx'	,'IN'	,'AS'	,0	,0
UNION
SELECT 'ImperialBusinessX'	,'GB'	,'EU'	,1	,0
UNION
SELECT 'IMTx'	,'FR'	,'EU'	,1	,1
UNION
SELECT 'ITMOx'	,'RU'	,'EU'	,1	,1
UNION
SELECT 'JaverianaX'	,'CO'	,'SA'	,0	,0
UNION
SELECT 'JuilliardOpenClassroom'	,'US'	,'NA'	,0	,0
UNION
SELECT 'KTHx'	,'SE'	,'EU'	,1	,1
UNION
SELECT 'KULeuvenX'	,'BE'	,'EU'	,1	,1
UNION
SELECT 'McGillX'	,'CA'	,'NA'	,0	,0
UNION
SELECT 'MEPhIx'	,'RU'	,'EU'	,1	,1
UNION
SELECT 'mitx'	,'US'	,'NA'	,0	,0
UNION
SELECT 'NewcastleX'	,'GB'	,'EU'	,1	,0
UNION
SELECT 'NYIF'	,'US'	,'NA'	,0	,0
UNION
SELECT 'OxfordX'	,'GB'	,'EU'	,1	,0
UNION
SELECT 'PerkinsX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'Harvardx'	,'US'	,'NA'	,0	,0
UNION
SELECT 'PennX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'RITx'	,'US'	,'NA'	,0	,0
UNION
SELECT 'ASUx'	,'US'	,'NA'	,0	,0
UNION
SELECT 'RWTHx'	,'DE'	,'EU'	,1	,1
UNION
SELECT 'SmithX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'SNUx'	,'KR'	,'AS'	,0	,0
UNION
SELECT 'SorbonneX'	,'FR'	,'EU'	,1	,1
UNION
SELECT 'BerkeleyX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'TrinityX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'TUMx'	,'DE'	,'EU'	,1	,1
UNION
SELECT 'UAMx'	,'ES'	,'EU'	,1	,1
UNION
SELECT 'UBCx'	,'CA'	,'NA'	,0	,0
UNION
SELECT 'UTArlingtonX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'BerkleeX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'UWashingtonX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'UC3Mx'	,'ES'	,'EU'	,1	,1
UNION
SELECT 'UCSDx'	,'US'	,'NA'	,0	,0
UNION
SELECT 'MITx'	,'US'	,'NA'	,0	,0
UNION
SELECT 'UPMCx'	,'FR'	,'EU'	,1	,1
UNION
SELECT 'RiceX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'University_of_TorontoX'	,'CA'	,'NA'	,0	,0
UNION
SELECT 'UPValenciaX'	,'ES'	,'EU'	,1	,1
UNION
SELECT 'UPValenciax'	,'ES'	,'EU'	,1	,1
UNION
SELECT 'UQx'	,'AU'	,'OC'	,0	,0
UNION
SELECT 'UrFUx'	,'RU'	,'EU'	,1	,1
UNION
SELECT 'USMx'	,'US'	,'NA'	,0	,0
UNION
SELECT 'Wharton'	,'US'	,'NA'	,0	,0
UNION
SELECT 'RICEx'	,'US'	,'NA'	,0	,0
UNION
SELECT 'UCSanDiegoX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'KyotoUx'	,'JP'	,'AS'	,0	,0
UNION
SELECT 'UTMBx'	,'US'	,'NA'	,0	,0
UNION
SELECT 'CornellX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'CaltechX'	,'US'	,'NA'	,0	,0
UNION
SELECT 'UTokyoX'	,'JP'	,'AS'	,0	,0
UNION
SELECT 'WageningenX'	,'NL'	,'EU'	,1	,1
UNION
SELECT 'WasedaX'	,'JP'	,'AS'	,0	,0
UNION
SELECT 'WitsX'	,'ZA'	,'AF'	,0	,0

);

CREATE TABLE IF NOT EXISTS ahemphill.country_region_mapping (
country_code VARCHAR(2),
continent_code VARCHAR(2)
);

INSERT INTO ahemphill.country_region_mapping
(
SELECT 'AD',	'EU'
UNION
SELECT 'AE',	'AS'
UNION
SELECT 'AF',	'AS'
UNION
SELECT 'AG',	'NA'
UNION
SELECT 'AI',	'NA'
UNION
SELECT 'AL',	'EU'
UNION
SELECT 'AM',	'AS'
UNION
SELECT 'AN',	'NA'
UNION
SELECT 'AO',	'AF'
UNION
SELECT 'AP',	'AS'
UNION
SELECT 'AQ',	'AN'
UNION
SELECT 'AR',	'SA'
UNION
SELECT 'AS',	'OC'
UNION
SELECT 'AT',	'EU'
UNION
SELECT 'AU',	'OC'
UNION
SELECT 'AW',	'NA'
UNION
SELECT 'AX',	'EU'
UNION
SELECT 'AZ',	'AS'
UNION
SELECT 'BA',	'EU'
UNION
SELECT 'BB',	'NA'
UNION
SELECT 'BD',	'AS'
UNION
SELECT 'BE',	'EU'
UNION
SELECT 'BF',	'AF'
UNION
SELECT 'BG',	'EU'
UNION
SELECT 'BH',	'AS'
UNION
SELECT 'BI',	'AF'
UNION
SELECT 'BJ',	'AF'
UNION
SELECT 'BL',	'NA'
UNION
SELECT 'BM',	'NA'
UNION
SELECT 'BN',	'AS'
UNION
SELECT 'BO',	'SA'
UNION
SELECT 'BR',	'SA'
UNION
SELECT 'BS',	'NA'
UNION
SELECT 'BT',	'AS'
UNION
SELECT 'BV',	'AN'
UNION
SELECT 'BW',	'AF'
UNION
SELECT 'BY',	'EU'
UNION
SELECT 'BZ',	'NA'
UNION
SELECT 'CA',	'NA'
UNION
SELECT 'CC',	'AS'
UNION
SELECT 'CD',	'AF'
UNION
SELECT 'CF',	'AF'
UNION
SELECT 'CG',	'AF'
UNION
SELECT 'CH',	'EU'
UNION
SELECT 'CI',	'AF'
UNION
SELECT 'CK',	'OC'
UNION
SELECT 'CL',	'SA'
UNION
SELECT 'CM',	'AF'
UNION
SELECT 'CN',	'AS'
UNION
SELECT 'CO',	'SA'
UNION
SELECT 'CR',	'NA'
UNION
SELECT 'CU',	'NA'
UNION
SELECT 'CV',	'AF'
UNION
SELECT 'CX',	'AS'
UNION
SELECT 'CY',	'AS'
UNION
SELECT 'CZ',	'EU'
UNION
SELECT 'DE',	'EU'
UNION
SELECT 'DJ',	'AF'
UNION
SELECT 'DK',	'EU'
UNION
SELECT 'DM',	'NA'
UNION
SELECT 'DO',	'NA'
UNION
SELECT 'DZ',	'AF'
UNION
SELECT 'EC',	'SA'
UNION
SELECT 'EE',	'EU'
UNION
SELECT 'EG',	'AF'
UNION
SELECT 'EH',	'AF'
UNION
SELECT 'ER',	'AF'
UNION
SELECT 'ES',	'EU'
UNION
SELECT 'ET',	'AF'
UNION
SELECT 'EU',	'EU'
UNION
SELECT 'FI',	'EU'
UNION
SELECT 'FJ',	'OC'
UNION
SELECT 'FK',	'SA'
UNION
SELECT 'FM',	'OC'
UNION
SELECT 'FO',	'EU'
UNION
SELECT 'FR',	'EU'
UNION
SELECT 'FX',	'EU'
UNION
SELECT 'GA',	'AF'
UNION
SELECT 'GB',	'EU'
UNION
SELECT 'GD',	'NA'
UNION
SELECT 'GE',	'AS'
UNION
SELECT 'GF',	'SA'
UNION
SELECT 'GG',	'EU'
UNION
SELECT 'GH',	'AF'
UNION
SELECT 'GI',	'EU'
UNION
SELECT 'GL',	'NA'
UNION
SELECT 'GM',	'AF'
UNION
SELECT 'GN',	'AF'
UNION
SELECT 'GP',	'NA'
UNION
SELECT 'GQ',	'AF'
UNION
SELECT 'GR',	'EU'
UNION
SELECT 'GS',	'AN'
UNION
SELECT 'GT',	'NA'
UNION
SELECT 'GU',	'OC'
UNION
SELECT 'GW',	'AF'
UNION
SELECT 'GY',	'SA'
UNION
SELECT 'HK',	'AS'
UNION
SELECT 'HM',	'AN'
UNION
SELECT 'HN',	'NA'
UNION
SELECT 'HR',	'EU'
UNION
SELECT 'HT',	'NA'
UNION
SELECT 'HU',	'EU'
UNION
SELECT 'ID',	'AS'
UNION
SELECT 'IE',	'EU'
UNION
SELECT 'IL',	'AS'
UNION
SELECT 'IM',	'EU'
UNION
SELECT 'IN',	'AS'
UNION
SELECT 'IO',	'AS'
UNION
SELECT 'IQ',	'AS'
UNION
SELECT 'IR',	'AS'
UNION
SELECT 'IS',	'EU'
UNION
SELECT 'IT',	'EU'
UNION
SELECT 'JE',	'EU'
UNION
SELECT 'JM',	'NA'
UNION
SELECT 'JO',	'AS'
UNION
SELECT 'JP',	'AS'
UNION
SELECT 'KE',	'AF'
UNION
SELECT 'KG',	'AS'
UNION
SELECT 'KH',	'AS'
UNION
SELECT 'KI',	'OC'
UNION
SELECT 'KM',	'AF'
UNION
SELECT 'KN',	'NA'
UNION
SELECT 'KP',	'AS'
UNION
SELECT 'KR',	'AS'
UNION
SELECT 'KW',	'AS'
UNION
SELECT 'KY',	'NA'
UNION
SELECT 'KZ',	'AS'
UNION
SELECT 'LA',	'AS'
UNION
SELECT 'LB',	'AS'
UNION
SELECT 'LC',	'NA'
UNION
SELECT 'LI',	'EU'
UNION
SELECT 'LK',	'AS'
UNION
SELECT 'LR',	'AF'
UNION
SELECT 'LS',	'AF'
UNION
SELECT 'LT',	'EU'
UNION
SELECT 'LU',	'EU'
UNION
SELECT 'LV',	'EU'
UNION
SELECT 'LY',	'AF'
UNION
SELECT 'MA',	'AF'
UNION
SELECT 'MC',	'EU'
UNION
SELECT 'MD',	'EU'
UNION
SELECT 'ME',	'EU'
UNION
SELECT 'MF',	'NA'
UNION
SELECT 'MG',	'AF'
UNION
SELECT 'MH',	'OC'
UNION
SELECT 'MK',	'EU'
UNION
SELECT 'ML',	'AF'
UNION
SELECT 'MM',	'AS'
UNION
SELECT 'MN',	'AS'
UNION
SELECT 'MO',	'AS'
UNION
SELECT 'MP',	'OC'
UNION
SELECT 'MQ',	'NA'
UNION
SELECT 'MR',	'AF'
UNION
SELECT 'MS',	'NA'
UNION
SELECT 'MT',	'EU'
UNION
SELECT 'MU',	'AF'
UNION
SELECT 'MV',	'AS'
UNION
SELECT 'MW',	'AF'
UNION
SELECT 'MX',	'NA'
UNION
SELECT 'MY',	'AS'
UNION
SELECT 'MZ',	'AF'
UNION
SELECT 'NA',	'AF'
UNION
SELECT 'NC',	'OC'
UNION
SELECT 'NE',	'AF'
UNION
SELECT 'NF',	'OC'
UNION
SELECT 'NG',	'AF'
UNION
SELECT 'NI',	'NA'
UNION
SELECT 'NL',	'EU'
UNION
SELECT 'NO',	'EU'
UNION
SELECT 'NP',	'AS'
UNION
SELECT 'NR',	'OC'
UNION
SELECT 'NU',	'OC'
UNION
SELECT 'NZ',	'OC'
UNION
SELECT 'O1',	'--'
UNION
SELECT 'OM',	'AS'
UNION
SELECT 'PA',	'NA'
UNION
SELECT 'PE',	'SA'
UNION
SELECT 'PF',	'OC'
UNION
SELECT 'PG',	'OC'
UNION
SELECT 'PH',	'AS'
UNION
SELECT 'PK',	'AS'
UNION
SELECT 'PL',	'EU'
UNION
SELECT 'PM',	'NA'
UNION
SELECT 'PN',	'OC'
UNION
SELECT 'PR',	'NA'
UNION
SELECT 'PS',	'AS'
UNION
SELECT 'PT',	'EU'
UNION
SELECT 'PW',	'OC'
UNION
SELECT 'PY',	'SA'
UNION
SELECT 'QA',	'AS'
UNION
SELECT 'RE',	'AF'
UNION
SELECT 'RO',	'EU'
UNION
SELECT 'RS',	'EU'
UNION
SELECT 'RU',	'EU'
UNION
SELECT 'RW',	'AF'
UNION
SELECT 'SA',	'AS'
UNION
SELECT 'SB',	'OC'
UNION
SELECT 'SC',	'AF'
UNION
SELECT 'SD',	'AF'
UNION
SELECT 'SE',	'EU'
UNION
SELECT 'SG',	'AS'
UNION
SELECT 'SH',	'AF'
UNION
SELECT 'SI',	'EU'
UNION
SELECT 'SJ',	'EU'
UNION
SELECT 'SK',	'EU'
UNION
SELECT 'SL',	'AF'
UNION
SELECT 'SM',	'EU'
UNION
SELECT 'SN',	'AF'
UNION
SELECT 'SO',	'AF'
UNION
SELECT 'SR',	'SA'
UNION
SELECT 'ST',	'AF'
UNION
SELECT 'SV',	'NA'
UNION
SELECT 'SY',	'AS'
UNION
SELECT 'SZ',	'AF'
UNION
SELECT 'TC',	'NA'
UNION
SELECT 'TD',	'AF'
UNION
SELECT 'TF',	'AN'
UNION
SELECT 'TG',	'AF'
UNION
SELECT 'TH',	'AS'
UNION
SELECT 'TJ',	'AS'
UNION
SELECT 'TK',	'OC'
UNION
SELECT 'TL',	'AS'
UNION
SELECT 'TM',	'AS'
UNION
SELECT 'TN',	'AF'
UNION
SELECT 'TO',	'OC'
UNION
SELECT 'TR',	'EU'
UNION
SELECT 'TT',	'NA'
UNION
SELECT 'TV',	'OC'
UNION
SELECT 'TW',	'AS'
UNION
SELECT 'TZ',	'AF'
UNION
SELECT 'UA',	'EU'
UNION
SELECT 'UG',	'AF'
UNION
SELECT 'UM',	'OC'
UNION
SELECT 'US',	'NA'
UNION
SELECT 'UY',	'SA'
UNION
SELECT 'UZ',	'AS'
UNION
SELECT 'VA',	'EU'
UNION
SELECT 'VC',	'NA'
UNION
SELECT 'VE',	'SA'
UNION
SELECT 'VG',	'NA'
UNION
SELECT 'VI',	'NA'
UNION
SELECT 'VN',	'AS'
UNION
SELECT 'VU',	'OC'
UNION
SELECT 'WF',	'OC'
UNION
SELECT 'WS',	'OC'
UNION
SELECT 'YE',	'AS'
UNION
SELECT 'YT',	'AF'
UNION
SELECT 'ZA',	'AF'
UNION
SELECT 'ZM',	'AF'
UNION
SELECT 'ZW',	'AF'
);

CREATE TABLE IF NOT EXISTS ahemphill.country_language_mapping (
country_code VARCHAR(2),
language VARCHAR(2)
);

INSERT INTO ahemphill.country_language_mapping (

SELECT 'AD', 'ca'
UNION
SELECT 'AE', 'ar'
UNION
SELECT 'AF', 'ps'
UNION
SELECT 'AG', 'en'
UNION
SELECT 'AI', 'en'
UNION
SELECT 'AL', 'sq'
UNION
SELECT 'AM', 'hy'
UNION
SELECT 'AO', 'pt'
UNION
SELECT 'AR', 'es'
UNION
SELECT 'AS', 'en'
UNION
SELECT 'AT', 'de'
UNION
SELECT 'AU', 'en'
UNION
SELECT 'AW', 'nl'
UNION
SELECT 'AX', 'sv'
UNION
SELECT 'AZ', 'az'
UNION
SELECT 'BA', 'bs'
UNION
SELECT 'BB', 'en'
UNION
SELECT 'BD', 'bn'
UNION
SELECT 'BE', 'nl'
UNION
SELECT 'BF', 'fr'
UNION
SELECT 'BG', 'bg'
UNION
SELECT 'BH', 'ar'
UNION
SELECT 'BI', 'fr'
UNION
SELECT 'BJ', 'fr'
UNION
SELECT 'BL', 'fr'
UNION
SELECT 'BM', 'en'
UNION
SELECT 'BN', 'ms'
UNION
SELECT 'BO', 'es'
UNION
SELECT 'BQ', 'nl'
UNION
SELECT 'BR', 'pt'
UNION
SELECT 'BS', 'en'
UNION
SELECT 'BT', 'dz'
UNION
SELECT 'BW', 'en'
UNION
SELECT 'BY', 'be'
UNION
SELECT 'BZ', 'en'
UNION
SELECT 'CA', 'en'
UNION
SELECT 'CC', 'en'
UNION
SELECT 'CD', 'fr'
UNION
SELECT 'CF', 'fr'
UNION
SELECT 'CG', 'fr'
UNION
SELECT 'CH', 'de'
UNION
SELECT 'CI', 'fr'
UNION
SELECT 'CK', 'en'
UNION
SELECT 'CL', 'es'
UNION
SELECT 'CM', 'en'
UNION
SELECT 'CN', 'zh'
UNION
SELECT 'CO', 'es'
UNION
SELECT 'CR', 'es'
UNION
SELECT 'CU', 'es'
UNION
SELECT 'CV', 'pt'
UNION
SELECT 'CW', 'nl'
UNION
SELECT 'CX', 'en'
UNION
SELECT 'CY', 'el'
UNION
SELECT 'CZ', 'cs'
UNION
SELECT 'DE', 'de'
UNION
SELECT 'DJ', 'fr'
UNION
SELECT 'DK', 'da'
UNION
SELECT 'DM', 'en'
UNION
SELECT 'DO', 'es'
UNION
SELECT 'DZ', 'ar'
UNION
SELECT 'EC', 'es'
UNION
SELECT 'EE', 'et'
UNION
SELECT 'EG', 'ar'
UNION
SELECT 'EH', 'es'
UNION
SELECT 'ER', 'ti'
UNION
SELECT 'ES', 'es'
UNION
SELECT 'ET', 'am'
UNION
SELECT 'FI', 'fi'
UNION
SELECT 'FJ', 'en'
UNION
SELECT 'FK', 'en'
UNION
SELECT 'FM', 'en'
UNION
SELECT 'FO', 'fo'
UNION
SELECT 'FR', 'fr'
UNION
SELECT 'GA', 'fr'
UNION
SELECT 'GB', 'en'
UNION
SELECT 'GD', 'en'
UNION
SELECT 'GE', 'ka'
UNION
SELECT 'GF', 'fr'
UNION
SELECT 'GG', 'en'
UNION
SELECT 'GH', 'en'
UNION
SELECT 'GI', 'en'
UNION
SELECT 'GL', 'kl'
UNION
SELECT 'GM', 'en'
UNION
SELECT 'GN', 'fr'
UNION
SELECT 'GP', 'fr'
UNION
SELECT 'GQ', 'es'
UNION
SELECT 'GR', 'el'
UNION
SELECT 'GS', 'en'
UNION
SELECT 'GT', 'es'
UNION
SELECT 'GU', 'en'
UNION
SELECT 'GW', 'pt'
UNION
SELECT 'GY', 'en'
UNION
SELECT 'HK', 'zh'
UNION
SELECT 'HM', 'en'
UNION
SELECT 'HN', 'es'
UNION
SELECT 'HR', 'hr'
UNION
SELECT 'HT', 'fr'
UNION
SELECT 'HU', 'hu'
UNION
SELECT 'ID', 'id'
UNION
SELECT 'IE', 'ga'
UNION
SELECT 'IL', 'he'
UNION
SELECT 'IM', 'en'
UNION
SELECT 'IN', 'hi'
UNION
SELECT 'IO', 'en'
UNION
SELECT 'IQ', 'ar'
UNION
SELECT 'IR', 'fa'
UNION
SELECT 'IS', 'is'
UNION
SELECT 'IT', 'it'
UNION
SELECT 'JE', 'en'
UNION
SELECT 'JM', 'en'
UNION
SELECT 'JO', 'ar'
UNION
SELECT 'JP', 'ja'
UNION
SELECT 'KE', 'en'
UNION
SELECT 'KG', 'ky'
UNION
SELECT 'KH', 'km'
UNION
SELECT 'KI', 'en'
UNION
SELECT 'KM', 'ar'
UNION
SELECT 'KN', 'en'
UNION
SELECT 'KP', 'ko'
UNION
SELECT 'KR', 'ko'
UNION
SELECT 'KW', 'ar'
UNION
SELECT 'KY', 'en'
UNION
SELECT 'KZ', 'kk'
UNION
SELECT 'LA', 'lo'
UNION
SELECT 'LB', 'ar'
UNION
SELECT 'LC', 'en'
UNION
SELECT 'LI', 'de'
UNION
SELECT 'LK', 'si'
UNION
SELECT 'LR', 'en'
UNION
SELECT 'LS', 'en'
UNION
SELECT 'LT', 'lt'
UNION
SELECT 'LU', 'fr'
UNION
SELECT 'LV', 'lv'
UNION
SELECT 'LY', 'ar'
UNION
SELECT 'MA', 'ar'
UNION
SELECT 'MC', 'fr'
UNION
SELECT 'MD', 'ro'
UNION
SELECT 'ME', 'sr'
UNION
SELECT 'MF', 'en'
UNION
SELECT 'MG', 'fr'
UNION
SELECT 'MH', 'en'
UNION
SELECT 'MK', 'mk'
UNION
SELECT 'ML', 'fr'
UNION
SELECT 'MM', 'my'
UNION
SELECT 'MN', 'mn'
UNION
SELECT 'MO', 'zh'
UNION
SELECT 'MP', 'en'
UNION
SELECT 'MQ', 'fr'
UNION
SELECT 'MR', 'ar'
UNION
SELECT 'MS', 'en'
UNION
SELECT 'MT', 'mt'
UNION
SELECT 'MU', 'en'
UNION
SELECT 'MV', 'dv'
UNION
SELECT 'MW', 'en'
UNION
SELECT 'MX', 'es'
UNION
SELECT 'MY', ''
UNION
SELECT 'MZ', 'pt'
UNION
SELECT 'NA', 'en'
UNION
SELECT 'NC', 'fr'
UNION
SELECT 'NE', 'fr'
UNION
SELECT 'NF', 'en'
UNION
SELECT 'NG', 'en'
UNION
SELECT 'NI', 'es'
UNION
SELECT 'NL', 'nl'
UNION
SELECT 'NO', 'no'
UNION
SELECT 'NP', 'ne'
UNION
SELECT 'NR', 'en'
UNION
SELECT 'NU', 'en'
UNION
SELECT 'NZ', 'en'
UNION
SELECT 'OM', 'ar'
UNION
SELECT 'PA', 'es'
UNION
SELECT 'PE', 'es'
UNION
SELECT 'PF', 'fr'
UNION
SELECT 'PG', 'en'
UNION
SELECT 'PH', 'en'
UNION
SELECT 'PK', 'en'
UNION
SELECT 'PL', 'pl'
UNION
SELECT 'PM', 'fr'
UNION
SELECT 'PN', 'en'
UNION
SELECT 'PR', 'es'
UNION
SELECT 'PS', 'ar'
UNION
SELECT 'PT', 'pt'
UNION
SELECT 'PW', 'en'
UNION
SELECT 'PY', 'es'
UNION
SELECT 'QA', 'ar'
UNION
SELECT 'RE', 'fr'
UNION
SELECT 'RO', 'ro'
UNION
SELECT 'RS', 'sr'
UNION
SELECT 'RU', 'ru'
UNION
SELECT 'RW', 'rw'
UNION
SELECT 'SA', 'ar'
UNION
SELECT 'SB', 'en'
UNION
SELECT 'SC', 'fr'
UNION
SELECT 'SD', 'ar'
UNION
SELECT 'SE', 'sv'
UNION
SELECT 'SG', 'en'
UNION
SELECT 'SH', 'en'
UNION
SELECT 'SI', 'sl'
UNION
SELECT 'SJ', 'no'
UNION
SELECT 'SK', 'sk'
UNION
SELECT 'SL', 'en'
UNION
SELECT 'SM', 'it'
UNION
SELECT 'SN', 'fr'
UNION
SELECT 'SO', 'so'
UNION
SELECT 'SR', 'nl'
UNION
SELECT 'SS', 'en'
UNION
SELECT 'ST', 'pt'
UNION
SELECT 'SV', 'es'
UNION
SELECT 'SX', 'nl'
UNION
SELECT 'SY', 'ar'
UNION
SELECT 'SZ', 'en'
UNION
SELECT 'TC', 'en'
UNION
SELECT 'TD', 'fr'
UNION
SELECT 'TF', 'fr'
UNION
SELECT 'TG', 'fr'
UNION
SELECT 'TH', 'th'
UNION
SELECT 'TJ', 'tg'
UNION
SELECT 'TK', 'en'
UNION
SELECT 'TL', 'pt'
UNION
SELECT 'TM', 'tk'
UNION
SELECT 'TN', 'ar'
UNION
SELECT 'TO', 'en'
UNION
SELECT 'TR', 'tr'
UNION
SELECT 'TT', 'en'
UNION
SELECT 'TV', 'en'
UNION
SELECT 'TW', 'zh'
UNION
SELECT 'TZ', 'sw'
UNION
SELECT 'UA', 'uk'
UNION
SELECT 'UG', 'en'
UNION
SELECT 'UM', 'en'
UNION
SELECT 'US', 'en'
UNION
SELECT 'UY', 'es'
UNION
SELECT 'UZ', 'uz'
UNION
SELECT 'VA', 'it'
UNION
SELECT 'VC', 'en'
UNION
SELECT 'VE', 'es'
UNION
SELECT 'VG', 'en'
UNION
SELECT 'VI', 'en'
UNION
SELECT 'VN', 'vi'
UNION
SELECT 'VU', 'bi'
UNION
SELECT 'WF', 'fr'
UNION
SELECT 'WS', 'sm'
UNION
SELECT 'XK', 'sq'
UNION
SELECT 'YE', 'ar'
UNION
SELECT 'YT', 'fr'
UNION
SELECT 'ZA', 'af'
UNION
SELECT 'ZM', 'en'
UNION
SELECT 'ZW', 'en'
);