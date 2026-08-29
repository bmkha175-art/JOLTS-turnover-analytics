# Data validation notes

Project: JOLTS turnover analytics (Brightpath Workforce Solutions) Table: `jolts_turnover` Source: BLS JOLTS, seasonally adjusted national series, `JTS` prefix

## A note on what's real and what's fictional here

The underlying data is real: every number in this project comes from the BLS JOLTS series as published, pulled and loaded without alteration. Nothing in the table, the SQL, or the findings is simulated or invented.

The business scenario wrapped around that data is fictional, built as a framing device for this portfolio project. Brightpath Workforce Solutions, a US mid-market staffing and workforce solutions firm, does not exist. Three stakeholders drive the analysis, each fictional, each with their own question this project is scoped to answer:

- **Marcus Rhee**, SVP Sales & Client Delivery. He has proposed a $4.2M expansion of Brightpath's hospitality staffing desk (25 additional recruiters, three new branch offices), on the claim that hospitality has the highest churn of any vertical Brightpath staffs and therefore the largest replacement market. His question: does that claim hold up?  
- **Dana Whitfield**, Chief People Officer. She owns a $1.8M/year retention bonus program launched in 2022 in response to the Great Resignation, up for renewal. Her question: has quitting actually returned to normal, and is the program's founding premise still true?  
- **Priya Nandakumar**, VP Finance / FP\&A. She needs the downside case for the 2027 plan and a defensible read on how much risk the hospitality proposal concentrates in one vertical. Her question: how much would a repeat of 2020 cost, and do the verticals move together or independently?

Everything downstream, including the specific dollar figures, the retention program's 2022 launch date, and the Q3 investment committee deadline, is part of that same fictional scenario. It exists to give the real JOLTS data a decision to serve, not the other way around: none of it should be read as a claim about any real company.

## Coverage and grain

One row is one monthly observation of one turnover measure for one industry group, US national, seasonally adjusted. The table holds 3,600 rows: 6 industries times 5 measures times 120 months (January 2015 through December 2024). Every one of the 30 series has exactly 120 months of data with no gaps.

total\_rows | series\_count | industry\_count | measure\_count | first\_month | last\_month | duplicate\_keys

3600       | 30           | 6              | 5             | 2015-01-01  | 2024-12-01 | 0

Duplicate-key check (`series_id || date`) came back at 0, and coverage matched the expected 30 series with no missing months. Run this query first, before anything else, if the table is reloaded.

## Industry nesting

The six industries are not parallel. Total nonfarm contains Total private, which in turn contains Manufacturing, Professional and business services, and Leisure and hospitality. Government sits outside Total private, directly under Total nonfarm.

Total nonfarm

├── Total private

│   ├── Manufacturing

│   ├── Professional and business services

│   └── Leisure and hospitality

└── Government

Only the four leaf nodes (Government, Manufacturing, Professional and business services, Leisure and hospitality) can be compared to each other. Every query in this project filters to those four. Total nonfarm and Total private are excluded from any ranking or cross-industry average, since they mathematically contain the leaf industries and would double count.

## Reconciliation: quits and layoffs versus total separations

"Other separations" (retirements, deaths, transfers) was never pulled as its own series, so quits plus layoffs does not equal total separations. The gap is reported as a named residual rather than hidden or rescaled away. Checked at monthly grain across all four leaf industries, the residual (total separations minus quits minus layoffs) is never negative in this pull, so there's no sign of a data problem that would need flagging.

On the trailing 24-month average used in Q2, the residual share by industry:

| Industry | Voluntary (quits) | Involuntary (layoffs) | Residual (other) |
| :---- | :---- | :---- | :---- |
| Government | 57.88% | 25.21% | 16.91% |
| Manufacturing | 61.90% | 32.47% | 5.63% |
| Professional and business services | 56.05% | 38.50% | 5.45% |
| Leisure and hospitality | 73.40% | 24.42% | 2.18% |

Government's residual is far above the other three, consistent with an older, more retirement-prone workforce rather than a data issue specific to that series.

## Exclusion windows used, and why

- **Q1 (quit rate baseline):** trailing 24 months from the latest date in the table, not a single month. Single months are volatile and subject to revision.  
- **Q3/Q4 (pre-pandemic baseline):** January 2018 through December 2019, not 2015 through 2019\. The 2015 to 2016 labor market was looser than 2018 to 2019, and including it would pull the baseline down and make the present look tighter than it is.  
- **Q4 ("current"):** reported two ways, trailing 12 months and trailing 24 months, because the recovery verdict flips between them for some industries (see below).  
- **Q5 (layoff shock baseline):** calendar year 2019, the operating level immediately before the shock, rather than the 2018 to 2019 window used elsewhere. Recovery tolerance is set at 20% of each industry's own 2019 baseline rather than a flat percentage-point band, since the four industries' baselines differ by more than a factor of four (0.47 for Government versus 1.98 for Professional services) and a flat band would not measure them on equal terms.  
- **Q6 (replacement ratio):** excludes March 2020 through February 2021\. Hospitality went through two separate collapse-and-rebound cycles in that window, and a shorter cut would drop one collapse while keeping the rebound that followed it.  
- **Q7 (cross-industry correlation):** first differences are computed on the full, uninterrupted series first, and the COVID exclusion is applied afterward. Filtering the raw series before differencing would make the first difference after the gap span fifteen months instead of one. Reported three ways (full period, ex-COVID, and a rolling 24-month window) so the reader can see whether the correlation is stable or an artifact of one window choice.  
- **Q8 (openings-quits relationship):** see the methodology note below. Same differencing-before-filtering rule as Q7 applies.

## The tie in the Q4 peak, and how it was broken

Q4's peak is a 3-month centered moving average of the quit rate, and the rule for breaking a tie is: earliest date wins. This rule was not just a defensive default. Two of the four industries actually tied at their smoothed peak:

- **Government** tied at 1.13 in both February and March 2022\. February was taken as the peak.  
- **Leisure and hospitality** tied at 5.77 in both May 2021 and April 2022\. May 2021 was taken as the peak.

Manufacturing (peak 2.63, March 2022\) and Professional and business services (peak 3.63, December 2021\) had no tie.

## Revision and pull protocol

The most recent one to two months in any BLS JOLTS pull are preliminary and get revised in later releases. This pull covers through December 2024\.

**Pull date: \[fill in the date you downloaded this data\].** Record it here and re-diff against a fresh pull before final delivery, since a revision to a recent month could shift a peak, a recovery date, or a baseline mean by a small amount.

## Known limitations carried into every downstream question

1. Rates only, no employment levels, so no market can be sized in dollar or headcount terms from this pull alone.  
2. Seasonally adjusted series, so no within-year timing analysis is possible.  
3. National industry rates stand in for Brightpath's actual local markets, which is the weakest assumption in the project and the most fixable one (BLS publishes regional series that were not pulled for this version).  
4. The four BLS supersectors map onto Brightpath's three verticals as a simplification; the real client mix likely straddles those boundaries.

