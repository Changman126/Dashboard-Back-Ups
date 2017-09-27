CREATE TABLE ahemphill.bisupport_177 (user_email varchar(555));

COPY ahemphill.bisupport_177 FROM LOCAL '/Users/adleyhemphill/Downloads/bisupport_177.csv' WITH DELIMITER ',';

select user_id, b.user_email
from ahemphill.bisupport_177 a 
join production.d_user b
on a.user_email = b.user_email
and b.user_last_location_country_code = 'MX'
AND YEAR(CURRENT_DATE())-b.user_year_of_birth BETWEEN 18 AND 35