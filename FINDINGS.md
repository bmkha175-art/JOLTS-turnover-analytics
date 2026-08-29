# Findings

Brightpath Workforce Solutions, JOLTS turnover analytics Data: BLS JOLTS, national, seasonally adjusted, January 2015 to December 2024 Verticals: Government, Manufacturing, Professional and business services, Leisure and hospitality

Full metric definitions: `metric_dictionary.md`. Data quality checks and exclusion windows: `DATA_NOTES.md`.

---

## Q1. What's the normal quit rate in each vertical, and how far apart are they?

Asked by Marcus Rhee. Tests whether hospitality's churn advantage is real and stable enough to plan recruiter capacity against.

| Industry | Median quits | Mean | P25 | P75 | IQR | CV |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| Leisure and hospitality | 4.40 | 4.35 | 4.00 | 4.80 | 0.80 | 0.12 |
| Professional and business services | 2.60 | 2.53 | 2.38 | 2.70 | 0.33 | 0.09 |
| Manufacturing | 1.70 | 1.79 | 1.68 | 1.90 | 0.23 | 0.14 |
| Government | 0.80 | 0.84 | 0.80 | 0.90 | 0.10 | 0.09 |

**Findings.** Hospitality's quit rate (4.4%) is more than 60% above the next highest vertical, professional services (2.6%). Its IQR (0.80) is also the widest by far, so the gap isn't just high, it's harder to plan against. By relative volatility (CV) the order flips: Manufacturing is most volatile (0.14) despite a much lower level, since its swings are a bigger share of a smaller base.

**Method.** Median and IQR over the trailing 24 months, not a single month. Total nonfarm and Total private excluded (they contain the four leaf industries).

**Limitations.** National rate, stands in for Brightpath's actual local markets.

---

## Q2. How much of the turnover in each vertical is people quitting versus being let go?

Asked by Dana Whitfield. Decides whether her retention playbook is the right instrument.

| Industry | Voluntary | Involuntary | Residual |
| :---- | :---- | :---- | :---- |
| Leisure and hospitality | 73.40% | 24.42% | 2.18% |
| Manufacturing | 61.90% | 32.47% | 5.63% |
| Government | 57.88% | 25.21% | 16.91% |
| Professional and business services | 56.05% | 38.50% | 5.45% |

**Findings.** Hospitality's turnover is overwhelmingly voluntary; professional services has the highest involuntary share of the four. Government's residual (retirements etc.) is far above the others (16.9% vs. under 6%), pointing to forecastable, age-driven turnover rather than a data issue.

**Method.** Trailing 24-month average rates. Residual checked at monthly grain; never negative in this pull.

**Limitations.** Records the rate, not the reason someone left.

---

## Q3. Where are we today relative to before the pandemic?

Asked by Priya Nandakumar. Decides which baseline goes into the 2027 plan.

Gap in points, current (trailing 24m) minus 2018-2019 baseline:

| Industry | Hires | Openings | Layoffs | Quits | Total separations |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Government | \+0.05 | \+1.14 | \-0.10 | \+0.04 | \-0.10 |
| Manufacturing | \+0.08 | \+0.64 | \+0.06 | \+0.15 | \+0.22 |
| Professional and business services | \-0.95 | \+0.38 | \-0.24 | \-0.49 | \-0.76 |
| Leisure and hospitality | \-0.58 | \+0.71 | \-0.43 | \-0.12 | \-0.57 |

**Findings.** Openings are up in every vertical, but quits didn't follow in three of four: below baseline in Professional services and Hospitality, barely above it in Government and Manufacturing. That's the weaker openings-quits link Q8 tests directly. Professional services shows the broadest pullback across every measure; Manufacturing moved the opposite way on all five.

**Method.** Baseline is Jan 2018 to Dec 2019, not 2015-2019 (looser market, would understate the gap). Reported in points, not percent change.

**Limitations.** A two-point comparison; doesn't show the path in between (Q4 does, for quits).

---

## Q4. Did the Great Resignation actually reverse, or are we still above normal?

Asked by Dana Whitfield. Feeds Decision 2: renew, resize, or end the $1.8M/year retention program.

| Industry | Baseline | Peak | Peak date | Current 24m | Current 12m | Ratio 24m | Ratio 12m |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| Professional and business services | 3.02 | 3.63 | Dec 2021 | 2.53 | 2.43 | 1.81 | 1.98 |
| Leisure and hospitality | 4.47 | 5.77 | May 2021 | 4.35 | 3.93 | 1.09 | 1.41 |
| Manufacturing | 1.64 | 2.63 | Mar 2022 | 1.79 | 1.61 | 0.85 | 1.03 |
| Government | 0.80 | 1.13 | Feb 2022 | 0.84 | 0.81 | 0.88 | 0.99 |

Ratio of 1.0 \= back at baseline; above 1.0 \= fallen below it.

**Findings.** Quitting spiked in 2021-22, then fell back everywhere. Professional services fell furthest (ratio 1.81-1.98): people there now quit less than pre-pandemic, not just back to normal. Government and Manufacturing are close to settled, though Manufacturing's verdict flips between the 24m view (0.85, still above baseline) and the 12m view (1.03, recovered).

**Method.** Peak is a 3-month centered moving average; ties broken by earliest date (Government: Feb vs. Mar 2022; Hospitality: May 2021 vs. Apr 2022).

**Limitations.** Quits only, not the other four measures.

---

## Q5. Which verticals got hit hardest when the economy broke, and which held up?

Asked by Priya Nandakumar. Feeds the downside case and concentration risk.

| Industry | 2019 baseline | Peak | Shock multiple | Peak date | Recovery time |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Leisure and hospitality | 1.78 | 31.9 | 17.97 | Mar 2020 | 5 months |
| Manufacturing | 0.85 | 6.3 | 7.41 | Apr 2020 | 4 months |
| Professional and business services | 1.98 | 6.4 | 3.24 | Apr 2020 | 2 months |
| Government | 0.47 | 1.2 | 2.57 | Apr 2020 | 8 months |

**Findings.** Hospitality's layoffs shock was by far the largest (18x its own baseline, more than double Manufacturing's), so a desk built there can lose most of its billable base within weeks. But it also recovered fastest (5 months). Every vertical was back within tolerance inside 8 months, so the realistic 2027 downside is a 1-2 quarter cash-flow gap, not lasting damage.

**Method.** Shock measured as a multiple of each industry's own 2019 baseline, since normal levels differ 4x across verticals. Recovery tolerance is the same 20%-of-baseline convention.

**Limitations.** Measures internal layoffs, not client-side impact (needs data Brightpath hasn't supplied).

---

## Q6. Is high turnover in hospitality a growth opportunity or a treadmill?

Asked by Marcus Rhee. Directly tests his $4.2M proposal's core claim.

| Industry | Hires | Separations | Avg ratio | Median ratio |
| :---- | :---- | :---- | :---- | :---- |
| Leisure and hospitality | 6.71 | 6.36 | 1.06 | 1.03 |
| Professional and business services | 5.28 | 5.13 | 1.03 | 1.04 |
| Manufacturing | 2.83 | 2.75 | 1.03 | 1.03 |
| Government | 1.64 | 1.54 | 1.07 | 1.07 |

**Findings.** Hospitality hires and separates at more than double Manufacturing's rate but ends up growing at nearly the same pace: all four replacement ratios cluster between 1.03 and 1.07. High volume reflects how often people leave, not market growth. The $4.2M case should be re-priced on gross profit per placement, not hiring volume.

**Method.** Excludes March 2020 to February 2021 (hospitality's two collapse-and-rebound cycles). Median reported since the ratio is right-skewed.

**Limitations.** Answers growth vs. treadmill, not profitability per placement (needs data Brightpath hasn't supplied).

---

## Q7. Does turnover move together across verticals, or do they move independently?

Asked by Priya Nandakumar. Decides how much concentration risk the $4.2M carries.

Pairwise correlation, month-over-month quit rate changes:

| Pair | Full period | Ex-COVID (n=107) | Rolling 24m (n=25) |
| :---- | :---- | :---- | :---- |
| Government \- Manufacturing | 0.23 | 0.25 | 0.35 |
| Hospitality \- Manufacturing | 0.21 | 0.28 | 0.42 |
| Hospitality \- Professional services | 0.05 | 0.13 | \-0.07 |
| Manufacturing \- Professional services | 0.06 | \-0.11 | \-0.21 |
| Government \- Professional services | \-0.07 | \-0.20 | \-0.14 |
| Government \- Hospitality | \-0.19 | \-0.08 | \-0.10 |

**Findings.** Correlations are consistently weak across all three windows (mostly \-0.2 to \+0.4, no pair above 0.5), and the result doesn't depend much on window choice. The four verticals move largely independently, so concentrating the $4.2M in one vertical forfeits a real diversification benefit.

**Method.** First differences are mandatory; correlation on raw levels would mostly capture shared long-run trend, not real co-movement. Differencing is done before the COVID exclusion.

**Limitations.** Six pairwise tests at once is a descriptive read, not a formal hypothesis test.

---

## Q8. Did the relationship between labor market tightness and quitting change after 2020?

Asked by Dana Whitfield. The reversal condition on Decision 2: if quitting has become more sensitive to market tightness since 2020, today's normal-looking quit rate could still mean more attrition than before.

**Methodology issue found.** `Jolts.sql` and the Power BI dashboard compute this correlation on raw levels, not first differences, the same trap the brief flags for Q7. Level-based numbers, for reference:

| Industry | Pre | Ex-COVID | Post |
| :---- | :---- | :---- | :---- |
| Manufacturing | 0.82 | 0.93 | 0.87 |
| Leisure and hospitality | 0.55 | 0.87 | 0.84 |
| Government | 0.35 | 0.66 | 0.34 |
| Professional and business services | \-0.09 | 0.51 | 0.81 |

Corrected on first differences (pre: through Feb 2020, post: from Mar 2021, shock window excluded):

| Industry | Pre (n=61) | Post (n=46) |
| :---- | :---- | :---- |
| Government | \-0.52 | \-0.39 |
| Leisure and hospitality | \-0.33 | \+0.14 |
| Manufacturing | \-0.16 | \-0.02 |
| Professional and business services | \-0.10 | \+0.01 |

**Findings.** Once the shared trend is removed, the real relationship is weak and mostly negative in both periods, for every vertical. Three of four show little change; hospitality is the only one where the sign flips (still weak either way). The reversal condition does not trigger: quitting hasn't become more sensitive to tightness since 2020\. Combined with Q4 (quitting at or below baseline nearly everywhere), the case for renewing the $1.8M/year program at its current level doesn't hold on either test.

**Method.** First differences computed before the shock window is excluded, matching Q7. The brief's full spec also wants a regression version (interaction term, Chow test, HAC-adjusted errors, \~1 day in Python); out of scope here, correlation-only is what the brief calls "sufficient to answer the business question."

**Limitations.** Modest samples (61 pre, 46 post) and serially correlated monthly data mean this should be read as descriptive, not a confirmed hypothesis test.

**Next step.** Update the Q8 views in `Jolts.sql` to first differences (`Q8_corrected.sql`); update or caveat the Power BI visual so all three deliverables agree.  
