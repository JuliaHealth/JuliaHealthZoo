# Getting Started with the PLP Pipeline

## 1. Prepare Your Cohort Definitions

You need **two cohort definitions** in JSON format: one for your **target cohort** (study population) and one for your **outcome** (what you're predicting).

### Where to get them:

Visit **[ATLAS Demo](https://atlas-demo.ohdsi.org/#/conceptsets)** and:
1. Browse existing cohort definitions
2. Click one you like
3. Download the JSON (look for an export/download button)
4. Save it to `data/definitions/` with a clear name

**Example:**
- `data/definitions/Hypertension.json` (target)
- `data/definitions/Pneumonia.json` (outcome)

## 2. Update `config.toml`

Edit `config.toml` in this directory with your paths and cohort IDs:

```toml
[database]
path = "C:/path/to/your/synthea_1M_3YR.duckdb"

[schema]
name = "dbt_synthea_dev"

[cohorts]
target_json       = "data/definitions/Hypertension.json"
target_cohort_id  = 1
target_label      = "Hypertension"

outcome_json      = "data/definitions/Pneumonia.json"
outcome_cohort_id = 2
outcome_label     = "Pneumonia"
```

**Key fields:**
- `path` — Full path to your OMOP DuckDB file
- `name` — Schema name in your database (usually `dbt_synthea_dev`)
- `target_json` — Path to target cohort JSON
- `target_cohort_id` — Cohort ID for the cohort table
- `target_label` — Human-readable name

## 3. Run the Pipeline

```bash
cd workflows/patient_level_prediction
julia --project=. run.jl
```

That's it! The pipeline will:
1. Load your cohort definitions
2. Build cohorts in the database
3. Extract features
4. Train models

## Changing Cohorts

To run with different cohorts:
1. Download new JSONs from ATLAS
2. Save to `data/definitions/`
3. Update `config.toml` with new paths and IDs
4. Re-run `julia --project=. run.jl`
