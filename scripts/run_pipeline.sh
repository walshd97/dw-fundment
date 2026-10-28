#!/usr/bin/env bash

set -euo pipefail

echo "Running clean fees model..."
bq query \
    --location=europe-west2 \
    --use_legacy_sql=false \
    < sql/01_clean_fees.sql

echo "Clean fees model created successfully"

echo "Running client LTV model..."
bq query \
    --location=europe-west2 \
    --use_legacy_sql=false \
    < sql/02_client_ltv.sql

echo "Client LTV model created successfully"

echo "Running cohort LTV model..."
bq query \
    --location=europe-west2 \
    --use_legacy_sql=false \
    < sql/03_cohort_ltv.sql

echo "Cohort LTV model created successfully"

echo "Running adviser LTV model..."
bq query \
    --location=europe-west2 \
    --use_legacy_sql=false \
    < sql/04_adviser_ltv.sql

echo "Adviser LTV model created successfully"

echo "Pipeline completed successfully."