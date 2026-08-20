SELECT *
FROM healthcare.waiting_list
LIMIT 10;

SELECT COUNT(*) AS total_rows
FROM healthcare.waiting_list;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'healthcare'
  AND table_name = 'waiting_list'
ORDER BY ordinal_position;

SELECT COUNT(*) AS total_rows
FROM healthcare.waiting_list;

SELECT *
FROM healthcare.waiting_list
LIMIT 10;

SELECT
    year,
    COUNT(*) AS rows,
    SUM(total) AS total_waiting_list
FROM healthcare.waiting_list
GROUP BY year
ORDER BY year;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'healthcare'
  AND table_name = 'waiting_list'
ORDER BY ordinal_position;

SELECT
    COUNT(*) AS total_rows,
    SUM(total) AS total_waiting_list,
    MIN(year) AS first_year,
    MAX(year) AS last_year
FROM healthcare.waiting_list;

SELECT
    patient_type,
    COUNT(*) AS records,
    SUM(total) AS total_waiting_list
FROM healthcare.waiting_list
GROUP BY patient_type
ORDER BY total_waiting_list DESC;

SELECT
    patient_type,
    SUM(total) AS total_waiting_list,
    ROUND(
        SUM(total) * 100.0 /
        SUM(SUM(total)) OVER (),
        2
    ) AS percentage
FROM healthcare.waiting_list
GROUP BY patient_type
ORDER BY total_waiting_list DESC;

SELECT
    time_bands,
    COUNT(*) AS records,
    SUM(total) AS total_waiting_list
FROM healthcare.waiting_list
GROUP BY time_bands
ORDER BY total_waiting_list DESC;

SELECT
    time_bands,
    SUM(total) AS total_waiting_list,
    ROUND(
        SUM(total) * 100.0 /
        SUM(SUM(total)) OVER (),
        2
    ) AS percentage
FROM healthcare.waiting_list
GROUP BY time_bands
ORD
ER BY total_waiting_list DESC;

SELECT
    specialty_name,
    SUM(total) AS total_waiting_list
FROM healthcare.waiting_list
GROUP BY specialty_name
ORDER BY total_waiting_list DESC
LIMIT 10;

SELECT
    specialty_name,
    SUM(total) AS total_waiting_list,
    ROUND(
        SUM(total) * 100.0 /
        SUM(SUM(total)) OVER (),
        2
    ) AS percentage
FROM healthcare.waiting_list
GROUP BY specialty_name
ORDER BY total_waiting_list DESC
LIMIT 10;

SELECT
    year,
    SUM(total) AS total_waiting_list
FROM healthcare.waiting_list
GROUP BY year
ORDER BY year;

SELECT
    year,
    patient_type,
    SUM(total) AS total_waiting_list
FROM healthcare.waiting_list
GROUP BY year, patient_type
ORDER BY year, patient_type;

SELECT
    year,
    time_bands,
    SUM(total) AS total_waiting_list
FROM healthcare.waiting_list
GROUP BY year, time_bands
ORDER BY year, total_waiting_list DESC;

SELECT
    specialty_name,
    patient_type,
    SUM(total) AS total_waiting_list
FROM healthcare.waiting_list
GROUP BY specialty_name, patient_type
ORDER BY total_waiting_list DESC;

WITH specialty_year AS (
    SELECT
        year,
        specialty_name,
        SUM(total) AS total_waiting_list
    FROM healthcare.waiting_list
    GROUP BY year, specialty_name
),
ranked AS (
    SELECT
        year,
        specialty_name,
        total_waiting_list,
        RANK() OVER (
            PARTITION BY year
            ORDER BY total_waiting_list DESC
        ) AS specialty_rank
    FROM specialty_year
)
SELECT
    year,
    specialty_name,
    total_waiting_list,
    specialty_rank
FROM ranked
WHERE specialty_rank <= 10
ORDER BY year, specialty_rank;

WITH yearly AS (
    SELECT
        year,
        SUM(total) AS total_waiting_list
    FROM healthcare.waiting_list
    GROUP BY year
)
SELECT
    year,
    total_waiting_list,
    LAG(total_waiting_list) OVER (
        ORDER BY year
    ) AS previous_year,
    ROUND(
        (
            total_waiting_list -
            LAG(total_waiting_list) OVER (ORDER BY year)
        ) * 100.0 /
        NULLIF(
            LAG(total_waiting_list) OVER (ORDER BY year),
            0
        ),
        2
    ) AS yoy_growth_percentage
FROM yearly
ORDER BY year;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE specialty_name IS NULL) AS missing_specialty,
    COUNT(*) FILTER (WHERE time_bands IS NULL) AS missing_time_band,
    COUNT(*) FILTER (WHERE total IS NULL) AS missing_total,
    COUNT(*) FILTER (WHERE year IS NULL) AS missing_year,
    COUNT(*) FILTER (WHERE patient_type IS NULL) AS missing_patient_type
FROM healthcare.waiting_list;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (
        archive_date,
        specialty_hipe,
        specialty_name,
        case_type,
        adult_child,
        age_profile,
        time_bands,
        total,
        year,
        patient_type,
        speciality
    )) AS unique_rows
FROM healthcare.waiting_list;

SELECT
    specialty_name,
    SUM(total) AS total_waiting_list
FROM healthcare.waiting_list
GROUP BY specialty_name
ORDER BY total_waiting_list DESC
LIMIT 1;

SELECT
    specialty_name,
    SUM(total) AS total_waiting_list
FROM healthcare.waiting_list
GROUP BY specialty_name
ORDER BY total_waiting_list ASC
LIMIT 10;

SELECT
    specialty_name,
    SUM(total) AS total_waiting_list,
    ROUND(
        SUM(total) * 100.0 /
        SUM(SUM(total)) OVER (),
        2
    ) AS contribution_percentage
FROM healthcare.waiting_list
GROUP BY specialty_name
ORDER BY contribution_percentage DESC;

WITH specialty_type AS (
    SELECT
        patient_type,
        specialty_name,
        SUM(total) AS total_waiting_list
    FROM healthcare.waiting_list
    GROUP BY patient_type, specialty_name
),
ranked AS (
    SELECT
        patient_type,
        specialty_name,
        total_waiting_list,
        RANK() OVER (
            PARTITION BY patient_type
            ORDER BY total_waiting_list DESC
        ) AS ranking
    FROM specialty_type
)
SELECT
    patient_type,
    specialty_name,
    total_waiting_list,
    ranking
FROM ranked
WHERE ranking <= 10
ORDER BY patient_type, ranking;

WITH yearly_band AS (
    SELECT
        year,
        time_bands,
        SUM(total) AS total_waiting_list
    FROM healthcare.waiting_list
    GROUP BY year, time_bands
),
ranked AS (
    SELECT
        year,
        time_bands,
        total_waiting_list,
        RANK() OVER (
            PARTITION BY year
            ORDER BY total_waiting_list DESC
        ) AS ranking
    FROM yearly_band
)
SELECT
    year,
    time_bands,
    total_waiting_list
FROM ranked
WHERE ranking = 1
ORDER BY year;

SELECT
    specialty_name,
    time_bands,
    SUM(total) AS total_waiting_list
FROM healthcare.waiting_list
GROUP BY specialty_name, time_bands
ORDER BY total_waiting_list DESC;

WITH specialty_band AS (
    SELECT
        specialty_name,
        time_bands,
        SUM(total) AS total_waiting_list
    FROM healthcare.waiting_list
    GROUP BY specialty_name, time_bands
),
ranked AS (
    SELECT
        specialty_name,
        time_bands,
        total_waiting_list,
        RANK() OVER (
            PARTITION BY specialty_name
            ORDER BY total_waiting_list DESC
        ) AS ranking
    FROM specialty_band
)
SELECT
    specialty_name,
    time_bands,
    total_waiting_list
FROM ranked
WHERE ranking = 1
ORDER BY total_waiting_list DESC;

WITH yearly AS (
    SELECT
        year,
        SUM(total) AS total_waiting_list
    FROM healthcare.waiting_list
    GROUP BY year
),
comparison AS (
    SELECT
        year,
        total_waiting_list,
        LAG(total_waiting_list) OVER (
            ORDER BY year
        ) AS previous_year
    FROM yearly
)
SELECT
    year,
    total_waiting_list,
    previous_year,
    total_waiting_list - previous_year AS change,
    CASE
        WHEN previous_year IS NULL THEN 'No Previous Year'
        WHEN total_waiting_list > previous_year THEN 'Increased'
        WHEN total_waiting_list < previous_year THEN 'Decreased'
        ELSE 'No Change'
    END AS trend
FROM comparison
ORDER BY year;

SELECT
    age_profile,
    SUM(total) AS total_waiting_list
FROM healthcare.waiting_list
GROUP BY age_profile
ORDER BY total_waiting_list DESC;

SELECT
    adult_child,
    SUM(total) AS total_waiting_list,
    ROUND(
        SUM(total) * 100.0 /
        SUM(SUM(total)) OVER (),
        2
    ) AS percentage
FROM healthcare.waiting_list
GROUP BY adult_child
ORDER BY total_waiting_list DESC;

SELECT
    case_type,
    SUM(total) AS total_waiting_list,
    ROUND(
        SUM(total) * 100.0 /
        SUM(SUM(total)) OVER (),
        2
    ) AS percentage
FROM healthcare.waiting_list
GROUP BY case_type
ORDER BY total_waiting_list DESC;

SELECT
    specialty_name,
    case_type,
    SUM(total) AS total_waiting_list
FROM healthcare.waiting_list
GROUP BY specialty_name, case_type
ORDER BY total_waiting_list DESC;

WITH specialty_year AS (
    SELECT
        specialty_name,
        year,
        SUM(total) AS total_waiting_list
    FROM healthcare.waiting_list
    GROUP BY specialty_name, year
),
comparison AS (
    SELECT
        specialty_name,
        year,
        total_waiting_list,
        LAG(total_waiting_list) OVER (
            PARTITION BY specialty_name
            ORDER BY year
        ) AS previous_year
    FROM specialty_year
)
SELECT
    specialty_name,
    year,
    total_waiting_list,
    previous_year,
    ROUND(
        (total_waiting_list - previous_year) * 100.0 /
        NULLIF(previous_year, 0),
        2
    ) AS yoy_growth_percentage
FROM comparison
ORDER BY specialty_name, year;

WITH specialty_year AS (
    SELECT
        specialty_name,
        year,
        SUM(total) AS total_waiting_list
    FROM healthcare.waiting_list
    GROUP BY specialty_name, year
),
growth AS (
    SELECT
        specialty_name,
        year,
        total_waiting_list,
        LAG(total_waiting_list) OVER (
            PARTITION BY specialty_name
            ORDER BY year
        ) AS previous_year
    FROM specialty_year
),
latest_year AS (
    SELECT MAX(year) AS max_year
    FROM healthcare.waiting_list
)
SELECT
    g.specialty_name,
    g.year,
    g.total_waiting_list,
    g.previous_year,
    ROUND(
        (g.total_waiting_list - g.previous_year) * 100.0 /
        NULLIF(g.previous_year, 0),
        2
    ) AS growth_percentage
FROM growth g
CROSS JOIN latest_year l
WHERE g.year = l.max_year
  AND g.previous_year IS NOT NULL
ORDER BY growth_percentage DESC
LIMIT 10;

SELECT
    patient_type,
    case_type,
    adult_child,
    COUNT(*) AS records,
    SUM(total) AS total_waiting_list
FROM healthcare.waiting_list
GROUP BY
    patient_type,
    case_type,
    adult_child
ORDER BY total_waiting_list DESC;

WITH specialty_summary AS (
    SELECT
        specialty_name,
        SUM(total) AS total_waiting_list,
        COUNT(DISTINCT year) AS years_present
    FROM healthcare.waiting_list
    GROUP BY specialty_name
),
ranked AS (
    SELECT
        specialty_name,
        total_waiting_list,
        years_present,
        RANK() OVER (
            ORDER BY total_waiting_list DESC
        ) AS overall_rank
    FROM specialty_summary
)
SELECT
    specialty_name,
    total_waiting_list,
    years_present,
    overall_rank,
    ROUND(
        total_waiting_list * 100.0 /
        SUM(total_waiting_list) OVER (),
        2
    ) AS contribution_percentage
FROM ranked
ORDER BY overall_rank;

CREATE OR REPLACE VIEW healthcare.vw_yearly_summary AS
SELECT
    year,
    SUM(total) AS total_waiting_list,
    COUNT(*) AS records
FROM healthcare.waiting_list
GROUP BY year
ORDER BY year;

SELECT *
FROM healthcare.vw_yearly_summary;

CREATE OR REPLACE VIEW healthcare.vw_patient_type_summary AS
SELECT
    patient_type,
    SUM(total) AS total_waiting_list,
    COUNT(*) AS records,
    ROUND(
        SUM(total) * 100.0 /
        SUM(SUM(total)) OVER (),
        2
    ) AS percentage
FROM healthcare.waiting_list
GROUP BY patient_type
ORDER BY total_waiting_list DESC;

SELECT *
FROM healthcare.vw_patient_type_summary;

CREATE OR REPLACE VIEW healthcare.vw_specialty_summary AS
SELECT
    specialty_name,
    SUM(total) AS total_waiting_list,
    COUNT(*) AS records,
    COUNT(DISTINCT year) AS years_present,
    ROUND(
        SUM(total) * 100.0 /
        SUM(SUM(total)) OVER (),
        2
    ) AS contribution_percentage
FROM healthcare.waiting_list
GROUP BY specialty_name
ORDER BY total_waiting_list DESC;

SELECT *
FROM healthcare.vw_specialty_summary
LIMIT 20;

CREATE OR REPLACE VIEW healthcare.vw_time_band_summary AS
SELECT
    time_bands,
    SUM(total) AS total_waiting_list,
    COUNT(*) AS records,
    ROUND(
        SUM(total) * 100.0 /
        SUM(SUM(total)) OVER (),
        2
    ) AS percentage
FROM healthcare.waiting_list
GROUP BY time_bands
ORDER BY total_waiting_list DESC;

SELECT *
FROM healthcare.vw_time_band_summary;

CREATE OR REPLACE VIEW healthcare.vw_year_patient_summary AS
SELECT
    year,
    patient_type,
    SUM(total) AS total_waiting_list,
    COUNT(*) AS records
FROM healthcare.waiting_list
GROUP BY year, patient_type
ORDER BY year, patient_type;

SELECT *
FROM healthcare.vw_year_patient_summary;

CREATE OR REPLACE VIEW healthcare.vw_year_timeband_summary AS
SELECT
    year,
    time_bands,
    SUM(total) AS total_waiting_list,
    COUNT(*) AS records
FROM healthcare.waiting_list
GROUP BY year, time_bands
ORDER BY year, total_waiting_list DESC;

CREATE OR REPLACE VIEW healthcare.vw_specialty_patient_summary AS
SELECT
    specialty_name,
    patient_type,
    SUM(total) AS total_waiting_list,
    COUNT(*) AS records
FROM healthcare.waiting_list
GROUP BY specialty_name, patient_type
ORDER BY total_waiting_list DESC;

SELECT *
FROM healthcare.vw_specialty_patient_summary
LIMIT 20;

CREATE OR REPLACE VIEW healthcare.vw_dashboard_summary AS
SELECT
    year,
    patient_type,
    specialty_name,
    case_type,
    adult_child,
    age_profile,
    time_bands,
    SUM(total) AS total_waiting_list,
    COUNT(*) AS records
FROM healthcare.waiting_list
GROUP BY
    year,
    patient_type,
    specialty_name,
    case_type,
    adult_child,
    age_profile,
    time_bands;

SELECT *
FROM healthcare.vw_dashboard_summary
LIMIT 20;	

SELECT
    table_schema,
    table_name
FROM information_schema.views
WHERE table_schema = 'healthcare'
ORDER BY table_name;

SELECT COUNT(*) AS row_count
FROM healthcare.vw_dashboard_summary;


DROP TABLE IF EXISTS healthcare.waiting_list_staging;

CREATE TABLE healthcare.waiting_list_staging (
    col1 text,
    col2 text,
    col3 text,
    col4 text,
    col5 text,
    col6 text,
    col7 text,
    col8 text,
    col9 text,
    col10 text,
    col11 text,
    col12 text
);


SELECT *
FROM healthcare.waiting_list_staging
LIMIT 10;

