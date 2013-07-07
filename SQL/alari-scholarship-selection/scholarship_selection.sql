-- WEIGHTED MEAN WITH THRESHOLD AND DATE RANGE
-- 
-- Author: Rafael R Rezende
-- 
-- HOW IT WORKS (from inside out):
-- It selects all information needed to perform the calculation, within an
-- INPUT range of START DATE and END DATE, ordered by id of student, then
-- decreasing mark and then ECTS.
-- For each entry, insert a cumulative ECTS according to the id of student.
-- If the previous entry had the same id of student, current entry will have
-- the previous accumulated ECTS plus the current one.
-- If the id does not match, reset the cumulative variable then proceed with
-- the same logic.
-- Also, if the cumulative variable exceeds the INPUT threshold (number of
-- ECTS required), the entry receives a null accumulated ECTS.
-- Thus, at this point it is possible to know with entries are included in
-- the cumulative ECTS.
-- After that, the command removes those entries that have exceeded the ECTS,
-- group the users and calculate the Weighted Average for the remaining
-- entries.
-- Additional fields are exposed to the output. For example, specific fields
-- present the list of Disciplines considered in the calculation, and their
-- respective marks and ETCS, comma-separated.
-- Number of disciplines included and total ECTS obtained are also presented.
-- 
-- NOTE that it is only a single command, and no temporary table is created.


SELECT
    # Resulting fields of request
    o.student AS "Student",
    o.student_academic_year AS "AcademicYear",
    COUNT(*) AS "NDisciplines",
    GROUP_CONCAT(o.course) AS "Courses",
    GROUP_CONCAT(o.mark) AS "Marks",
    GROUP_CONCAT(o.etcs) AS "ETCS",
    SUM(o.etcs) AS "SumETCS",
    SUM(o.etcs * o.mark) / SUM(o.etcs) AS "Average"
    
FROM (

    SELECT t.*,
        CASE WHEN @IDSTUDENT<>t.student
            THEN @CUMULATIVESUM:=t.etcs
            # input: required cumulative ETCS
            ELSE CASE WHEN @CUMULATIVESUM < 60 #<---- INPUT
                THEN @CUMULATIVESUM:=@CUMULATIVESUM+t.etcs
                #ELSE @cumSum:=-1 ## currently return cumSum = null
                END
        END AS "cumulative_sum",
        
        @IDSTUDENT := t.student

    FROM (
        SELECT
            marktable.STUDENTOID AS "student",
            program_table.ACADEMIC_YEAR AS "student_academic_year",
            course_table.COURSE_ AS "course",
            course_featuretable.ETCS AS "etcs",
            marktable.VALUE_2 AS "mark",
            # Concatenate ACADEMIC_YEAR and SEMESTER in one single field
            CONCAT (
                SUBSTRING_INDEX(course_table.ACADEMIC_YEAR, '-', 1), ':',
                SUBSTRING_INDEX(course_table.SEMESTER, '.', 1)
                ) AS "course_academic_year"

            FROM
                `testdb`.`marktable`,
                `testdb`.`course_featuretable`,
                `testdb`.`course_table`,
                `testdb`.`studenttable`,
                `testdb`.`program_table`

            WHERE
                # connecting marktable and studenttable
                marktable.STUDENTOID = studenttable.OID_2
                # connecting studenttable and program_table
                AND studenttable.COURSES_PROGRAM_EDITIONOID = program_table.OID_2
                # connecting marktable and course_featuretable
                AND course_featuretable.OID_2 = marktable.COURSE_FEATUREOID
                # connecting course_table and course_featuretable
                AND course_table.OID_2 = course_featuretable.COURSE_OID
                
                # restriction: only disciplines with ETCS
                AND course_featuretable.ETCS != 0
                # restriction: only numerical marks
                AND marktable.VALUE_2 NOT IN ("R", "P", "TBU", "NS")
                # restriction: only valid students
                AND studenttable.OID_2 IS NOT NULL
                # restriction: Master Project does not taken into account
                AND course_table.COURSE_ != 'Master Project'
                
                # This duplicated command below sets the NULL EXAM_DATE field to 1st of February
                # or 1st of July of the respective academic year, depending on the semester.
                
                # input: start date
                AND IFNULL(marktable.EXAM_DATE,
                    IF(course_table.SEMESTER = 1,
                        CONCAT((SUBSTRING_INDEX(course_table.ACADEMIC_YEAR, '-', 1) + 1),"-02-01"),
                        CONCAT((SUBSTRING_INDEX(course_table.ACADEMIC_YEAR, '-', 1) + 1), "-07-01")
                        )) >= '2008-01-01' #<---- INPUT
                        
                # input: end date
                AND IFNULL(marktable.EXAM_DATE,
                    IF(course_table.SEMESTER = 1,
                        CONCAT((SUBSTRING_INDEX(course_table.ACADEMIC_YEAR, '-', 1) + 1),"-02-01"),
                        CONCAT((SUBSTRING_INDEX(course_table.ACADEMIC_YEAR, '-', 1) + 1), "-07-01")
                        )) <= '2010-01-01' #<---- INPUT

            ORDER BY
                marktable.STUDENTOID,
                # ABS(column) is useful to consider the values as numbers, and not text
                ABS(marktable.VALUE_2) DESC,
                # order also by ascending ETCS, to grant selection of maximized ratio mark/etcs
                course_featuretable.ETCS

    ) t,
        (SELECT @IDSTUDENT:=0, @CUMULATIVESUM:=0) r

    # It is important to keep this ordering to get the maximized
    # average for a given interval of time
    ORDER BY t.student, ABS(t.mark) DESC

) o

WHERE
    o.cumulative_sum IS NOT NULL
    
GROUP BY
    o.student;
