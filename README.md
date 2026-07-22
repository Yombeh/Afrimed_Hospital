# AfriMed Hospital Management & Analytics System

A end-to-end data project covering database design, synthetic data generation, SQL analysis, and BI dashboarding for a fictional Gambian hospital — built to practice real data engineering and analytics workflows.

**Author:** Hawa Cham
**Stack:** MySQL 8.0 · Python (Faker) · Power BI Desktop

---
![AfriMed Dashboard](dashboard-complete.png)

## Project Overview

AfriMed is a simulated hospital management system built around five core entities: departments, doctors, patients, appointments, and billing. The goal was to design a properly normalized relational schema, populate it with realistic synthetic data, extract insights through SQL, and visualize those insights in an interactive Power BI dashboard — mirroring the kind of workflow a data engineer or analyst would run in a real healthcare or operations setting.

## Schema Design

The database models a simple but realistic relational chain:

```
departments (1) ──< doctors (1) ──< appointments (1) ──< billing
                                          ↑
                            patients (1) ─┘
```

**Tables:**
| Table | Key columns |
|---|---|
| `departments` | DepartmentID (PK), DepartmentName |
| `doctors` | DoctorID (PK), DoctorName, DepartmentID (FK) |
| `patients` | PatientID (PK), Gender, Age, Region |
| `appointments` | AppointmentID (PK), PatientID (FK), DoctorID (FK), AppointmentDate, Status |
| `billing` | BillID (PK), PatientID (FK), AppointmentID (FK), Amount, BillDate, PaymentStatus |

**Design notes:**
- `patients` intentionally has no name field — only demographic attributes (Gender, Age, Region). This mirrors real-world healthcare data practice, where analytical access to patient data is typically de-identified.
- `appointments` acts as a junction table resolving the many-to-many relationship between patients and doctors — a patient sees many doctors over time, and a doctor sees many patients, so the relationship can't be modeled with a direct foreign key on either side.

### A design fix worth documenting

The original schema linked `billing` directly to `patients` only. While that correctly reflects who is responsible for payment, it made department- and doctor-level revenue analysis impossible — there was no path from a bill to the department that generated it without going through an appointment.

**Fix:** added `AppointmentID` as a foreign key on `billing`, so each bill traces back to the specific visit that generated it (`billing → appointments → doctors → departments`). This unlocked revenue-by-department and revenue-by-doctor analysis, which would otherwise have been a dead end.

This is left in as part of the documentation deliberately — it reflects a normal part of real schema design: implement, test against the questions the data actually needs to answer, and refine when a gap surfaces.

## Data Pipeline

Since this is a portfolio project rather than a live system, data was synthetically generated rather than collected:

1. **Generation** — a Python script (`generate_afrimed_data.py`, using the `Faker` library) produces realistic sample data for all 5 tables, respecting foreign key integrity:
   - 6 departments, 15 doctors, 200 patients
   - 500 appointments over a 12-month window, with a realistic status distribution (Completed/Scheduled/Cancelled/No-show)
   - 270 billing records (generated only for Completed appointments, with department-specific fee ranges — e.g. Surgery costs more than General Medicine)
2. **Export** — data is written to CSV files, one per table.
3. **Load** — CSVs are loaded into MySQL via `LOAD DATA LOCAL INFILE`, in dependency order (departments → doctors → patients → appointments → billing) to satisfy foreign key constraints.

This generate → export → load flow is a simplified stand-in for a real ETL pipeline.

## SQL Analysis

Five analytical queries were written to answer specific business questions before moving into BI tooling — see `afrimed_analytical_queries.sql` for the full, commented set. They cover:

1. **Total revenue by department** — multi-table JOIN + SUM
2. **Completed appointment volume by department** — JOIN + filtered COUNT
3. **No-show count by region** — conditional aggregation using `CASE WHEN` inside `SUM()`
4. **No-show rate by region** — the above, converted to a percentage
5. **Monthly appointment trend** — date bucketing with `DATE_FORMAT()`

## Key Insights

- **Cardiology generates the most revenue overall, but Emergency handles more patient visits.** Cardiology wins on both volume (80 completed appointments) and average price per visit (~2,294 GMD), while Emergency sees more patients (87) at a lower average price (~1,254 GMD) — a high-volume, lower-margin pattern worth flagging for administrators comparing departments on a single metric.
- **General Medicine underperforms on both volume and revenue** — lowest appointment count and lowest total revenue of all departments, a pattern worth investigating operationally.
- **No-show rates vary noticeably by region** — from ~5% (Central River) to ~19% (Banjul) in this dataset. (Note: since the underlying data is randomly generated, this specific spread is statistical noise rather than a real signal — but the query and visualization approach would surface a genuine pattern the same way if run against real data.)

## Power BI Dashboard

Power BI Desktop connects live to the MySQL database (via the MySQL Connector/NET driver), importing all 5 tables with relationships mirroring the schema above. DAX measures reproduce the SQL analysis interactively:

```dax
Total Revenue = SUM(billing[Amount])
Completed Appointments = CALCULATE(COUNTROWS(appointments), appointments[Status] = "Completed")
No Shows = CALCULATE(COUNTROWS(appointments), appointments[Status] = "No-show")
Total Appointments = COUNTROWS(appointments)
No Show Rate = [No Shows] / [Total Appointments] * 100
```

The dashboard includes:
- KPI card (Total Revenue)
- Revenue by Department (bar chart)
- Completed Appointments by Department (bar chart)
- No-Show Rate by Region (bar chart)

All three charts were cross-checked against the SQL query results to confirm the data model and measures were correctly implemented before trusting them for further analysis — and they support live cross-filtering (e.g., clicking a region filters every other visual to that subset).

## Files in this project

- `generate_afrimed_data.py` — synthetic data generator
- `departments.csv`, `doctors.csv`, `patients.csv`, `appointments.csv`, `billing.csv` — generated sample data
- `afrimed_analytical_queries.sql` — the 5 analytical SQL queries
- Power BI `.pbix` file — the interactive dashboard

## What I'd do differently / next steps

- Add a monthly trend visual to the dashboard (query already written, not yet built as a chart)
- Add reference lines (e.g., average no-show rate) to make outlier regions easier to spot at a glance
- Expand the schema with a `treatments` or `diagnoses` table for richer clinical analysis
- Move from Import mode to a scheduled refresh setup if this were connected to a live, changing database
