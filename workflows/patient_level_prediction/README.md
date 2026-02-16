# Patient-Level Prediction with Observational Health Tooling

## Overview

This workflow demonstrates **patient-level prediction (PLP)** using observational healthcare data in the OMOP Common Data Model (CDM) format. It guides you through building a predictive model that identifies which patients with a given condition (e.g., hypertension) are likely to develop an outcome (e.g., diabetes) based on their historical medical records.

## Goal / Domain

**Research Question:** Can we predict the onset of diabetes in patients diagnosed with hypertension using observational healthcare data?

This workflow showcases how the Julia health ecosystem enables reproducible, standardized patient-level prediction following the OHDSI framework. It demonstrates:

- Cohort definition from OMOP CDM tables
- Feature extraction from multiple data sources (conditions, medications, procedures, measurements, observations)
- Data preprocessing and imputation
- Training and evaluation of multiple machine learning models
- Model performance comparison using AUC (Area Under the ROC Curve)

## What This Demonstrates

- **Cohort construction**: Define target and outcome cohorts from OMOP CDM
- **Feature engineering**: Extract patient-level features (demographics, diagnosis counts, medication history, etc.) within a temporal lookback window
- **Outcome attachment**: Link outcome labels with temporal validation
- **Preprocessing**: Handle missing values, standardize numeric features, encode categorical variables
- **Model training**: Train logistic regression, random forest, and XGBoost models using MLJ.jl
- **Evaluation**: Compute AUC and compare model performance

## Dependencies

This workflow requires:

- **Julia 1.10+**
- Data processing: DataFrames.jl, CSV.jl, CategoricalArrays.jl
- Database: DuckDB.jl, DBInterface.jl
- ML: MLJ.jl, MLJLinearModels.jl, MLJDecisionTreeInterface.jl, MLJXGBoostInterface.jl
- OHDSI: OHDSICohortExpressions.jl, FunSQL.jl
- Utilities: ROCAnalysis.jl, PrettyTables.jl, Downloads.jl

All dependencies are pinned in Project.toml.

## How to Run

### 1. Set Up Your Environment

```julia
cd workflows/patient_level_prediction
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

This installs all required packages at the specified versions.

### 2. Run the Full Pipeline

```julia
julia --project=. run.jl
```

Or from within Julia:

```julia
julia> using Pkg; Pkg.activate("."); Pkg.instantiate()
julia> include("run.jl")
```

### 3. Pipeline Stages

The `run.jl` script orchestrates the following stages:

1. **Data Download** (`src/download_data.jl`): Download OMOP CDM parquet files from Zenodo
2. **Database Setup** (`src/setup_db.jl`): Create DuckDB schema, cohort table, and load parquet files
3. **Data Loading** (`src/data_loader.jl`): Connect to OMOP CDM database and inspect tables
4. **Cohort Definition** (`src/cohort_definition.jl`): Define target (hypertension) and outcome (diabetes) cohorts using JSON specifications
5. **Feature Extraction** (`src/feature_extraction.jl`): Extract demographics, conditions, drugs, measurements, procedures, observations
6. **Distribution Check** (`src/distribution_check.jl`): Summarize feature distributions and missing values
7. **Outcome Attachment** (`src/outcome_attach.jl`): Join outcome labels with temporal ordering validation
8. **Preprocessing** (`src/preprocessing.jl`): Impute missing values, standardize numeric features, encode categorical variables, split train/test
9. **Model Training** (`src/train_model.jl`): Train and evaluate multiple models (L1-Logistic Regression, Random Forest, XGBoost)

## Expected Data

You will need an OMOP CDM database (DuckDB, PostgreSQL, or other supported backend) with tables:

- person � patient demographics
- condition_occurrence � diagnoses (e.g., hypertension, diabetes)
- drug_exposure � medications
- procedure_occurrence � procedures
- measurement � lab values
- observation � non-standardized observations
- concept_ancestor � hierarchical relationships between medical concepts
- cohort � target and outcome cohort definitions

Download public OMOP data from [Zenodo](https://doi.org/10.5281/zenodo.14674051).

## References

- **OHDSI PLP Framework**: Reps, J. M., Schuemie, M. J., Suchard, M. A., Ryan, P. B., Rijnbeek, P. R., & Madigan, D. (2018). Design and implementation of a standardized framework to generate and evaluate patient-level prediction models using observational healthcare data. *Journal of the American Medical Informatics Association*, 25(8), 969�975. https://doi.org/10.1093/jamia/ocy032
- **OHDSI PLP (R)**: https://ohdsi.github.io/PatientLevelPrediction/
- **OMOP Common Data Model**: https://ohdsi.github.io/CommonDataModel/
- **OHDSI ATLAS**: https://atlas.ohdsi.org/
- **JuliaHealth**: https://github.com/JuliaHealth

## Authors

- @kosuri-indu
- @TheCedarPrince
