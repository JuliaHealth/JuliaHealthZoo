# Getting Started

This guide gets you from zero to a running Patient-Level Prediction pipeline in as few steps as possible. By the end, you will have trained three classification models on real OMOP CDM data and measured their predictive performance.

## What You Need

| Requirement | Notes |
|-------------|-------|
| Julia 1.10 or later | Download from [julialang.org](https://julialang.org/downloads/) |
| An OMOP CDM database in DuckDB format | Any OMOP v5.3/v5.4 database exported as `.duckdb` |
| Internet access | Only needed to refresh cohort definitions from ATLAS |

The pipeline ships with cohort definition files already included, so you can run it against any OMOP-formatted DuckDB database without needing an ATLAS connection upfront.

## Step 1 - Clone the Repository

```bash
git clone https://github.com/JuliaHealth/JuliaHealthZoo.git
cd JuliaHealthZoo/src/workflows/patient_level_prediction
```

## Step 2 - Configure the Pipeline

Copy the example config file and fill in your local database path:

```bash
cp config.toml.example config.toml
```

Open `config.toml` and set the path to your DuckDB database file:

```toml
[database]
path = "/path/to/your/omop_cdm.duckdb"

[schema]
name = "dbt_synthea_dev"

[cohorts]
target_json  = "data/definitions/Hypertension.json"
outcome_json = "data/definitions/Pneumonia.json"

target_cohort_id  = 1
outcome_cohort_id = 2
```

That is the only file you need to edit. The cohort definitions, feature queries, and model training scripts are all ready to go.

## Step 3 - Install Dependencies

From inside the `patient_level_prediction/` directory, open a Julia REPL and instantiate the project environment:

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

This downloads all required packages. You only need to do this once.

> **Test Cohort definitions are already included.** The files `data/definitions/Hypertension.json` and `data/definitions/Pneumonia.json` are part of the repository If you want to download new concept sets, you can visit https://atlas-demo.ohdsi.org/#/conceptsets, or optionally run:
>
> ```julia
> import OHDSIAPI: download_concept_set
> download_concept_set([1792865, 1790632]; deflate = true, output_dir = "data/definitions")
> ```

## Step 4 - Run the Pipeline

With your database path in `config.toml` and dependencies installed, run:

```bash
julia --project=. run.jl
```

The pipeline executes these steps in order:

```
01_data_loader.jl        -> connect to DuckDB, inspect schemas
02_cohort_definition.jl  -> translate cohort JSON to SQL, populate cohort table
03_feature_extraction.jl -> extract features from 6 OMOP tables (365-day lookback)
04_distribution_check.jl -> print summary statistics for quality control
05_outcome_attach.jl     -> label each patient with outcome = 0 or 1
06_preprocessing.jl      -> impute, standardize, encode, split 80/20
07_train_model.jl        -> train LogReg / Random Forest / XGBoost, print AUC
```

Each step prints progress to the console. Total runtime on the 1M-patient database is typically 10–20 minutes depending on hardware.

## Step 5 - Check the Results

After `train_model.jl` completes, you will see output like:

```
L1-regularized Logistic Regression AUC: 0.72
Random Forest AUC: 0.81
XGBoost AUC: 0.84
```

Intermediate files are saved in `output/`:

| File | Contents |
|------|----------|
| `plp_features.csv` | Feature matrix before outcome labeling |
| `plp_final.csv` | Feature matrix with outcome column attached |
| `train.csv` | 80% training split |
| `test.csv` | 20% test split |

You can load any of these directly into a Julia session for further exploration:

```julia
using CSV, DataFrames
df = CSV.read("output/plp_final.csv", DataFrame)
```

## Adapting to Your Own Data

To run this workflow on your own research question:

1. **Choose different cohorts** - find new ATLAS cohort IDs at [atlas-demo.ohdsi.org](https://atlas-demo.ohdsi.org/#/cohortdefinitions), download their JSON with `download_cohort_definition`, and update `config.toml`
2. **Change the lookback window** - edit `const RECENT_DAYS = 365` in `src/03_feature_extraction.jl`
3. **Add features** - extend `src/03_feature_extraction.jl` with additional OMOP table queries
4. **Tune models** - adjust hyperparameters in `src/07_train_model.jl` or wrap any model in `MLJ.TunedModel` for automated search

## Where to Go Next

- [Introduction](plp-intro.md) - the concepts behind PLP and OMOP CDM
- [Package Examples](plp-examples.md) - focused demos of each JuliaHealth package
- [Setup and Cohort Building](plp-setup.md) - deep dive into the cohort SQL pipeline
- [Feature Engineering](plp-features.md) - all six OMOP feature queries, explained
- [Training and Evaluation](plp-modeling.md) - MLJ.jl model training and AUC comparison

## Troubleshooting

**`config.toml not found`** - Make sure you ran `cp config.toml.example config.toml` and that your working directory is `src/workflows/patient_level_prediction/`.

**`DuckDB file not found`** - Double-check the `path` in `config.toml`. Use an absolute path to avoid ambiguity.

**`Cohort build failed`** - The cohort JSON may be missing a field that `OHDSICohortExpressions.jl` requires. Check the JSON files in `data/definitions/` or re-download them from ATLAS. You can browse valid example definitions at [atlas-demo.ohdsi.org/\#/cohortdefinitions](https://atlas-demo.ohdsi.org/#/cohortdefinitions).

**`Package not found`** - Run `Pkg.instantiate()` from a Julia REPL with the project activated:

```julia
using Pkg; Pkg.activate("."); Pkg.instantiate()
```
