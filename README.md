# JOLTS-turnover-analytics

A SQL and Power BI portfolio project built on real BLS JOLTS turnover data, framed around a fictional staffing company's decision to expand into one vertical.

At a glance
--------------------	
Data source	BLS JOLTS (Job Openings and Labor Turnover Survey), national, seasonally adjusted
Coverage	Jan 2015 to Dec 2024, 6 industries x 5 measures, 3,600 rows, 0 duplicate keys
Verticals compared	Government, Manufacturing, Professional and business services, Leisure and hospitality
Tools	PostgreSQL (all transformation), Power BI (dashboard)
Fictional wrapper	Brightpath Workforce Solutions, a staffing firm deciding whether to expand into hospitality
What's real, what's fictional

The data is real: BLS JOLTS turnover rates, pulled and loaded without alteration. The business scenario wrapped around it is fictional, built to give the data a decision to serve. Brightpath Workforce Solutions, the company at the center of this project, does not exist. Full detail in DATA_NOTES.md.

The scenario

Brightpath is a fictional US mid-market staffing firm placing contract and temp-to-perm workers across manufacturing, professional services, and hospitality. Three stakeholders drive the analysis, each with a real business question riding on the same JOLTS pull:

Stakeholder	Role	Question
Marcus Rhee	SVP Sales & Client Delivery	Proposed a $4.2M hospitality desk expansion on the claim that hospitality has the highest churn and therefore the largest replacement market. Does that hold up?
Dana Whitfield	Chief People Officer	Owns a $1.8M/year retention bonus program, launched in 2022, up for renewal. Has quitting actually returned to normal?
Priya Nandakumar	VP Finance & FP&A	Needs the downside case for next year's plan and a read on how much risk the proposal concentrates in one vertical.

Eight questions, split across three tiers (descriptive, diagnostic, causal), answer those three questions end to end. Full question set and metric definitions: metric_dictionary.md.

Repo structure
File	What it is
Jolts.sql	All SQL views, Q1 through Q8, plus the data validation query
Q8_corrected.sql	Corrected Q8 query (first differences, not levels); see the methodology note below
DATA_NOTES.md	Data validation: nesting rules, reconciliation, exclusion windows, tie-breaks, coverage checks
metric_dictionary.md	One row per metric: formula, denominator convention, window, edge cases
FINDINGS.md	One section per question: the question, the decision it unlocks, results, findings, limitations
DASHBOARD.md	Documents the Power BI dashboard (3 pages, one per stakeholder decision)
recommendation_memo.md	One-page memo: decision, recommendation, supporting findings, what would change it
Headline findings
Hospitality does have the highest quit rate of the four verticals (4.4% vs. 2.6% for the next highest), but its replacement ratio (hires divided by separations) is within a couple of points of every other vertical. High churn there is backfill, not net growth.
Quitting has returned to, or fallen below, its pre-pandemic baseline in every vertical.
The four verticals' turnover moves largely independently month to month, so concentrating budget in one vertical gives up a real diversification benefit.

Full findings, including result tables and method notes: FINDINGS.md.

A methodology note, left in on purpose

While preparing this project, a correlation query (Q8) turned out to be computed on raw monthly levels instead of month-over-month first differences, the same trap the brief calls out explicitly for a different question (Q7). Levels share a long-run trend, so a correlation on levels mostly measures that shared trend, not whether the two series actually move together month to month. Recomputing it correctly changed the finding materially, from a strong, strengthening relationship to a weak one. Both versions are documented side by side in FINDINGS.md (Q8), including how the error was caught, rather than quietly replaced. The Power BI dashboard still shows the uncorrected version in one appendix visual; that gap is noted in DASHBOARD.md.

Reproducing this
Load the raw JOLTS pull into a jolts_turnover table (columns: series_id, industry, industry_code, measure, measure_code, year, month, date, value, seasonally_adjusted).
Run the validation query at the top of Jolts.sql first (duplicate_keys should be 0, series_count should be 30).
Run the rest of Jolts.sql top to bottom.
Connect Power BI to the same database for the dashboard.
