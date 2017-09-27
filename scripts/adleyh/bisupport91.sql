DROP TABLE ahemphill.bisupport91_1;
CREATE TABLE ahemphill.bisupport91_1 (email VARCHAR(64));

COPY ahemphill.bisupport91_1 FROM LOCAL '/Users/adleyhemphill/Downloads/export-new_activated-all.csv'

--number on the list who enrolled pre or post 1/26/2017

SELECT 
	case when a.first_enroll_time < '2017-01-26' then 'prior to 1/26' else 'after 1/26' end as enroll_range,
	count(1) AS cnt_users
FROM
(
	SELECT
		a.user_id,
		MIN(first_enrollment_time) AS first_enroll_time
	FROM 
		d_user_course a
	JOIN 
		d_user b
	ON 
		a.user_id = b.user_id
	JOIN 
		ahemphill.bisupport91_1 c
	ON 
		b.user_email = c.email
	GROUP BY
		1
) a
GROUP BY
	1;

--number of enrollments from those on the list which came pre or post 1/26/2017

	SELECT
		case when a.first_enrollment_time < '2017-01-26' then 'prior to 1/26' else 'after 1/26' end as enroll_range,
		COUNT(1) AS cnt_enrolls
	FROM 
		d_user_course a
	JOIN 
		d_user b
	ON 
		a.user_id = b.user_id
	JOIN 
		ahemphill.bisupport91_1 c
	ON 
		b.user_email = c.email
	GROUP BY
		1;

--courses that users enrolled in, split by whether the user's first enroll came pre or post 1/26/2017

SELECT
	course_id,
	case when first_enroll_time < '2017-01-26' then 'prior to 1/26' else 'after 1/26' end as enroll_range,
	COUNT(1) AS cnt_enrolls
FROM
	d_user_course a
JOIN
	(
		SELECT
			a.user_id,
			MIN(first_enrollment_time) AS first_enroll_time
		FROM 
			d_user_course a
		JOIN 
			d_user b
		ON 
			a.user_id = b.user_id
		JOIN 
			ahemphill.bisupport91_1 c
		ON 
			b.user_email = c.email
		GROUP BY
			1
	) b
ON
	a.user_id = b.user_id
GROUP BY
	1,2;

--courses that users enrolled in, split by whether the user's first enroll came pre or post 1/26/2017


SELECT
	case when first_enrollment_time < '2017-01-26' then 'prior to 1/26' else 'after 1/26' end as enroll_range,
	course_id,
	COUNT(1) AS cnt_enrolls
FROM 
	d_user_course a
JOIN 
	d_user b
ON 
	a.user_id = b.user_id
JOIN 
	ahemphill.bisupport91_1 c
ON 
	b.user_email = c.email
GROUP BY
	1,2;


DROP TABLE ahemphill.bisupport91_2;
CREATE TABLE ahemphill.bisupport91_2 (email VARCHAR(64));

COPY ahemphill.bisupport91_2 FROM LOCAL '/Users/adleyhemphill/Downloads/export-new_learners_enrolled_in_the_architectural_imagination-all.csv';

SELECT 
	case when a.first_enroll_time < '2017-02-10' then 'prior to 2/10' else 'after 2/10' end as enroll_range,
	count(1) AS cnt_users
FROM
(
	SELECT
		a.user_id,
		MIN(first_enrollment_time) AS first_enroll_time
	FROM 
		d_user_course a
	JOIN 
		d_user b
	ON 
		a.user_id = b.user_id
	JOIN 
		ahemphill.bisupport91_2 c
	ON 
		b.user_email = c.email
	GROUP BY
		1
) a
GROUP BY
	1;

--number of enrollments from those on the list which came pre or post 1/26/2017

	SELECT
		case when a.first_enrollment_time < '2017-02-10' then 'prior to 2/10' else 'after 2/10' end as enroll_range,
		COUNT(1) AS cnt_enrolls
	FROM 
		d_user_course a
	JOIN 
		d_user b
	ON 
		a.user_id = b.user_id
	JOIN 
		ahemphill.bisupport91_2 c
	ON 
		b.user_email = c.email
	GROUP BY
		1;

--courses that users enrolled in, split by whether the user's first enroll came pre or post 1/26/2017

SELECT
	course_id,
	case when b.first_enroll_time < '2017-02-10' then 'prior to 2/10' else 'after 2/10' end as enroll_range,
	COUNT(1) AS cnt_enrolls
FROM
	d_user_course a
JOIN
	(
		SELECT
			a.user_id,
			MIN(first_enrollment_time) AS first_enroll_time
		FROM 
			d_user_course a
		JOIN 
			d_user b
		ON 
			a.user_id = b.user_id
		JOIN 
			ahemphill.bisupport91_2 c
		ON 
			b.user_email = c.email
		GROUP BY
			1
	) b
ON
	a.user_id = b.user_id
GROUP BY
	1,2;

--courses that users enrolled in, split by whether the user's first enroll came pre or post 1/26/2017


SELECT
	case when a.first_enrollment_time < '2017-02-10' then 'prior to 2/10' else 'after 2/10' end as enroll_range,
	course_id,
	COUNT(1) AS cnt_enrolls
FROM 
	d_user_course a
JOIN 
	d_user b
ON 
	a.user_id = b.user_id
JOIN 
	ahemphill.bisupport91_2 c
ON 
	b.user_email = c.email
GROUP BY
	1,2;

