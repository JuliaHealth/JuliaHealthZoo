# Patient-Level Prediction (PLP)

A Julia-based observational study pipeline for extracting patient cohorts, defining outcomes, building features, and training predictive models on OMOP CDM data.

## What does it do?

1. **Loads cohort definitions** → Reads target and outcome cohorts from JSON
2. **Builds cohorts** → Creates patient cohorts in your OMOP database
3. **Extracts features** → Pulls demographics, conditions, drugs, measurements, procedures, observations
4. **Attaches outcomes** → Joins outcome events to the target cohort
5. **Preprocesses data** → Standardizes, encodes, splits train/test
6. **Trains models** → Logistic regression, random forest, gradient boosting

## Quick Start

See [GET_STARTED.md](GET_STARTED.md) for step-by-step instructions.

## Requirements

- Julia 1.10+
- DuckDB database with OMOP CDM data
- Target and outcome cohort definitions (JSON format from ATLAS)

## Project Structure

```
workflows/patient_level_prediction/
├── config.toml              <- Configure your paths and cohort IDs
├── run.jl                   <- Main pipeline (run this!)
├── data/definitions/        <- Cohort JSON files
├── src/                     <- Pipeline scripts
│   ├── 01_data_loader.jl
│   ├── 02_cohort_definition.jl
│   ├── 03_feature_extraction.jl
│   ├── 04_distribution_check.jl
│   ├── 05_outcome_attach.jl
│   ├── 06_preprocessing.jl
│   └── 07_train_model.jl
└── output/                  <- Results (train/test splits, models)
```



