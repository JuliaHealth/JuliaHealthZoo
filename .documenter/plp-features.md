
# Feature Engineering and Preprocessing {#Feature-Engineering-and-Preprocessing}

## Overview {#Overview}

With the target and outcome cohorts in place, the next step is to describe each target-cohort patient numerically - building a row of features that captures their clinical history in the 365 days before their index date.

The principle is simple: everything we use to predict must come from **before** the index date. Looking at anything that happened after would introduce data leakage and invalidate the model.

## Feature Sources {#Feature-Sources}

Features are drawn from six OMOP CDM tables. Each one captures a different dimension of a patient&#39;s clinical picture.

|             OMOP Table |                                                Features Extracted |
| ----------------------:| -----------------------------------------------------------------:|
| `condition_occurrence` |                                      Number of distinct diagnoses |
|        `drug_exposure` | Distinct drugs, days of supply, total quantity, most common route |
| `procedure_occurrence` |                                     Number of distinct procedures |
|          `observation` |                          Number of distinct clinical observations |
|          `measurement` |                          Maximum recorded value, most common unit |
|               `person` |                        Age at index date, gender, race, ethnicity |


All queries below use the same lookback pattern:

```sql
AND table.start_date BETWEEN cohort.cohort_start_date - INTERVAL 365 DAY
                         AND cohort.cohort_start_date
```


## Extracting Features {#Extracting-Features}

### Drug Exposure {#Drug-Exposure}

```julia
using DuckDB, DBInterface, DataFrames

schema = config["schema"]["name"]

drug_features = DataFrame(DBInterface.execute(conn, """
    SELECT
        c.subject_id,
        COUNT(DISTINCT ca.ancestor_concept_id) AS drug_count,
        SUM(de.days_supply)                    AS total_days_supply,
        SUM(de.quantity)                       AS total_quantity,
        MAX(de.route_concept_id)               AS max_common_route
    FROM $(schema).cohort c
    JOIN $(schema).drug_exposure de
        ON c.subject_id = de.person_id
    JOIN $(schema).concept_ancestor ca
        ON de.drug_concept_id = ca.descendant_concept_id
    WHERE c.cohort_definition_id = 1
      AND de.drug_exposure_start_date
          BETWEEN c.cohort_start_date - INTERVAL 365 DAY
              AND c.cohort_start_date
    GROUP BY c.subject_id
"""))
```


The `concept_ancestor` join rolls up specific drug ingredients to their higher-level drug classes, capturing both specific and general medication exposure patterns.

### Conditions {#Conditions}

```julia
condition_features = DataFrame(DBInterface.execute(conn, """
    SELECT
        c.subject_id,
        COUNT(DISTINCT co.condition_concept_id) AS condition_count
    FROM $(schema).cohort c
    JOIN $(schema).condition_occurrence co
        ON c.subject_id = co.person_id
    WHERE c.cohort_definition_id = 1
      AND co.condition_start_date
          BETWEEN c.cohort_start_date - INTERVAL 365 DAY
              AND c.cohort_start_date
    GROUP BY c.subject_id
"""))
```


### Demographics from Person Table {#Demographics-from-Person-Table}

```julia
person_features = DataFrame(DBInterface.execute(conn, """
    SELECT
        c.subject_id,
        YEAR(c.cohort_start_date) - p.year_of_birth AS age,
        p.gender_concept_id,
        p.race_concept_id
    FROM $(schema).cohort c
    JOIN $(schema).person p
        ON c.subject_id = p.person_id
    WHERE c.cohort_definition_id = 1
"""))
```


## Building the Feature Matrix {#Building-the-Feature-Matrix}

Each feature table is left-joined on `subject_id`. Using a left join ensures every patient in the target cohort appears in the final matrix, even if they have no records in a given table - those missing values are handled during preprocessing.

```julia
features_df = person_features

for df in [drug_features, condition_features]
    features_df = leftjoin(features_df, df; on = :subject_id)
end
```


## Attaching Outcome Labels {#Attaching-Outcome-Labels}

Each patient receives a binary label based on whether they appear in the outcome cohort after their index date. The join is deliberately simple - if a patient has `cohort_definition_id = 2` in the cohort table, they developed pneumonia; everyone else gets label `0`.

```julia
outcome_df = DataFrame(DBInterface.execute(conn, """
    SELECT subject_id, 1 AS outcome
    FROM $(schema).cohort
    WHERE cohort_definition_id = 2
"""))

# Left join - unmatched patients receive missing, replaced with 0
df = leftjoin(features_df, outcome_df; on = :subject_id)
df[!, :outcome] .= coalesce.(df[!, :outcome], 0)
```



![](public/binary_classification.png)


The resulting dataset has one row per patient, with features drawn from their clinical history and a binary outcome label.

The resulting dataset has one row per patient:

|              Column |  Type |                               Meaning |
| -------------------:| -----:| -------------------------------------:|
|        `subject_id` |   Int |                    Patient identifier |
|               `age` | Float |                   Age at cohort entry |
| `gender_concept_id` |   Int |                        Encoded gender |
|        `drug_count` |   Int |     Distinct drugs in lookback window |
|   `condition_count` |   Int | Distinct diagnoses in lookback window |
|               `...` |   ... |              Other extracted features |
|           `outcome` | 0 / 1 |    Did this patient develop diabetes? |


## Preprocessing {#Preprocessing}

Before modeling, the feature matrix needs three preparation steps.

### 1. Impute Missing Values {#1.-Impute-Missing-Values}

Patients with no records in a given OMOP table will have missing values for that table&#39;s features. We replace them with sensible defaults - 0 for numeric fields, `"unknown"` for categorical ones.

```julia
for col in names(df, Not(:subject_id))
    if eltype(df[!, col]) <: Union{Missing, Number}
        df[!, col] = coalesce.(df[!, col], 0)
    else
        df[!, col] = coalesce.(df[!, col], "unknown")
    end
end
```


### 2. Standardize Numeric Features {#2.-Standardize-Numeric-Features}

Logistic regression and distance-based models are sensitive to feature scale. Standardizing each numeric feature to zero mean and unit variance prevents large-valued columns from dominating.

```julia
using Statistics

for col in [:age, :condition_count, :drug_count, :total_days_supply, :total_quantity]
    μ = mean(df[!, col])
    σ = std(df[!, col])
    σ > 0 && (df[!, col] = (df[!, col] .- μ) ./ σ)
end
```


### 3. Encode Categorical Variables {#3.-Encode-Categorical-Variables}

OMOP stores gender and race as integer concept IDs. Converting them to `CategoricalArray` tells MLJ to treat them as unordered categories rather than ordinal numbers.

```julia
using CategoricalArrays

df.gender_concept_id = categorical(df.gender_concept_id)
df.race_concept_id   = categorical(df.race_concept_id)
```


Continue to [Training &amp; Evaluation](plp-modeling.md)
