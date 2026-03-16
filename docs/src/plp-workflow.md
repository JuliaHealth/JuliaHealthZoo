# PLP Workflow

This tutorial walks you through the entire Patient-Level Prediction pipeline - from a raw OMOP CDM database to trained classification models - in one page. By the end, you will have three models evaluated and a clear picture of how every intermediate file is produced.

We will work through each step the way `run.jl` executes them, explaining what goes in, what comes out, and why. If you just want to run the pipeline and see results, skip ahead to [Run the Full Pipeline](@ref).

## What You Will Need

Before we start, make sure you have:

| Requirement | Why |
|-------------|-----|
| **Julia 1.10+** | The language everything runs in. [Download here](https://julialang.org/downloads/). |
| **An OMOP CDM DuckDB database** | Any OMOP v5.3/v5.4 database exported as a `.duckdb` file. This is your patient data. |
| **This repository cloned locally** | All pipeline scripts, cohort definitions, and configs live here. |

No ATLAS server is required - cohort definitions are already included as JSON files in the repository.

> **Want different cohorts?** You can browse and download cohort definitions and concept sets from the [OHDSI ATLAS demo](https://atlas-demo.ohdsi.org/#/cohortdefinitions). Find the cohort ID you need, then use [OHDSIAPI.jl](https://github.com/JuliaHealth/OHDSIAPI.jl) to download them programmatically - see the [Package Examples](plp-examples.md) page for how.

## Clone and Set Up

Start by getting the code and navigating to the workflow directory:

```bash
git clone https://github.com/JuliaHealth/JuliaHealthZoo.git
cd JuliaHealthZoo/src/workflows/patient_level_prediction
```

Next, install all Julia dependencies. Open a Julia REPL from inside this directory:

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

This downloads every package the pipeline needs. You only need to do this once.

## Configure the Pipeline

The pipeline reads all its settings from a single file: `config.toml`. Copy the example and fill in your database path:

```bash
cp config.toml.example config.toml
```

Open `config.toml` in any editor:

```toml
[database]
path = "/path/to/your/omop_cdm.duckdb"   # <-- change this to your actual .duckdb file

[schema]
name = "dbt_synthea_dev"                  # the schema inside DuckDB that holds OMOP tables

[cohorts]
target_json  = "data/definitions/Hypertension.json"
outcome_json = "data/definitions/Pneumonia.json"

target_cohort_id  = 1
outcome_cohort_id = 2

target_label  = "Hypertension (target)"
outcome_label = "Pneumonia (outcome)"
```

**What each field means:**

- `database.path` - absolute path to your DuckDB file. This is the only value you *must* change.
- `schema.name` - the schema inside DuckDB where OMOP CDM tables (`person`, `condition_occurrence`, etc.) live.
- `cohorts.target_json` / `outcome_json` - paths to the cohort definition JSON files. These are already included in the repo under `data/definitions/`.
- `cohort_definition_id` values (1 and 2) - integer IDs used to tag rows in the OMOP `cohort` table so we can tell target patients apart from outcome patients.

That is the only file you need to edit. Everything else is ready to go.

## How the Pipeline is Organized

When you run `julia --project=. run.jl`, it executes seven scripts in sequence. Here is the flow:

```
┌-------------------------┐
│  config.toml            │  ← your settings
│  data/definitions/*.json│  ← cohort definitions (included)
└------------┬------------┘
             |
   01_data_loader.jl         Connect to DuckDB, validate paths
             |
   02_cohort_definition.jl   Translate JSON -> SQL, populate cohort table
             |
   03_feature_extraction.jl  Query 6 OMOP tables -> feature matrix
             |
   04_distribution_check.jl  Print summary statistics for QC
             |
   05_outcome_attach.jl      Label each patient: outcome = 0 or 1
             |
   06_preprocessing.jl       Impute, standardize, encode, 80/20 split
             |
   07_train_model.jl         Train 3 models, print AUC scores
             |
┌-------------------------┐
│  output/                │  ← all generated CSV files land here
│    plp_features.csv     │
│    plp_final.csv        │
│    train.csv            │
│    test.csv             │
└-------------------------┘
```

Let's walk through each step.

## Step 1 - Connect to the Database

**Script:** `src/01_data_loader.jl` (the database connection is opened in `run.jl` before this script runs)

**Input:** The `database.path` and `schema.name` from your `config.toml`.

**What happens:** First, `run.jl` reads `config.toml`, opens a DuckDB connection, and validates the database path. Then `01_data_loader.jl` re-reads the config to verify that the cohort JSON files exist at the specified paths. It prints which JSON files it found and lists all OMOP tables present in the schema - a quick sanity check that your database is set up correctly.

```julia
# In run.jl - opens the connection:
conn = DBInterface.connect(DuckDB.DB, DB_PATH)

# In 01_data_loader.jl - verifies cohort JSONs and inspects schema:
println("Target:  $(basename(target_json))")
println("Outcome: $(basename(outcome_json))")
inspect_schema()   # lists all tables in the schema
```

**Output:** A live database connection (`conn`) shared with every subsequent script, plus console confirmation of which JSONs and schema tables were found.

If you see `DuckDB file not found`, double-check the `path` in your `config.toml` - use an absolute path to avoid ambiguity.

## Step 2 - Build Cohorts

**Script:** `src/02_cohort_definition.jl`

**Input:** The two JSON files (`Hypertension.json` and `Pneumonia.json`) that define which patients belong to each group.

**What happens:** Each JSON file is an [OHDSI ATLAS](https://atlas-demo.ohdsi.org/) cohort definition - a machine-readable specification of clinical criteria. The pipeline first **clears** any previously inserted rows for these cohort IDs (so you can safely re-run), then uses [OHDSICohortExpressions.jl](https://github.com/JuliaHealth/OHDSICohortExpressions.jl) and [FunSQL.jl](https://mechanicalrabbit.github.io/FunSQL.jl/stable/) to translate each JSON into SQL and execute it:

```julia
# Clear previous runs
execute(conn, "DELETE FROM $SCHEMA.cohort WHERE cohort_definition_id IN ($TARGET_COHORT_ID, $OUTCOME_COHORT_ID)")

# For each cohort definition:
catalog = reflect(conn; schema=SCHEMA, dialect=:duckdb)
sql = render(catalog, translate(definition; cohort_definition_id=cohort_id))
execute(conn, "INSERT INTO $SCHEMA.cohort SELECT * FROM ($sql) AS foo;")
```

The three-step pattern is: **reflect** the database schema -> **translate** the JSON to a FunSQL query -> **render** it to SQL and execute.

**Output:** Rows inserted into the OMOP `cohort` table. Each row records a `subject_id`, `cohort_definition_id` (1 for target, 2 for outcome), and the patient's `cohort_start_date` (their index date).

You will see console output like:

```
-- Defining cohorts -------------------------
Building: Hypertension (target) ...
Done - 269607 rows
Building: Pneumonia (outcome) ...
Done - 13461 rows
```

If either count is 0, your database may not contain the relevant SNOMED codes, or the JSON may be incompatible. Check the troubleshooting section at the bottom of this page.

## Step 3 - Extract Features

**Script:** `src/03_feature_extraction.jl`

**Input:** The target cohort (ID = 1) in the `cohort` table, plus six OMOP CDM tables.

**What happens:** For each target patient, the pipeline looks back 365 days from their index date and extracts features from six clinical domains:

| OMOP Table | What We Extract |
|------------|----------------|
| `person` | Age at index, gender, race, ethnicity |
| `condition_occurrence` | Count of distinct diagnoses (expanded via `concept_ancestor`) |
| `drug_exposure` | Distinct drugs (via `concept_ancestor`), total days of supply, total quantity, max route concept ID |
| `procedure_occurrence` | Count of distinct procedures (via `concept_ancestor`) |
| `measurement` | Maximum lab/vital value (via `concept_ancestor`), max unit concept ID |
| `observation` | Count of distinct observations, maximum observation value |

All queries share the same temporal guard - only data from **before** the index date is used:

```sql
WHERE table.start_date
    BETWEEN cohort.cohort_start_date - INTERVAL 365 DAY
        AND cohort.cohort_start_date
```

This is what prevents data leakage: we never peek into a patient's future.

The six DataFrames are joined together on `subject_id` into one wide feature matrix.

**Output:** `output/plp_features.csv` - one row per patient, one column per feature. This file has no outcome labels yet; it is purely descriptive.

## Step 4 - Distribution Check

**Script:** `src/04_distribution_check.jl`

**Input:** The feature matrix from Step 3.

**What happens:** The script calls Julia's `describe(df)`, which prints a summary table for each column - including the data type, mean, min, median, max, and count of missing values. This is a quick sanity check before modeling: are any columns entirely zero? Are there implausible outliers?

**Output:** Console-only (no files written). You will see a DataFrame summary like this:

```
15×7 DataFrame
 Row │ variable               mean        min     median   max        nmissing  eltype
─────┼───────────────────────────────────────────────────────────────────────────────────
   1 │ subject_id             5.72e5      3       572376.0 1145353    0         Int64
   2 │ gender_concept_id      8519.44     8507    8507.0   8532       0         Int64
   3 │ race_concept_id        8280.47     0       8527.0   8527       0         Int64
   4 │ ethnicity_concept_id   3.80e7      ...     ...      ...        0         Int64
   5 │ age                    54.6        19      53.0     112        0         Int64
   6 │ condition_count        12.4        8       8.0      137        0         Int64
   7 │ drug_count             389.7       12      321.0    2805       30081     Union{Missing, Int64}
 ...
```

Note that the raw features have 15 columns (before preprocessing). Columns like `total_quantity` and `max_observation_value` may show as entirely `Missing` in synthetic data - these are dropped during preprocessing.

Scan the output for anything that looks off before continuing.

## Step 5 - Attach Outcome Labels

**Script:** `src/05_outcome_attach.jl`

**Input:** The feature matrix (`plp_features.csv`) and the outcome cohort (ID = 2) from the `cohort` table.

**What happens:** Each patient is labeled with a binary outcome: **1** if they appear in the outcome cohort (developed pneumonia within 365 days), **0** otherwise. This is a simple left join:

```julia
outcome_df = DataFrame(execute(conn, """
    SELECT subject_id, 1 AS outcome
    FROM $SCHEMA.cohort
    WHERE cohort_definition_id = $OUTCOME_COHORT_ID
"""))

df = leftjoin(features_df, outcome_df; on=:subject_id)
df[!, :outcome] .= coalesce.(df[!, :outcome], 0)
```

Patients not in the outcome cohort get `missing` from the join, which is replaced with `0` - meaning "no pneumonia observed."

**Output:** `output/plp_final.csv` - the complete labeled dataset, ready for preprocessing. Each row is one patient; the last column is `outcome` (0 or 1).

## Step 6 - Preprocessing

**Script:** `src/06_preprocessing.jl`

**Input:** `output/plp_final.csv`

**What happens:** The raw feature matrix needs a few preparation steps before any model can use it:

1. **Drop low-signal columns** - columns that are mostly missing or unreliable in synthetic data (like `total_quantity` and `max_observation_value`) are removed.
2. **Impute missing values** - patients with no records in a given domain have `missing` for those columns. Numeric gaps are filled with `0` ("no events recorded"); categorical gaps with `"unknown"`.
3. **Standardize numeric features** - logistic regression is sensitive to feature scale, so each of the 9 numeric columns (age, condition_count, drug_count, total_days_supply, max_common_route, max_measurement_value, max_common_unit, procedure_count, observation_count) is centered to zero mean and scaled to unit variance.
4. **One-hot encode categorical variables** - OMOP stores gender, race, and ethnicity as integer concept IDs. These are expanded into binary indicator columns (e.g., `gender_concept_id_8507 = 1.0` or `0.0`) so all features are purely numeric - required by models like logistic regression.
5. **Convert to Float64** - all feature columns are cast to `Float64` for model compatibility.
6. **Train/test split** - the dataset is shuffled and split 80/20.

**Output:** Two files in `output/`:

| File | Contents |
|------|----------|
| `train.csv` | 80% of patients - used to train models |
| `test.csv` | 20% of patients - held out for evaluation |

## Step 7 - Train and Evaluate Models

**Script:** `src/07_train_model.jl`

**Input:** `output/train.csv` and `output/test.csv`

**What happens:** Three classification models are trained through [MLJ.jl](https://alan-turing-institute.github.io/MLJ.jl/stable/)'s uniform interface and evaluated with **ROC AUC** (Area Under the Receiver Operating Characteristic Curve). AUC = 1.0 means perfect predictions; AUC = 0.5 means random guessing.

All three models use the same `evaluate_model` function:

```julia
function evaluate_model(model, X_train, y_train, X_test, y_test)
    m = machine(model, X_train, y_train; scitype_check_level=0)
    fit!(m; verbosity=0)
    preds = predict(m, X_test)
    pos_label = levels(y_train)[2]   # "1"
    probs = [Float64(pdf(p, pos_label)) for p in preds]
    true_vals = [x == pos_label for x in y_test]
    tar = probs[true_vals]      # predicted probabilities for actual positives
    non = probs[.!true_vals]    # predicted probabilities for actual negatives
    auc_val = auc(ROCAnalysis.roc(tar, non))
    return auc_val, m
end
```

`ROCAnalysis.roc(tar, non)` takes two arrays: predicted scores for actual positive cases (`tar`) and predicted scores for actual negative cases (`non`). AUC measures how well the model separates the two groups.

The three models are:

| Model | Package | Why include it |
|-------|---------|----------------|
| **L1 Logistic Regression** | `MLJLinearModels.jl` | Transparent baseline - L1 regularization drives irrelevant feature coefficients to zero, effectively selecting the most informative predictors. |
| **Random Forest** | `MLJDecisionTreeInterface.jl` | Handles non-linear relationships naturally; robust to noisy features. Configured with 100 trees and max depth 10. |
| **XGBoost** | `MLJXGBoostInterface.jl` | Gradient-boosted trees - consistently strong on tabular clinical data. Learning rate 0.1, 100 rounds, max depth 5. |

**Output:** AUC scores printed to your console:

```
L1 Logistic Regression AUC: 0.XXXX
Random Forest AUC:          0.XXXX
XGBoost AUC:                0.XXXX
```

Your exact numbers depend on your database and the random train/test split. On **real-world OMOP data**, tree-based models typically outperform logistic regression on this task, with AUC values in the 0.6–0.8 range. On **synthetic data** (e.g., Synthea), AUC values may hover near 0.5 because the generated conditions and drugs lack the realistic correlations that drive predictivity. This is expected - synthetic databases are useful for testing the pipeline end-to-end, not for drawing clinical conclusions.

These are baseline models with fixed hyperparameters, so there is room to improve via tuning (see the [Adapting](#adapting-to-your-own-data) section).

## Run the Full Pipeline

With your `config.toml` set and dependencies installed, run everything in one command:

```bash
julia --project=. run.jl
```

The full console output looks roughly like this (condensed for readability):

```
Patient-Level Prediction

-- Loading & downloading cohorts ----------------------
Target:  Hypertension.json
Outcome: Pneumonia.json
config.toml updated
Using DB: C:/Users/you/data/synthea_1M_3YR.duckdb

Tables in dbt_synthea_dev:
  - person
  - condition_occurrence
  - drug_exposure
  - measurement
  - observation
  - procedure_occurrence
  - cohort
  ...
Target:  Hypertension (target) (id=1)
Outcome: Pneumonia (outcome) (id=2)

-- Defining cohorts -------------------------
Building: Hypertension (target) ...
Done - 269607 rows
Building: Pneumonia (outcome) ...
Done - 13461 rows

-- Extracting features -------------------------
Feature extraction complete!

-- Checking distributions -------------------------
15×7 DataFrame
 Row │ variable               mean       min      median    max        nmissing  eltype
─────┼───────────────────────────────────────────────────────────────────────────────────
   1 │ subject_id             5.72e5     3        572376.0  1145353    0         Int64
   2 │ age                    54.6       19       53.0      112        0         Int64
   ...

-- Attaching outcomes -------------------------
Outcome attachment complete

-- Preprocessing -------------------------
Train size: 215686 | Test size: 53921
Features:   17 (excluding subject_id and outcome)
Preprocessing complete

-- Training models -------------------------
L1 Logistic Regression AUC: 0.XXXX
Random Forest AUC:          0.XXXX
XGBoost AUC:                0.XXXX

Pipeline complete!
```

Total runtime depends on your database size and hardware - typically a few minutes for a synthetic database.

## What the Pipeline Produces

After a successful run, the `output/` directory contains everything:

```
output/
├-- plp_features.csv   Feature matrix (no labels yet)
├-- plp_final.csv      Feature matrix + outcome column
├-- train.csv          80% training split (ready for modeling)
└-- test.csv           20% test split (ready for evaluation)
```

You can load any of these into a Julia session for further exploration:

```julia
using CSV, DataFrames
df = CSV.read("output/plp_final.csv", DataFrame)
println("Rows: $(nrow(df))  Columns: $(ncol(df))")
first(df, 5)
```

## Adapting to Your Own Data

This pipeline is designed to be reusable. Here is how to adapt it for a different research question:

1. **Different cohorts** - Browse cohort definitions on [ATLAS](https://atlas-demo.ohdsi.org/#/cohortdefinitions), find the one you need, and download the JSON. You can also download the associated **concept sets** (the specific clinical codes included in a phenotype) using [OHDSIAPI.jl](https://github.com/JuliaHealth/OHDSIAPI.jl) - see the [Package Examples](plp-examples.md) page for a working example. Place the JSON files in `data/definitions/` and update the paths in `config.toml`.
2. **Different lookback window** - Edit `const RECENT_DAYS = 365` in `src/03_feature_extraction.jl` to change how far back features are extracted.
3. **Additional features** - Add new SQL queries to `src/03_feature_extraction.jl` for other OMOP tables (e.g., `visit_occurrence` for visit counts).
4. **Tune models** - Adjust hyperparameters in `src/07_train_model.jl`, or wrap any model in `MLJ.TunedModel` for automated hyperparameter search.

## Troubleshooting

**`config.toml not found`** - Make sure you ran `cp config.toml.example config.toml` and that your working directory is `src/workflows/patient_level_prediction/`.

**`DuckDB file not found`** - Double-check the `path` in `config.toml`. Use an absolute path to avoid ambiguity.

**Cohort build returns 0 rows** - Your database may not contain the relevant SNOMED codes for hypertension or pneumonia. Verify that the `condition_occurrence` table has records, and that the `concept_ancestor` table is populated.

**`Package not found`** - Run `Pkg.instantiate()` from a Julia REPL with the project activated:

```julia
using Pkg; Pkg.activate("."); Pkg.instantiate()
```

## References

- Reps, J. M., Schuemie, M. J., Suchard, M. A., Ryan, P. B., & Rijnbeek, P. R. (2018). Design and implementation of a standardized framework to generate and evaluate patient-level prediction models using observational healthcare data. *JAMIA*, 25(8), 969–975. [https://doi.org/10.1093/jamia/ocy032](https://doi.org/10.1093/jamia/ocy032)
- [OHDSI Patient-Level Prediction](https://ohdsi.github.io/PatientLevelPrediction/)
- [OHDSI Common Data Model](https://ohdsi.github.io/CommonDataModel/)
- [ATLAS Demo](https://atlas-demo.ohdsi.org/#/cohortdefinitions)
