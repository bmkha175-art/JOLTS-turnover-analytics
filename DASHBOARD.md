# Dashboard

Built in Power BI. This file documents the dashboard as a project deliverable; it doesn't rebuild it; fill in the bracketed placeholders with your actual page details and screenshots.

**Audience:** Marcus Rhee and Dana Whitfield, monthly review. Not the board. **Refresh:** monthly, on the BLS release. The dashboard should display the reference month and the publication lag somewhere visible, so no one mistakes it for live data.

The dashboard is organized as three pages, one per stakeholder decision, rather than by question number. Each page should carry three visuals, matching the "one decision per page, three visuals each" structure.

## Page 1: Hospitality proposal (Marcus Rhee)

Answers whether the $4.2M hospitality desk expansion's core claim (highest churn means largest replacement market) holds up.

\[Screenshot placeholder\]

Suggested contents, drawing on Q1 and Q6:

- Quit rate by vertical, trailing 24-month median with IQR shown (Q1)  
- Replacement ratio by vertical, with a reference line at 1.0 (Q6)  
- \[Third visual: your choice, e.g. hires rate vs. separations rate scatter, or a KPI card stating the replacement ratio gap between hospitality and the other three verticals\]

Filters: vertical, date range.

## Page 2: Retention program renewal (Dana Whitfield)

Answers whether the $1.8M/year retention bonus program, funded on a 2022 Great Resignation premise, should be renewed, resized, or ended.

\[Screenshot placeholder\]

Suggested contents, drawing on Q2 and Q4:

- Voluntary vs. involuntary vs. residual separation share by vertical (Q2)  
- Quits gap to pre-pandemic baseline over time, with the baseline band shown, and peak and current markers (Q4)  
- \[Third visual: your choice, e.g. recovery ratio by vertical as a KPI row, or the Q8 openings-quits sensitivity result as supporting context\]

Filters: vertical, date range.

## Page 3: Downside case and planning inputs (Priya Nandakumar)

Answers how much concentration risk the hospitality expansion carries and what the downside looks like for the 2027 plan.

\[Screenshot placeholder\]

Suggested contents, drawing on Q3, Q5, and Q7:

- Pre-pandemic baseline vs. current level by vertical, across the five measures (Q3)  
- Layoff shock multiple and recovery time by vertical, as an event-study style view anchored on March 2020 (Q5)  
- \[Third visual: cross-industry correlation heatmap (Q7), if not moved to the appendix page\]

Filters: vertical, date range.

## Appendix page (hidden)

Correlation heatmaps and other diagnostic views that would clutter the three decision pages: the full Q7 correlation matrices (full period, ex-COVID, rolling 24 months), and, once corrected, the Q8 first-difference results. Not shown by default; a dashboard that shows everything gets used for nothing.

## What's deliberately excluded

Raw series browser, a full correlation matrix on the main pages, and regression diagnostics. These live in `FINDINGS.md` instead.

## Known gap to close

The Q8 openings-quits scatter charts (wherever they currently live in the report) are built on raw monthly levels, not first differences; see `FINDINGS.md` Q8 and the corrected SQL query for the fix. Once the underlying measure is corrected in Power BI, update the \[Third visual\] placeholder above and this note.  
