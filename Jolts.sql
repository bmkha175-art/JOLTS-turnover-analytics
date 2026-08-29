SELECT
	COUNT(*) AS total_rows,
	COUNT(DISTINCT series_id) AS series_count,
	COUNT(DISTINCT industry) AS industry_count,
	COUNT(DISTINCT measure) AS measure_count,
	MIN(date) AS first_month,
	MAX(date) AS last_month,
	COUNT(*) - COUNT(DISTINCT series_id || date::text) AS duplicate_keys
FROM jolts_turnover AS j;


SELECT measure, measure_code, AVG(value) 
FROM jolts_turnover AS j
GROUP BY measure, measure_code;
--Q1. "What's the normal quit rate in each of the verticals we staff, and how far apart are they?

WITH latest AS(
	SELECT Max(date) as latest_date
	FROM jolts_turnover
),

	window_data AS (
		SELECT 
			j.industry,
			j.measure,
			DATE(j.date),
			j.value,
			ROW_NUMBER() OVER(PARTITION BY industry ORDER BY DATE(j.date))
		FROM jolts_turnover AS j
		CROSS JOIN latest AS l
		WHERE date > l.latest_date - interval '24 months'
		AND measure_code = 'QUR'
		AND j.industry IN('Government', 'Manufacturing', 
							'Professional and business services', 'Leisure and hospitality')
		ORDER BY industry
	)

SELECT
	industry,
	ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY VALUE)::numeric, 2) AS median_quits,
	ROUND(AVG(value)::numeric,2) AS mean_quits,
	ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY VALUE)::numeric, 2) AS p25,
	ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY VALUE)::numeric, 2) AS p75,
	ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY VALUE)::numeric - PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY VALUE)::numeric, 2) AS IQR,
	ROUND(STDDEV(value)::numeric/AVG(value)::numeric,2) AS coef_variation
FROM window_data
GROUP BY industry
ORDER BY median_quits DESC;

-- FINDINGS: Leisure and Hospitality has the highest quit rate of any industry, with employees typically leaving at a rate of about 4.4% per month. 
-- This rate also swings widely from period to period, meaning turnover isn't just high — it's unpredictable. As a consequence, HR teams in this sector 
-- face persistent staffing gaps and often need to invest more heavily in retention and rapid rehiring to maintain stable operations."
	 
-- Q2. "How much of the turnover in each vertical is people quitting versus being let go?	

WITH latest AS(
	SELECT Max(date) as latest_date
	FROM jolts_turnover),

	q AS 
	(SELECT industry, AVG(value) AS avg_value
	FROM jolts_turnover
	CROSS JOIN latest AS l
	WHERE industry IN('Government', 'Manufacturing', 
							'Professional and business services', 'Leisure and hospitality')
	AND date > l.latest_date - interval '24 months' 
	AND measure_code ='QUR'
	GROUP BY industry),

	t AS 
	(SELECT industry, AVG(value) AS avg_value
	FROM jolts_turnover
CROSS JOIN latest AS l
	WHERE industry IN('Government', 'Manufacturing', 
							'Professional and business services', 'Leisure and hospitality')
	AND date > l.latest_date - interval '24 months' 
	AND measure_code ='TSR'
	GROUP BY industry),

	layoffs AS 
	(SELECT industry, AVG(value) AS avg_value
	FROM jolts_turnover
	CROSS JOIN latest AS l
	WHERE industry IN('Government', 'Manufacturing', 
							'Professional and business services', 'Leisure and hospitality')
	AND date > l.latest_date - interval '24 months' 
	AND measure_code ='LDR'
	GROUP BY industry)

SELECT 
	t.industry,
	ROUND((q.avg_value / t.avg_value)::numeric * 100,2) AS Voluntary_separation_share,
	ROUND((layoffs.avg_value / t.avg_value)::numeric *100,2) AS Involuntary_separation_share,
	ROUND(((t.avg_value - q.avg_value - layoffs.avg_value)::numeric/t.avg_value)::numeric * 100, 2) AS Residual_share,
	ROUND(q.avg_value::numeric,2) AS avg_quits_rate,
	ROUND(t.avg_value::numeric,2) AS avg_total_separation_rate,
	ROUND(layoffs.avg_value::numeric, 2) AS avg_layoffs_rate
	
	FROM t 
	INNER JOIN q ON q.industry = t.industry
	INNER JOIN layoffs ON layoffs.industry = t.industry;

-- FIDNINGS: 
-- 1. Finding 1 — Same turnover, different reasons Hospitality's departures are mostly voluntary,
--  while professional services sees the highest involuntary rate in the set, 
-- tied to project and client cycles rather than employee choice.
-- 2. Government's "other separations" share is far above every other industry, pointing to an aging workforce approaching retirement rather than people quitting. 
-- As a consequence, this turnover can be planned for years in advance, letting a staffing firm schedule recruiter capacity instead of holding it in reserve. 
-- 3. Manufacturing shows a mix of voluntary and involuntary departures with no dominant driver. As a consequence, this vertical needs more data before its turnover 
-- pattern can be explained.

-- Q3. "Where are we today relative to before the pandemic?"

CREATE OR REPLACE VIEW latest AS(
	SELECT Max(date) as latest_date
	FROM jolts_turnover);

	CREATE OR REPLACE VIEW current_model_all AS(
	SELECT industry, measure, AVG(value) AS avg_value, COUNT(*) AS n_months
	FROM jolts_turnover
	CROSS JOIN latest AS l
	WHERE industry IN('Government', 'Manufacturing', 
							'Professional and business services', 'Leisure and hospitality')
	AND date > l.latest_date - interval '24 months' 
	GROUP BY industry,measure);

	CREATE OR REPLACE VIEW pre_model_all AS 
	(SELECT industry, measure, AVG(value) AS avg_value, COUNT(*) AS n_months
	FROM jolts_turnover
	WHERE industry IN('Government', 'Manufacturing', 
							'Professional and business services', 'Leisure and hospitality')
	AND date BETWEEN '2018-01-01' AND '2019-12-31' 
	GROUP BY industry, measure);
	
DROP VIEW IF EXISTS gap_in_percentage CASCADE;
CREATE OR REPLACE VIEW gap_in_percentage AS(
SELECT 
	c.industry,
	c.measure,
	ROUND(c.avg_value::numeric,2) AS current_model,
	ROUND(p.avg_value::numeric,2) AS pre_model,
	ROUND((c.avg_value - p.avg_value)::numeric,2) AS gap_in_percentage
	FROM current_model_all AS c
	INNER JOIN pre_model_all AS p
	ON c.industry = p.industry
	AND c.measure = p.measure
	ORDER BY industry);

SELECT * FROM gap_in_percentage;

DROP VIEW IF EXISTS slope_points CASCADE;
CREATE OR REPLACE VIEW slope_points AS
SELECT industry, measure, '2018-19' AS period, 1 AS period_order,
       ROUND(avg_value::numeric, 2) AS value
FROM pre_model_all
UNION ALL
SELECT industry, measure, 'Current' AS period, 2 AS period_order,
       ROUND(avg_value::numeric, 2) AS value
FROM current_model_all;

SELECT * FROM slope_points;
	
-- FINDINGS: Job openings rose in all four industries but quitting didn't follow. 
-- These normally move together — people leave when there's somewhere to go. That link looks weaker now.

-- Q4. "Did the Great Resignation actually reverse, or are we still above normal?"

	DROP VIEW IF EXISTS max_peak CASCADE;
	DROP VIEW IF EXISTS three_months_peak CASCADE;
	DROP VIEW IF EXISTS pre_model CASCADE;
	DROP VIEW IF EXISTS full_model CASCADE;
	DROP VIEW IF EXISTS current_model CASCADE;
	DROP VIEW IF EXISTS one_year_model CASCADE;
	
	CREATE OR REPLACE VIEW latest AS
	(SELECT MAX(date) AS latest_date
	FROM jolts_turnover);
	
	CREATE OR REPLACE VIEW full_model AS 
		(SELECT industry, date, AVG(value) AS avg_value
		FROM jolts_turnover
		WHERE industry IN('Government', 'Manufacturing', 
								'Professional and business services', 'Leisure and hospitality')
		AND date BETWEEN '2015-01-01' AND '2024-12-01'
		AND measure_code = 'QUR'
		GROUP BY industry, date);
	
	CREATE OR REPLACE VIEW pre_model AS 
		(SELECT industry, AVG(value) AS avg_value
		FROM jolts_turnover
		WHERE industry IN('Government', 'Manufacturing', 
								'Professional and business services', 'Leisure and hospitality')
		AND date BETWEEN '2018-01-01' AND '2019-12-31' 
		AND measure_code = 'QUR'
		GROUP BY industry);
	
	CREATE OR REPLACE VIEW current_model AS 
		(SELECT industry, AVG(value) AS avg_value, COUNT(*) AS n_months
		FROM jolts_turnover
		CROSS JOIN latest AS l
		WHERE industry IN('Government', 'Manufacturing', 
								'Professional and business services', 'Leisure and hospitality')
		AND date > l.latest_date - interval '24 months'
		AND measure_code = 'QUR'
		GROUP BY industry);
	SELECT * FROM current_model;
	
	-- Quits_gap_to_baseline
	CREATE OR REPLACE VIEW Quits_gap_to_baseline AS( 
	SELECT 	
		p.industry,
		TO_CHAR(f.date,'YYYY-MM'),
		ROUND((f.avg_value - p.avg_value)::numeric,2) AS quits_gap_to_baseline
	FROM pre_model AS p
	INNER JOIN full_model AS f
	ON f.industry = p.industry
	ORDER BY f.date);
	
	SELECT * FROM Quits_gap_to_baseline;
	
	-- Peak
	CREATE OR REPLACE VIEW three_months_peak AS(
	SELECT
	    industry,
	    date,
	    avg_value,
	    AVG(avg_value) OVER(
	        PARTITION BY industry
	        ORDER BY date
	        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
	    ) AS avg_three_months
	FROM full_model AS f);
	
	CREATE OR REPLACE VIEW max_peak AS(
	SELECT industry, peak_date, peak
	FROM (
	    SELECT
	        industry,
	        TO_CHAR(date, 'YYYY-MM') AS peak_date,
	        ROUND(avg_three_months::numeric, 2) AS peak,
	        ROW_NUMBER() OVER (
	            PARTITION BY industry
	            ORDER BY avg_three_months DESC, date ASC
	        ) AS ranked
	    FROM three_months_peak
	) t
	WHERE ranked = '1');

CREATE OR REPLACE VIEW one_year_model AS 
	(SELECT industry, AVG(value) AS avg_value, COUNT(*) AS n_months
	FROM jolts_turnover
	CROSS JOIN latest AS l
	WHERE industry IN('Government', 'Manufacturing', 
							'Professional and business services', 'Leisure and hospitality')
	AND date > l.latest_date - interval '12 months'
	AND measure_code = 'QUR'
	GROUP BY industry);


CREATE OR REPLACE VIEW v_recovery AS
SELECT
    p.industry,
    ROUND(p.avg_value::numeric, 2)                  AS baseline_2018_2019,
    m.peak,
    m.peak_date,
    ROUND(c.avg_value::numeric, 2)                  AS current_24m,
    ROUND(o.avg_value::numeric, 2)                  AS current_12m,
    ROUND((m.peak - c.avg_value)::numeric
        / NULLIF(m.peak - p.avg_value, 0)::numeric, 2)  AS recovery_ratio_24m,
    ROUND((m.peak - o.avg_value)::numeric
        / NULLIF(m.peak - p.avg_value, 0)::numeric, 2)  AS recovery_ratio_12m
FROM max_peak        AS m
INNER JOIN pre_model      AS p ON p.industry = m.industry
INNER JOIN current_model  AS c ON c.industry = m.industry
INNER JOIN one_year_model AS o ON o.industry = m.industry
ORDER BY recovery_ratio_12m DESC;
SELECT * FROM v_recovery;
-- Quitting spiked across all four industries in 2021 and 2022, then dropped back. Professional services fell the furthest: 
-- people there now change jobs less often than they did before the pandemic. Government and manufacturing have returned to 
-- roughly where they started, though whether they've fully settled depends on whether you look at the past year or the past two.

-- Q5. "Which verticals got hit hardest when the economy broke, and which held up?"
DROP VIEW IF EXISTS peak_layoffs_rate CASCADE;
CREATE OR REPLACE VIEW peak_layoffs_rate AS(
	SELECT *
	FROM(SELECT
		industry,
		date,
		value AS peak,
		ROW_NUMBER() OVER (PARTITION BY industry ORDER BY value DESC, date ASC) AS ranked
	FROM jolts_turnover
	WHERE measure_code = 'LDR'
	AND date BETWEEN '2020-03-01' AND '2020-06-30'
	AND industry IN('Government', 'Manufacturing', 
							'Professional and business services', 'Leisure and hospitality'))
WHERE ranked = '1'
);
SELECT * FROM peak_layoffs_rate;

DROP VIEW IF EXISTS layoffs_rate_during_2019 CASCADE;
CREATE OR REPLACE VIEW layoffs_rate_during_2019 AS(
	SELECT 
		industry,
		AVG(value) AS base_line
	FROM jolts_turnover
	WHERE measure_code = 'LDR'
	AND date BETWEEN '2019-01-01' AND '2019-12-31'
	AND industry IN('Government', 'Manufacturing', 
							'Professional and business services', 'Leisure and hospitality')
	GROUP BY industry
);

DROP VIEW IF EXISTS layoff_shock_multiple CASCADE;
CREATE OR REPLACE VIEW layoff_shock_multiple AS(
	SELECT 
		p.industry AS industry,
		p.date::date,
		ROUND((p.peak / l.base_line)::numeric,2) AS layoff_shock_multiple
	FROM peak_layoffs_rate AS p
	INNER JOIN layoffs_rate_during_2019 AS l
	ON p.industry = l.industry
);
SELECT * FROM layoff_shock_multiple;

CREATE OR REPLACE VIEW full_model AS 
		(SELECT industry, date, AVG(value) AS avg_value
		FROM jolts_turnover
		WHERE industry IN('Government', 'Manufacturing', 
								'Professional and business services', 'Leisure and hospitality')
		AND date BETWEEN '2015-01-01' AND '2024-12-01'
		AND measure_code = 'LDR'
		GROUP BY industry, date);

DROP VIEW IF EXISTS v_recovery_flags CASCADE;
CREATE OR REPLACE VIEW v_recovery_flags AS (
SELECT multi.industry,
		f.date,
		SUM((f.avg_value - l.base_line <= l.base_line * 0.20)::int) OVER (
        PARTITION BY multi.industry
        ORDER BY f.date ASC
        ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING 
    ) AS flag
FROM layoff_shock_multiple AS multi
LEFT JOIN peak_layoffs_rate AS p
ON p.industry = multi.industry
LEFT JOIN layoffs_rate_during_2019 AS l
ON l.industry = multi.industry
LEFT JOIN full_model AS f
ON f.industry = multi.industry
WHERE f.date::date > p.date::date);

SELECT * FROM v_recovery_flags;

CREATE OR REPLACE VIEW v_recovery_time AS (
SELECT industry, date::date AS recovery_date
FROM(
SELECT industry,
		date,
		flags,
		ROW_NUMBER() OVER(PARTITION BY industry ORDER BY date ASC) AS ranked
FROM v_recovery_flags AS flags
WHERE flag = 3)
WHERE ranked = 1);

CREATE OR REPLACE VIEW pre_model AS 
	(SELECT industry, AVG(value) AS avg_value
	FROM jolts_turnover
	WHERE industry IN('Government', 'Manufacturing', 
								'Professional and business services', 'Leisure and hospitality')
	AND date BETWEEN '2018-01-01' AND '2019-12-31' 
	AND measure_code = 'LDR'
	GROUP BY industry);

SELECT  
		v.industry,
		
		ROUND(normal_layoffs.base_line::numeric,2) AS base_line_2019,
		p.peak AS peak_in_2020,
		l.layoff_shock_multiple,
		l.date AS peak_date,
		v.recovery_date,
(EXTRACT(YEAR  FROM v.recovery_date) - EXTRACT(YEAR  FROM l.date)) * 12 + (EXTRACT(MONTH FROM v.recovery_date) - EXTRACT(MONTH FROM l.date)) AS recovery_months
FROM layoff_shock_multiple AS l
LEFT JOIN v_recovery_time AS v
ON v.industry = l.industry
LEFT JOIN peak_layoffs_rate AS p
ON p.industry = l.industry
LEFT JOIN  layoffs_rate_during_2019 AS normal_layoffs
ON normal_layoffs.industry = l.industry;

SELECT * FROM layoff_shock_multiple AS l
INNER JOIN v_recovery_time AS v 
ON l.industry = v.industry

-- 1. Hospitality carries far more downside than any other vertical. Nearly a third of everyone employed in the industry lost their job in a single month 
-- around seven times the shock manufacturing absorbed. A desk built there can lose most of its billable base within weeks, and the expansion case should 
-- price that in rather than treat it as a remote scenario.
-- 2. The damage was severe but short. Every vertical was back to normal layoff levels within a couple of quarters, and hospitality itself took only five 
-- months despite being hit hardest. The realistic downside for 2027 is a sharp cash-flow gap of one to two quarters, not a lasting loss of market.
	
-- Q6. "Is high turnover in hospitality a growth opportunity or a treadmill?"

-- MONTHLY REPLACEMENT RATIO 
DROP VIEW IF EXISTS hire_rates CASCADE;
CREATE OR REPLACE VIEW hire_rates AS 
		(SELECT industry, date, value
		FROM jolts_turnover
		WHERE industry IN('Government', 'Manufacturing', 
								'Professional and business services', 'Leisure and hospitality')
		AND measure_code = 'HIR'
		);

DROP VIEW IF EXISTS total_separations_rate CASCADE;
CREATE OR REPLACE VIEW total_separations_rate AS 
		(SELECT industry,measure_code, date, value
		FROM jolts_turnover
		WHERE industry IN('Government', 'Manufacturing', 
								'Professional and business services', 'Leisure and hospitality')
		AND measure_code = 'TSR'
		);

DROP VIEW IF EXISTS replacement_ratio_flag CASCADE;
CREATE OR REPLACE VIEW replacement_ratio_flag AS (
SELECT h.industry,
		h.date,
		h.value AS hires_rate,
		t.value AS separations_rate,
		ROUND((h.value / t.value)::numeric,2) AS replacement_ratio
FROM hire_rates AS h
INNER JOIN total_separations_rate AS t
ON t.industry = h.industry
AND t.date = h.date)
;

SELECT * FROM replacement_ratio_flag;

-- After consideration, we'll set aside March 2020 through February 2021, because hospitality went through two waves of job losses that year, 
-- one in the spring and another over the winter, and each was followed by a burst of hiring that simply brought back the roles just lost.

-- AVERAGE REPLACEMENT RATIO 

DROP VIEW IF EXISTS median_replacement_ratio CASCADE;
CREATE OR REPLACE VIEW median_replacement_ratio AS (
SELECT h.industry, t.measure_code,
		ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP ( ORDER BY h.value / t.value)::numeric, 2) 
			AS median_replacement_ratio
FROM hire_rates AS h
INNER JOIN total_separations_rate AS t
ON t.industry = h.industry
AND t.date = h.date
WHERE h.date NOT BETWEEN '2020-03-01' AND '2021-02-01'
GROUP BY h.industry, t.measure_code);

SELECT * FROM median_replacement_ratio;

DROP VIEW IF EXISTS average_hire_rates CASCADE;
CREATE OR REPLACE VIEW average_hire_rates AS 
		(SELECT industry, AVG(value) AS avg_value
		FROM jolts_turnover
		WHERE industry IN('Government', 'Manufacturing', 
								'Professional and business services', 'Leisure and hospitality')
		AND date NOT BETWEEN '2020-03-01' AND '2021-02-01'
		AND measure_code = 'HIR'
		GROUP BY industry);

DROP VIEW IF EXISTS average_total_separations_rate CASCADE;
CREATE OR REPLACE VIEW average_total_separations_rate AS 
		(SELECT industry, AVG(value) AS avg_value
		FROM jolts_turnover
		WHERE industry IN('Government', 'Manufacturing', 
								'Professional and business services', 'Leisure and hospitality')
		AND date NOT BETWEEN '2020-03-01' AND '2021-02-01'
		AND measure_code = 'TSR'
		GROUP BY industry);

SELECT avg_h.industry,
		ROUND(avg_h.avg_value::numeric,2) AS hires_rate,
		ROUND(avg_t.avg_value::numeric,2) AS separations_rate, 
		ROUND((avg_h.avg_value / avg_t.avg_value)::numeric,2) AS avg_replacement_ratio,
		m.median_replacement_ratio
FROM average_hire_rates AS avg_h
INNER JOIN average_total_separations_rate AS avg_t
ON avg_t.industry = avg_h.industry
INNER JOIN median_replacement_ratio AS m
ON m.industry = avg_h.industry; 
         
-- Hospitality hires and loses staff at more than double the rate of manufacturing every month
-- but ends up growing at almost the exact same pace.

-- What this means for the $4.2M plan: the case for prioritizing hospitality was built on its hiring volume looking impressive. 
-- That volume doesn't translate into faster growth than other verticals — it reflects how often people leave, not how much the 
--  market is expanding. Before committing the budget, it's worth pricing hospitality based on profit per hire rather than hiring volume alone.

-- Q7. "Does turnover move together across verticals, or do they move independently?"

--full year correlation

DROP VIEW IF EXISTS quits_change CASCADE;
CREATE OR REPLACE VIEW quits_change AS 
		(SELECT industry, date, value, 
		ROUND((value - LAG(value) OVER(PARTITION BY industry ORDER BY date))::numeric,2) AS quits_change
		FROM jolts_turnover
		WHERE industry IN('Government', 'Manufacturing', 
								'Professional and business services', 'Leisure and hospitality')
		AND measure_code = 'QUR'
		);

DROP VIEW IF EXISTS full_year_correlation_quits_rate CASCADE;
CREATE OR REPLACE VIEW full_year_correlation_quits_rate AS 
		(SELECT 
			a.industry AS industry_a,
			b.industry AS industry_b,
			ROUND(CORR(a.quits_change,b.quits_change)::numeric,2) AS correlation
		FROM quits_change AS a
		INNER JOIN quits_change AS b
		ON a.industry < b.industry
		AND a.date = b.date
		WHERE a.quits_change IS NOT NULL
		GROUP BY a.industry, b.industry); 

SELECT * FROM full_year_correlation_quits_rate
ORDER BY industry_a;

-- Excluding Mar 2020 – Feb 2021 correlarion

DROP VIEW IF EXISTS correlation_quits_rate_ex_covid CASCADE;
CREATE OR REPLACE VIEW correlation_quits_rate_ex_covid AS 
		(SELECT 
			a.industry AS industry_a,
			b.industry AS industry_b,
			ROUND(CORR(a.quits_change,b.quits_change)::numeric,2) AS correlation,
			COUNT(*) AS n_months
		FROM quits_change AS a
		INNER JOIN quits_change AS b
		ON a.industry < b.industry
		AND a.date = b.date
		WHERE a.quits_change IS NOT NULL
		AND a.date NOT BETWEEN '2020-03-01' AND '2021-02-01'
		GROUP BY a.industry, b.industry); 

SELECT *
FROM correlation_quits_rate_ex_covid AS c
ORDER BY industry_a;

-- 24 month correlation

DROP VIEW IF EXISTS latest CASCADE;
CREATE OR REPLACE VIEW latest AS
		(SELECT Max(date) as latest_date
	FROM jolts_turnover );

DROP VIEW IF EXISTS current_24m_correlation_quits_rate CASCADE;
CREATE OR REPLACE VIEW current_24m_correlation_quits_rate AS 
		(SELECT 
			a.industry AS industry_a,
			b.industry AS industry_b,
			ROUND(CORR(a.quits_change,b.quits_change)::numeric,2) AS correlation,
			COUNT(*) AS n_months
		FROM quits_change AS a
		CROSS JOIN latest AS l
		INNER JOIN quits_change AS b
		ON a.industry < b.industry
		AND a.date = b.date
		WHERE a.quits_change IS NOT NULL
		AND a.date >= l.latest_date::date - interval '24 months'
		GROUP BY a.industry, b.industry); 

SELECT *
FROM current_24m_correlation_quits_rate AS c
ORDER BY industry_a;

-- Q8. "Did the relationship between labour market tightness and quitting change after 2020?"
-- tightness relationship 2018-2019
DROP VIEW IF EXISTS pre_model_openings CASCADE;
CREATE OR REPLACE VIEW pre_model_openings AS 
	(SELECT industry, date, measure, value
	FROM jolts_turnover
	WHERE industry IN('Government', 'Manufacturing', 
							'Professional and business services', 'Leisure and hospitality')
	AND date BETWEEN '2015-01-01' AND '2019-12-31' 
	AND measure = 'Job openings rate'
	);
	
SELECT * FROM pre_model_openings;

DROP VIEW IF EXISTS pre_model_quits CASCADE;
CREATE OR REPLACE VIEW pre_model_quits AS 
	(SELECT industry,date , measure, value
	FROM jolts_turnover
	WHERE industry IN('Government', 'Manufacturing', 
							'Professional and business services', 'Leisure and hospitality')
	AND date BETWEEN '2015-01-01' AND '2019-12-31' 
	AND measure = 'Quits rate'
	);
	
SELECT * FROM pre_model_quits;


DROP VIEW IF EXISTS pre_tightness_relationship CASCADE;
CREATE OR REPLACE VIEW pre_tightness_relationship AS 
	(SELECT o.industry, ROUND(CORR(o.value,q.value)::numeric,2) AS pre_covid_correlation
	FROM pre_model_openings AS o
	INNER JOIN pre_model_quits AS q
	ON o.industry  = q.industry
	AND o.date = q.date
	GROUP BY o.industry);
	
SELECT * FROM pre_tightness_relationship;


-- Tightness relationship, all period except Mar 2020 - Feb 2021

DROP VIEW IF EXISTS excl_covid_openings CASCADE;
CREATE OR REPLACE VIEW excl_covid_openings AS 
	(SELECT industry, date, measure, value
	FROM jolts_turnover
	WHERE industry IN('Government', 'Manufacturing', 
							'Professional and business services', 'Leisure and hospitality')
	AND measure = 'Job openings rate'
	AND date NOT BETWEEN '2020-03-01' AND '2021-02-28'
	);
	
SELECT * FROM excl_covid_openings;

DROP VIEW IF EXISTS excl_covid_quits CASCADE;
CREATE OR REPLACE VIEW excl_covid_quits AS 
	(SELECT industry, date, measure, value
	FROM jolts_turnover
	WHERE industry IN('Government', 'Manufacturing', 
							'Professional and business services', 'Leisure and hospitality')
	AND measure = 'Quits rate'
	AND date NOT BETWEEN '2020-03-01' AND '2021-02-28'
	);
	
SELECT * FROM excl_covid_quits;

DROP VIEW IF EXISTS excl_covid_tightness_relationship CASCADE;
CREATE OR REPLACE VIEW excl_covid_tightness_relationship AS 
	(SELECT o.industry, ROUND(CORR(o.value, q.value)::numeric, 2) AS correlation_exlu_covid
	FROM excl_covid_openings AS o
	INNER JOIN excl_covid_quits AS q
	ON o.industry = q.industry
	AND o.date = q.date
	GROUP BY o.industry);
	
SELECT * FROM excl_covid_tightness_relationship;

-- tightness relationship, Mar-2020 tới nay
DROP VIEW IF EXISTS post2020_model_openings CASCADE;
CREATE OR REPLACE VIEW post2020_model_openings AS 
	(SELECT industry, date, measure, value
	FROM jolts_turnover
	WHERE industry IN('Government', 'Manufacturing', 
							'Professional and business services', 'Leisure and hospitality')
	AND measure = 'Job openings rate'
	AND date >= '2020-03-01'
	AND date <= CURRENT_DATE
	);
	
SELECT * FROM post2020_model_openings;

DROP VIEW IF EXISTS post2020_model_quits CASCADE;
CREATE OR REPLACE VIEW post2020_model_quits AS 
	(SELECT industry, date, measure, value
	FROM jolts_turnover
	WHERE industry IN('Government', 'Manufacturing', 
							'Professional and business services', 'Leisure and hospitality')
	AND measure = 'Quits rate'
	AND date >= '2020-03-01'
	AND date <= CURRENT_DATE
	);
	
SELECT * FROM post2020_model_quits;

DROP VIEW IF EXISTS post2020_tightness_relationship CASCADE;
CREATE OR REPLACE VIEW post2020_tightness_relationship AS 
	(SELECT o.industry, ROUND(CORR(o.value, q.value)::numeric, 2) AS post_covid_correlation
	FROM post2020_model_openings AS o
	INNER JOIN post2020_model_quits AS q
	ON o.industry = q.industry
	AND o.date = q.date
	GROUP BY o.industry);
	
SELECT * FROM post2020_tightness_relationship;

--Tightness summary

DROP VIEW IF EXISTS tightness_summary CASCADE;
CREATE OR REPLACE VIEW tightness_summary AS
	(SELECT p.industry, 
		p.pre_covid_correlation,
		e.correlation_exlu_covid,
		po.post_covid_correlation
	FROM pre_tightness_relationship AS p
	INNER JOIN excl_covid_tightness_relationship AS e ON p.industry = e.industry
	INNER JOIN post2020_tightness_relationship AS po ON p.industry = po.industry
	ORDER BY p.industry);

SELECT * FROM tightness_summary;