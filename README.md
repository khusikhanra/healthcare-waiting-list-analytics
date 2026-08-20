# Healthcare Waiting List Analytics

**An end-to-end analytics pipeline for Ireland's National Treatment Purchase Fund (NTPF) waiting list data — from raw CSV extracts to a governed SQL warehouse to an executive Power BI dashboard.**

<p align="left">
  <img alt="rows" src="https://img.shields.io/badge/records-384%2C627-0B2545">
  <img alt="span" src="https://img.shields.io/badge/coverage-Jan_2018_–_Mar_2021-0B2545">
  <img alt="patients" src="https://img.shields.io/badge/latest_snapshot-687%2C763_patients-EE6C4D">
  <img alt="stack" src="https://img.shields.io/badge/stack-SQL_%7C_Power_BI_%7C_Python-3D5A80">
  <img alt="license" src="https://img.shields.io/badge/license-MIT-444444">
</p>

---

## Overview

Ireland's public hospital waiting lists are published monthly by the [National Treatment Purchase Fund](https://www.ntpf.ie/) as separate Inpatient/Day-Case and Outpatient extracts, with no unified schema, no historical rollup, and no analytical layer. This project turns 39 months of raw open-data files into a single, query-ready warehouse and a decision-ready BI product.

The pipeline answers four questions a hospital-operations or health-policy stakeholder actually asks:

1. **How is the national waiting list trending**, and what did COVID-19 do to it?
2. **Which specialties and case types** carry the largest share of the backlog?
3. **How long are patients actually waiting**, and is that distribution improving or worsening?
4. **Where should capacity be added first** — which specialty/time-band combinations are growing fastest?

| Layer | Artifact | Tool |
|---|---|---|
| Raw data | 8 yearly Inpatient/Outpatient extracts (2018–2021) | NTPF Open Data (`.csv`) |
| Cleaning & consolidation | Combined, deduplicated, schema-reconciled dataset | Python / pandas |
| Warehouse | `healthcare.waiting_list` table + 8 analytical views | PostgreSQL |
| Semantic model & reporting | Star-schema model, DAX measures, 1 report | Power BI (`.pbix`) |

---

## Pipeline architecture

<img width="1200" height="360" alt="architecture" src="https://github.com/user-attachments/assets/40b6ed99-bb8b-44d1-a4de-3e562f2232c6" />


The design deliberately keeps each stage swappable: the warehouse layer doesn't care whether the source file changed from an Excel workbook to an API feed, and the BI layer only ever talks to governed SQL views — never to raw tables — so a broken source extract can't silently corrupt a published dashboard.

---

## Key findings

*(Figures below are the underlying dataset's actual aggregates and a single point-in-time snapshot — see [Data quality & analytical caveats](#data-quality--analytical-caveats) for why "sum across all months" is not the same as "total patients", and why the snapshot view is used for composition breakdowns.)*

### 1. The national trend line, and the COVID-19 effect

<img width="2000" height="840" alt="monthly_trend" src="https://github.com/user-attachments/assets/a9c44b8b-6886-40d8-976b-2a3e7d685fb0" />


The list was already on a slow upward drift pre-pandemic (~565k → ~605k, Jan 2018–Feb 2020, +7%). From March 2020, elective activity was suspended and the backlog began compounding faster; by the final available snapshot (March 2021) the list stood at **687,763 patients**, up **21.6%** from the first available snapshot three years earlier. The single dip in early 2021 (a ~3% pullback from the December 2020 peak) is consistent with a brief reopening of elective capacity before renewed restrictions.

### 2. Outpatients dominate the backlog, nine-to-one

<img width="1040" height="840" alt="patient_type_split" src="https://github.com/user-attachments/assets/f5be436f-a5c8-425f-a210-22f65337cc0f" />


Of the 687,763 patients waiting in the latest snapshot, **614,280 (89.3%) are Outpatient referrals** (first consultant appointments) versus **73,483 (10.7%) Inpatient/Day-Case** (patients already diagnosed and awaiting a procedure). This is the single most important segmentation in the dataset: outpatient bottlenecks are a diagnostic-capacity problem, while inpatient bottlenecks are a theatre/bed-capacity problem — they require entirely different operational interventions, and this project's SQL schema keeps them as first-class dimensions rather than a single ambiguous "waiting list" figure.

### 3. Ten specialties carry roughly half the load

<img width="1700" height="1000" alt="top_specialties" src="https://github.com/user-attachments/assets/6190c01a-53bc-4e8a-8737-335c5f9ef898" />


**Orthopaedics** is the single largest specialty (83,256 patients, 12.1% of the snapshot total), followed by **Otolaryngology/ENT** (71,052) and **Ophthalmology** (55,288). These three alone account for roughly 30% of the entire national list. In a resourcing conversation, this chart is the one-slide argument for where an additional theatre list or outsourced treatment contract would move the national number the most.

### 4. Waiting times are bimodal — most patients wait under 6 months, but a large long-tail exists

<img width="1800" height="840" alt="time_bands" src="https://github.com/user-attachments/assets/01e27889-6763-4210-b419-0f57a5928358" />


**146,583 patients (21.3%)** have been waiting 0–3 months and **123,672 (18.0%)** 3–6 months — the "normal churn" of a functioning system. But **177,607 patients (25.8%)**, the single largest band, have been waiting **18 months or longer**. That long-tail is the group least likely to resolve without direct intervention (insourcing, outsourcing, or the NTPF's own treatment-purchase mechanism), and it is the metric this dashboard tracks month-over-month as the primary KPI.

---

## Repository structure

```
healthcare-waiting-list-analytics/
├── README.md
├── assets/                                   # Charts and diagrams used in this README
├── data/
│   ├── raw/
│   │   ├── InPatient/                        # IN_WL 2018.csv … IN_WL 2021.csv
│   │   └── Outpatient/                       # Op_WL 2018.csv … Op_WL 2021.csv
│   ├── processed/
│   │   ├── healthcare_waiting_list_final.csv # Cleaned, analysis-ready dataset (this repo's source of truth)
│   │   ├── healthcare_waiting_list_combined.csv
│   │   ├── healthcare_waiting_list_pg.csv    # Postgres-load-ready (typed, quoted)
│   │   └── data_quality_report.csv           # Column-level null/type/cardinality audit
│   └── exports/                              # Pre-aggregated summary tables (yearly, specialty, time-band)
├── notebooks/
│   └── healthcare_waiting_list_analysis.ipynb # EDA & cleaning notebook — source of truth for data/processed/*
├── sql/
│   └── healthcare_analysis.sql               # Profiling, aggregation, ranking, YoY, and view-creation scripts
└── powerbi/
    └── Healthcare_Waiting_List_Analytics.pbix
```

---

## Data model

The cleaned dataset unifies the Inpatient and Outpatient schemas into a single fact table:

| Column | Type | Description |
|---|---|---|
| `archive_date` | date | Monthly publication date of the snapshot (39 distinct months, Jan 2018–Mar 2021) |
| `year` | int | Calendar year of the snapshot |
| `patient_type` | string | `Inpatient` or `Outpatient` — the primary split |
| `specialty_hipe` | float | HIPE specialty code (numeric identifier) |
| `specialty_name` | string | Specialty label — **populated for Inpatient rows only** |
| `speciality` | string | Specialty label — **populated for Outpatient rows only** |
| `case_type` | string | `Day Case` / `Inpatient` — **Inpatient rows only** (structurally null for Outpatient) |
| `adult_child` | string | `Adult` / `Child` |
| `age_profile` | string | Age band, granularity varies by adult/child |
| `time_bands` | string | Waiting-time bucket, e.g. `0-3 Months` … `18 Months +` |
| `total` | int | Patient count for that combination of dimensions, at that snapshot date |

**`healthcare.waiting_list`** loads this table as-is; the SQL layer then builds a `Specialty = COALESCE(specialty_name, speciality)` field and eight views (`vw_yearly_summary`, `vw_patient_type_summary`, `vw_specialty_summary`, `vw_time_band_summary`, `vw_year_patient_summary`, `vw_year_timeband_summary`, `vw_specialty_patient_summary`, `vw_dashboard_summary`) so downstream tools — including the Power BI model — never write ad hoc aggregation logic against the raw table.

---

## Data quality & analytical caveats

Honesty about a dataset's limitations is part of the deliverable, not a footnote. Three things matter for anyone extending this analysis:

- **`specialty_name` is "62.99% missing" — and that's not a data quality defect.** The two patient-type extracts use different specialty columns by design: Inpatient rows populate `specialty_name`, Outpatient rows populate `speciality`. Naively filtering or aggregating on `specialty_name` alone silently drops all 242,283 Outpatient records (63% of the dataset). Every specialty-level query in this repo uses the coalesced field.
- **`Total` is a monthly point-in-time census, not an event count.** Each row represents "N patients waiting" *as observed on that archive date* — the same patient is counted again in every subsequent month they remain on the list. This means `SUM(total) GROUP BY year` (used in several profiling queries in `sql/healthcare_analysis.sql` for exploratory purposes) sums 12+ overlapping monthly snapshots and should be read as "cumulative monthly observations," not "distinct patients waiting that year." All of the headline figures in [Key findings](#key-findings) above instead use either the **latest single snapshot** (for composition/breakdowns) or the **monthly time series** (for trend) — the two representations that don't double-count.
- **2021 is a partial year (3 of 12 months).** The naive `yearly_waiting_list` export shows a −73% year-over-year "decline" from 2020 to 2021 purely because only Q1 2021 data exists in this extract — not because the list shrank. Any consumer of this repo should treat 2021 aggregates as partial-year and use the monthly series for anything requiring like-for-like comparison.
- All 384,627 rows are unique on the full dimension set (verified via `COUNT(DISTINCT (...))` in the SQL profiling script) — no duplicate-row cleanup was required.

---

## SQL layer

`sql/healthcare_analysis.sql` is organized in four passes, in the order they were actually run:

1. **Profiling** — row counts, column types, null rates, distinct-value cardinality per column.
2. **Descriptive aggregation** — totals and percentage share by patient type, time band, specialty, and every pairwise combination of the above.
3. **Analytical windows** — `RANK() OVER (PARTITION BY year ...)` for top-N specialties per year, `LAG() OVER (ORDER BY year)` for year-over-year growth, and a fastest-growing-specialty query that joins the growth CTE back to the latest available year.
4. **View creation** — materializes the eight `vw_*` views listed above so Power BI (and any future BI tool) reads from a stable, documented interface instead of the raw table.

Representative query — fastest-growing specialties in the most recent year, using a `LAG` window function partitioned by specialty:

```sql
WITH specialty_year AS (
    SELECT specialty_name, year, SUM(total) AS total_waiting_list
    FROM healthcare.waiting_list
    GROUP BY specialty_name, year
),
growth AS (
    SELECT
        specialty_name, year, total_waiting_list,
        LAG(total_waiting_list) OVER (
            PARTITION BY specialty_name ORDER BY year
        ) AS previous_year
    FROM specialty_year
)
SELECT specialty_name, year, total_waiting_list, previous_year,
       ROUND((total_waiting_list - previous_year) * 100.0 / NULLIF(previous_year, 0), 2) AS growth_percentage
FROM growth
WHERE previous_year IS NOT NULL
ORDER BY growth_percentage DESC
LIMIT 10;
```

---

## Exploratory analysis & cleaning notebook

`notebooks/healthcare_waiting_list_analysis.ipynb` is the pandas/seaborn notebook that turns the raw `InPatient/` and `Outpatient/` yearly extracts into `data/processed/healthcare_waiting_list_final.csv` — the file every other layer in this repo (SQL warehouse, Power BI model, the charts above) is built from. It runs in four stages:

1. **Discovery & ingestion** — walks `InPatient/*.csv` and `Outpatient/*.csv`, tags each file with the `Year` parsed from its filename and a `Patient_Type` derived from its folder, and concatenates all eight files into one frame.
2. **Structural cleaning** — normalizes column names (strips whitespace, non-word characters), casts text columns to a consistent string dtype, drops exact duplicate rows, and coerces `Total` to numeric.
3. **Profiling** — a full null-rate / dtype / cardinality audit per column (this is what produces `data_quality_report.csv`), an IQR-based outlier scan on numeric columns, and value-count breakdowns across every categorical field.
4. **Exploratory visuals** — bar, line, pie, and heatmap views (yearly volume, Inpatient vs Outpatient trend, time-band distribution, top/bottom specialties, Year × Time-Band and Patient-Type × Time-Band heatmaps) used to sanity-check the data before it was promoted to the warehouse and dashboard layers.

**A transparency note, in the spirit of the caveats above:** the notebook's specialty-level charts (cells grouping by `Specialty_HIPE`) aggregate by the numeric HIPE *code*, not the resolved specialty *name* — useful for a quick volume check, but it's why this README's specialty breakdown instead uses the coalesced `Specialty_Name`/`Speciality` text field for anything reader-facing. The notebook also contains its normal iterative working history (repeated re-runs of the same cell while debugging column names, a few now-superseded cells) rather than a fully linear, presentation-ready script — that's expected and fine for an exploration notebook; `sql/healthcare_analysis.sql` and the Power BI model are the productionized, reproducible layer downstream of it.

---

## Power BI dashboard

`powerbi/Healthcare_Waiting_List_Analytics.pbix` connects to the `vw_dashboard_summary` view and layers a DAX measure set (YoY growth, rolling averages, % of total) on top of a star-schema model with dedicated Date and Specialty dimension tables. It ships with a single-page executive report; recommended visuals when extending it:

- **Trend line** of the monthly total, mirroring [the chart above](#1-the-national-trend-line-and-the-covid-19-effect), with a bookmark to toggle Inpatient/Outpatient.
- **Matrix** of Specialty × Time Band, conditionally formatted, to spot which specialties have the worst long-tail concentration rather than just the largest raw total.
- **Slicer panel** on `patient_type`, `adult_child`, and `year` so a regional health-office user can filter to their own population without editing the model.

---

## Getting started

```bash
# 1. Clone
git clone https://github.com/<your-org>/healthcare-waiting-list-analytics.git
cd healthcare-waiting-list-analytics

# 2. Stand up the warehouse (PostgreSQL 13+)
createdb healthcare
psql -d healthcare -c "CREATE SCHEMA IF NOT EXISTS healthcare;"
psql -d healthcare -c "\copy healthcare.waiting_list FROM 'data/processed/healthcare_waiting_list_pg.csv' WITH (FORMAT csv, HEADER true);"

# 3. Build the analytical views
psql -d healthcare -f sql/healthcare_analysis.sql

# 4. Open the dashboard
# Power BI Desktop → File → Open → powerbi/Healthcare_Waiting_List_Analytics.pbix
# Update the data source credentials to point at your local `healthcare` database, then Refresh.
```

**Requirements:** PostgreSQL 13+, Power BI Desktop (Windows) or the Power BI service for viewing, Python 3.9+ with `pandas` if you intend to re-run the cleaning step against a newer NTPF extract.

---

## Roadmap

- [ ] Automate monthly ingestion directly from the NTPF open-data portal (replace manual CSV drops)
- [ ] Extend the time series past March 2021 as new extracts are published
- [ ] Add a regional/hospital-group dimension if NTPF begins publishing sub-national breakdowns
- [ ] Publish the Power BI report to a workspace with scheduled refresh, rather than a static `.pbix`

## Source & license

Underlying data: **National Treatment Purchase Fund (NTPF), Ireland** — published waiting list open data. Data is subject to the NTPF's own terms of use; verify current licensing at [ntpf.ie](https://www.ntpf.ie/) before redistribution.

Code and analysis in this repository are released under the [MIT License](LICENSE).

---

## Author

**Khusi Khanra**
Developer — data pipeline design, SQL analysis, and dashboard build for this project.

<p align="left">
  <a href="https://github.com/khusikhanra">
    <img alt="GitHub" src="https://img.shields.io/badge/GitHub-Khusi_Khanra-181717?logo=github&logoColor=white">
  </a>
  <a href="https://www.linkedin.com/in/khusi-khanra-a4b2b527b/">
    <img alt="LinkedIn" src="https://img.shields.io/badge/LinkedIn-Connect-0A66C2?logo=linkedin&logoColor=white">
  </a>
</p>
