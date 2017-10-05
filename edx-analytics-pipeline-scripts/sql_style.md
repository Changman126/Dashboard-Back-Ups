# edX SQL Best Practices

The goal of this guide is to improve the readability and efficiency of SQL queries.

Questions outside of the recommendations below? Reference this: http://www.sqlstyle.guide/

## Formatting

### Keywords

* Keywords should be UPPERCASE.

    ```SQL
    /* Good */
    SELECT 
        COUNT(1) AS cnt_enrolled_users
    FROM
        production.d_user_course 
    WHERE 
        user_id = 123;
    
    /* Bad */
    select 
        COUNT(1) AS cnt_enrolled_users
    from
        production.d_user_course 
    where 
        user_id = 123;
    ```
* Keywords should be on their own line.

    ```SQL
    /* Good */
    SELECT 
        COUNT(1) AS cnt_enrolled_users
    FROM
        production.d_user_course 
    WHERE 
        user_id = 123;
    
    /* Bad */
    SELECT COUNT(1) AS cnt_enrolled_users
    FROM production.d_user_course 
    WHERE user_id = 123;
    ```

### Indentation and newlines

* 80 characters max line length.

* Each clause should begin a new line.
  SELECT, JOIN, LEFT JOIN, OUTER JOIN, WHERE, UNION, etc. are keywords that begin new clauses.

    ```SQL
    /* Good */
    SELECT 
        COUNT(1) AS cnt_enrolled_users
    FROM
        production.d_user_course 
    WHERE 
        user_id = 123;
    
    /* Bad */
    SELECT COUNT(1) AS cnt_enrolled_users FROM production.d_user_course WHERE user_id = 123;
    ```    

* Query parameters immediately following a keyword should be tabbed over (4 spaces)

    ```SQL
    /* Good */
    SELECT 
        COUNT(1) AS cnt_enrolled_users
    FROM
        production.d_user_course 
    WHERE 
        user_id = 123;
    
    /* Bad */
    SELECT 
    COUNT(1) AS cnt_enrolled_users
    FROM
    production.d_user_course 
    WHERE 
    user_id = 123;
    ```

 And an example with JOINs:

    ```SQL
    /* Good */
    SELECT 
        enrolls.user_id,
        enrolls.course_id,
        course.start_time
    FROM
        production.d_user_course enrolls
    JOIN
        production.d_course course
    ON
        enrolls.course_id = course.course_id
        AND enrolls.user_id = 123;
    
    /* Bad */
    SELECT 
        enrolls.user_id,
        enrolls.course_id,
        course.start_time
    FROM
        production.d_user_course enrolls
    JOIN production.d_course course
    ON enrolls.course_id = course.course_id
    AND enrolls.user_id = 123;
    ```  

* Subqueries should always be indented from the opening parentheses.
  So, they should be indented as a unit, to identify them as subqueries.

    ```SQL
    /* Good */
    SELECT 
        COUNT(1) AS cnt_enrolled_users
    FROM
        production.d_user_course 
    WHERE 
        user_id IN 
        (
            SELECT
                user_id
            FROM
                production.d_user
            WHERE
                first_enrollment_time BETWEEN '2015-07-01' AND '2015-10-01'
        );
    
    /* Bad */
    SELECT 
        COUNT(1) AS cnt_enrolled_users
    FROM
        production.d_user_course 
    WHERE 
        user_id IN 
        (
        SELECT
            user_id
        FROM
            production.d_user
        WHERE
            first_enrollment_time BETWEEN '2015-07-01' AND '2015-10-01'
        );
    ```  

### Explicit naming

* Do not use * as a reference for all column names. Explicitly list what columns are being selected.
Exception: When making a copy of a table, * is fine.

    ```SQL
    /* Good */
    SELECT 
        user_id,
        course_id,
        first_enrollment_time
    FROM
        production.d_user_course 
    WHERE 
        user_id = 123;
    
    /* Bad */
    SELECT 
        *
    FROM
        production.d_user_course 
    WHERE 
        user_id = 123
    ```
* GROUP BY clauses should also list the explicit column name(s) instead of the index

    ```SQL
    /* Good */
    SELECT 
        user_id,
        COUNT(1) AS cnt_enrolled_users
    FROM
        production.d_user_course 
    GROUP BY
        user_id;
    
    /* Bad */
    SELECT 
        user_id,
        COUNT(1) AS cnt_enrolled_users
    FROM
        production.d_user_course 
    GROUP BY
        1;
    ```
* With the exception of complex or derived fields, where it is often cleaner to use the index.
    
    ```SQL
    /* Good */
    SELECT 
        CASE
            WHEN first_enrollment_time > '2016-01-01' THEN '>2016'
            ELSE '<2016'
        END AS pre_post_2016,
        COUNT(1) AS cnt_enrolled_users
    FROM
        production.d_user_course 
    GROUP BY
        1;
    
    /* Bad */
    SELECT 
        CASE
            WHEN first_enrollment_time > '2016-01-01' THEN '>2016'
        ELSE
            '<2016'
        END AS pre_post_2016,
        COUNT(1) AS cnt_enrolled_users
    FROM
        production.d_user_course 
    GROUP BY
        CASE
            WHEN first_enrollment_time > '2016-01-01' THEN '>2016'
        ELSE
            '<2016'
        END;
    ```

## Structure

* Column aliases should always use the keyword AS

    ```SQL
    /* Good */
    SELECT 
        COUNT(1) AS cnt_enrolled_users
    FROM
        production.d_user_course 
    WHERE 
        user_id = 123
    
    /* Bad */
    SELECT 
        COUNT(1) cnt_enrolled_users
    FROM
        production.d_user_course 
    WHERE 
        user_id = 123;
    
    ```    
* Table aliases and column aliases should be descriptive.
  Much like variable names, "a", "b", "x", etc are not generally useful in and of themselves outside of short examples.

* Tiny names for table aliases can sometimes work as abbreviations.
  As an example, if "releases" is referenced frequently, it might make sense to abbreviate it "r".  However, "rel" is almost as short, and much more descriptive.  Have a good reason for "r" instead of "rel".

  ```SQL
  /* Good */
  SELECT 
        enrolls_aggregated.user_id
  FROM
      (
          SELECT 
              user_id,
              COUNT(1) AS cnt_enrolled_courses
          FROM
              production.d_user_course 
          GROUP BY 
              user_id
      ) enrolls_aggregated
  WHERE 
      enrolls_aggregated.cnt_enrolled_courses = 1;

  /* Bad */
  SELECT 
        a.user_id
  FROM
      (
          SELECT 
              user_id,
              COUNT(1) AS cnt_enrolled_courses
          FROM
              production.d_user_course 
          GROUP BY
              user_id
      ) a
  WHERE 
      a.cnt_enrolled_courses = 1;
  ```

## Optimization

* Complete list of Vertica optimizations here: https://my.vertica.com/docs/6.1.x/HTML/index.htm#12525.htm. Calling out a few specifically:

* Choose the larger table as the left table in your JOINs (https://my.vertica.com/docs/6.1.x/HTML/index.htm#19972.htm)

    ```SQL
    /* Good */
    SELECT 
        l.id,
        s.parameter
    FROM
        large_table l
    JOIN
        small_table s
    ON
        l.id = s.id 
    
    /* Bad */
    SELECT 
        l.id,
        s.parameter
    FROM
        small_table s
    JOIN
        large_table l
    ON
        s.id = l.id 
    
    ```    
* Move as many conditions into your ON clause as possible.
The JOIN is completed prior to enforcing any conditionals in the WHERE clause, so save some resouces by restricting what you JOIN on.

  
  ```SQL
  /* Good */
  SELECT 
      enrolls.user_id,
      enrolls.course_id,
      course.start_time
  FROM
      production.d_user_course enrolls
  JOIN
      production.d_course course
  ON
      enrolls.course_id = course.course_id
      AND enrolls.user_id = 123;

  /* Bad */
  SELECT 
      enrolls.user_id,
      enrolls.course_id,
      course.start_time
  FROM
      production.d_user_course enrolls
  JOIN
      production.d_course course
  ON
      enrolls.course_id = course.course_id
  WHERE 
      enrolls.user_id = 123;
  ```

* Distinct counts can be expensive. Consider a subquery with a GROUP BY instead.

  
  ```SQL
  /* Good */
  SELECT 
      COUNT(user_id_agg.user_id)
  FROM
      (
          SELECT
              user_id
          FROM
              production.d_user_course
          GROUP BY
              user_id
      ) user_id_agg;

  /* Not as good */
  SELECT 
      COUNT(DISTINCT user_id)
  FROM
      production.d_user_course;
  ```
