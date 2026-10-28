Data Engineer – Take-Home Exercise

Overview

Fundment is a fast-growing wealth infrastructure company, building on our cutting-edge digital investment system to transform the £3 trillion UK wealth management market. We are passionate about revolutionising the investment experience for financial advisers and their clients by combining our innovative proprietary technology with exceptional customer service.

A key part of that is a data architecture where data correctness, trust, and transparency are foundational. Our data platform will support product decisions, financial reporting, and regulatory-adjacent workflows.

This exercise is designed to reflect the kind of work you would do as part of our data engineering team, building our data platform for various analytics and AI use-cases.

We are not looking for a perfect or exhaustive solution. We are looking for sound engineering judgment, clear data modelling, and thoughtful communication.

⸻
Time Expectation
Please expect this exercise to take around 4-6 hours. Make sure to scope the work and focus on what you think is most important.

We explicitly value:
	•	Clear assumptions
	•	Good tradeoffs
	•	Simplicity over over-engineering

⸻
The Problem
You are given a dataset representing platform fees paid by clients over time.

Your task is to design and implement a simple, production-minded batch analytics pipeline on Google Cloud Platform (GCP) that:
	•	Ingests the raw data
	•	Stores it safely
	•	Transforms it into analytics-ready models
	•	Answers a small set of business questions using SQL

Assume this data will be used for:
	•	Business reporting
	•	Adviser performance analysis
	•	Financial oversight and trust-sensitive use cases

⸻
Dataset
The dataset is provided in the data/ directory as a CSV file.

Schema
client_id    STRING
client_nino	 STRING
adviser_id   STRING
fee_date     DATE
fee_amount   NUMERIC

Notes:
	•	A client may pay multiple fees per month
	•	A client may change advisers over time
	•	Data may contain duplicates or corrections
	•	Not all clients pay fees every month

You may make reasonable assumptions as needed, but please document them.

⸻
Technical Requirements
Infrastructure (Terraform + GCP)
Use Terraform to provision the minimum required infrastructure on GCP, that allows you to store and analyse data.

Guidelines:
	•	Keep Terraform minimal and readable
	•	Use variables where appropriate
	•	Assume this could later be extended to CI/CD
	•	You may use your own GCP account; please keep costs minimal

⸻
Data Pipeline
Design a simple batch pipeline that:
Ingests the raw CSV to GCP platform
Transforms it into one or more analytics-ready tables using SQL

Guidelines:
	•	Pipelines should be idempotent (safe to rerun)
	•	Clearly separate raw data from transformed data
	•	Prefer SQL-based transformations
	•	Focus on correctness and clarity

The analytics-ready tables should be able to answer the following questions:
	•	What are the lifetime value (LTV), i.e. the accumulated fees, at 1, 3 and 6 months for each client, measured from the client’s first fee date?
	•	What is the 6-month LTV for the January and February cohorts of the current year? (A cohort is defined by the month in which a client first paid a fee)
	•	Which adviser has the highest total client LTV over the first 6 months of each client’s lifetime?

Please document how you attribute client LTV to advisers.

⸻
Deliverables
Please submit a GitHub repository (or zip file) containing:
README.md                # This file, updated with your notes
terraform/               # Terraform configuration
sql/                     # SQL models and/or queries
scripts/ (optional)      # Any helper scripts you use

⸻
README Expectations
Please update this README to include:
	•	A short description of your architecture
	•	Your data modelling approach
	•	Key assumptions and tradeoffs
	•	How you would evolve this into a production-grade, trustworthy fintech data platform
	•	Auditing and reconciliation
	•	Backfills and reprocessing
	•	Schema changes
	•	Data quality checks

Diagrams are welcome but not required.

⸻
What We’re Evaluating
We will evaluate submissions based on:
	•	Engineering judgment
	•	Data modelling fundamentals
	•	SQL correctness and readability
	•	Terraform clarity
	•	Trust, safety and data-quality awareness
	•	Communication and documentation

We care more about how you think than how much you build.

⸻
What’s Out of Scope
You do not need to:
	•	Build dashboards or visualisations
	•	Implement streaming ingestion
	•	Set up CI/CD pipelines
	•	Optimise for very large scale

⸻
Follow-Up Discussion
In the follow-up interview, we will:
	•	Walk through your solution together
	•	Discuss tradeoffs and assumptions
	•	Explore how you would build and scale the data architecture at Fundment
	•	Talk about operating data systems in a trust-sensitive fintech environment

⸻
Final Notes
This exercise is intended to be collaborative, not adversarial.

If something is ambiguous, make a reasonable assumption and document it.
If you choose not to implement something, explain why.

Thank you for your time and effort. We appreciate it!

=========================================

# Solution

### Overview

This repository contains a basic analytics pipeline allowing users to analyse Fundment Client Platform fees.

The solution will:

1) Store the raw CSV in Google Cloud Storage
2) Loads the raw data into BigQuery
3) Creates a standardised fee table
4) Calculates client level lifetime value (LTV)
5) Produces both cohort and adviser-level analysis

The solution utilises Terraform for infrastructure and BigQuery SQL for transformations and creation of tables.

### Architecture
```text
        CSV
         ↓
Google Cloud Storage
         ↓
 BigQuery: raw_fees
         ↓
BigQuery: clean_fees
         ↓
BigQuery: client_ltv
          cohort_ltv
          adviser_ltv
```

### Data Model
The source contains 51,697 rows, 5,200 clients and 5 advisers. Exact duplicate handling removes 119 excess rows. Two negative fee records are retained as potential corrections. Below lists the data model created to answer analyst questions.

#### Raw Layer: 

- `fees.raw_fees`
	- Contains the source data as loaded into BigQuery and is not modified by transformation logic.

#### Standardised Layer: 

- `fees.clean_fees`
	- Removes exact duplicate rows
	- Applies the expected data types
	- Provides the input for tables in the Analytics Layer

#### Analytics Layer:

- `fees.client_ltv`
	- One row per client containing
		- Date of first fee
		- One month LTV
		- Three month LTV (Null if not applicable)
		- Six month LTV (Null if not applicable)

- `fees.cohort_ltv`
	- One row per cohort containing
		- Cohort month (2025-01-01 etc)
		- Number of clients in cohort
		- Total six month LTV
		- Average six month LTV

- `fees.adviser_ltv`
	- One row per adviser containing
		- Number of clients
		- Total six month client LTV
		- Adviser ranking

### KPIs

#### Lifetime Value (LTV)

A client's first fee month is treated as month 1 meaning `month 3` is 2 calendar months after the first fee month.

For example, the cohort of January 2025 has a six month window from January to June inclusive. Fees are summed across all fee records within the relevant window, including corrections. 

Clients will only be included in a six month LTV calculation where the dataset contains a complete six month observation window.

#### Adviser Attribution

Adviser LTV is attributed at fee level using the adviser recorded on each fee.

This means:
- A client can contribute fees to more than one adviser if their adviser changed.
- Each fee is counted once.
- Adviser totals reconcile to the fee-level client LTV totals.
- Adviser ranking is based on total fees attributed during each client’s first six months.
This approach reflects adviser assignment at the time the fee was charged and avoids assigning a client’s entire value to only one adviser.

### Assumptions & tradeoffs

- Exact duplicates are removed from the standardised layer
- `client_nino` is treated as personally identifiable information (PII) and should not be used as part of analysis. In a production environment, this information would be redacted or access limited.
- Separate `client` and `adviser` dimension tables were not created because the data did not contain any additional attributes.
- SQL queries use `CREATE OR REPLACE TABLE` to make reruns deterministic.
- Data quality checks have not yet been implemented but would need to be going forward ensuring. BigQuery assertions could be used for this

### Pipeline execution

Terraform provisions the Cloud Storage bucket, BigQuery dataset and raw table schema.

The batch pipeline is run with:

```bash
terraform -chdir=terraform apply
./scripts/run_pipeline.sh
```

The script uploads the CSV, replaces the raw BigQuery table and executes the SQL models in order

### Auditing
The raw layer is retained so analytics results can be traced back to the source if needed

### Backfills and reprocessing

For a backfill, the source data would be reloaded and the standardised and analytics tables rebuilt. Results would then be reconciled against the previous output.

### Schema Changes

As the `main.tf` file specifies the schema of the `google_bigquery_table.raw_fees`, any new columns would have to be discussed in advance because new columns would cause the CSV load step to fail.

### Evolution

For future evolution there are a few things which would need to be considered or implemented:
- CI/CD pipelines to manage Terraform and SQL validation. Prevents untested/unapproved changes being deployed into production. This can go along with separate DEV/UAT/PROD environments.
- Creation and scheduling of jobs to ensure regular updating of the Analytics Layer tables.
- Automated data quality checks
- Consider partitioning of data by date when working with larger scale as this helps with querying.
- Consolidated data dictionaries, data lineage graphs and entity relationships diagrams when working with more tables and more data sources

------------------------