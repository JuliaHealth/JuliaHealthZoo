# Extract features from OMOP CDM: demographics, conditions, drugs, measurements, procedures, observations

import InvertedIndices: Not
import DBInterface:
    connect,
    close!,
    execute
import DuckDB: DB
import DataFrames:
    DataFrame,
    outerjoin,
    select!
import CSV
import Dates:
    year,
    today

const DATA_DIR = joinpath(@__DIR__, "..", "data")
const OUTPUT_DIR = joinpath(@__DIR__, "..", "output")
mkpath(OUTPUT_DIR)

connection = connect(DB, joinpath(DATA_DIR, "synthea_1M_3YR.duckdb"))

const SCHEMA = "dbt_synthea_dev"
const COHORT_TABLE = "cohort"
const TARGET_COHORT_ID = 1 # hypertension
const RECENT_DAYS = 365 # 1-year history window

# Demographics: age, gender, race, ethnicity
demographics_query = """
SELECT c.subject_id,
       p.year_of_birth,
       p.gender_concept_id,
       p.race_concept_id,
       p.ethnicity_concept_id
FROM $SCHEMA.$COHORT_TABLE c
JOIN $SCHEMA.person p ON c.subject_id = p.person_id
WHERE c.cohort_definition_id = $TARGET_COHORT_ID
"""
demographics_df = execute(connection, demographics_query) |> DataFrame

# created new age column from year_of_birth using current year as reference,
# and dropped the original year_of_birth column
ref_year = year(today())
demographics_df[!, :age] = ref_year .- demographics_df[!, :year_of_birth]
select!(demographics_df, Not(:year_of_birth))

# Conditions: count of parent & child conditions before index
conditions_query = """
SELECT c.subject_id,
       COUNT(DISTINCT ca.ancestor_concept_id) AS condition_count,
       MAX(co.condition_status_concept_id) AS max_condition_status
FROM $SCHEMA.$COHORT_TABLE c
JOIN $SCHEMA.condition_occurrence co ON c.subject_id = co.person_id
JOIN $SCHEMA.concept_ancestor ca ON co.condition_concept_id = ca.descendant_concept_id
WHERE c.cohort_definition_id = $TARGET_COHORT_ID
AND co.condition_start_date BETWEEN c.cohort_start_date - INTERVAL $RECENT_DAYS DAY AND c.cohort_start_date
GROUP BY c.subject_id
"""
conditions_df = execute(connection, conditions_query) |> DataFrame

# Drugs: count of parent & child drugs before index date
drugs_query = """
SELECT c.subject_id,
       COUNT(DISTINCT ca.ancestor_concept_id) AS drug_count,
       SUM(de.days_supply) AS total_days_supply,
       SUM(de.quantity) AS total_quantity,
       MAX(de.route_concept_id) AS max_common_route
FROM $SCHEMA.$COHORT_TABLE c
JOIN $SCHEMA.drug_exposure de ON c.subject_id = de.person_id
JOIN $SCHEMA.concept_ancestor ca ON de.drug_concept_id = ca.descendant_concept_id
WHERE c.cohort_definition_id = $TARGET_COHORT_ID
AND de.drug_exposure_start_date BETWEEN c.cohort_start_date - INTERVAL $RECENT_DAYS DAY AND c.cohort_start_date
GROUP BY c.subject_id
"""
drugs_df = execute(connection, drugs_query) |> DataFrame

# Measurements: last recorded measurement values grouped by hierarchy
measurements_query = """
SELECT c.subject_id,
       MAX(m.value_as_number) AS max_measurement_value,
       MAX(m.unit_concept_id) AS max_common_unit
FROM $SCHEMA.$COHORT_TABLE c
JOIN $SCHEMA.measurement m ON c.subject_id = m.person_id
JOIN $SCHEMA.concept_ancestor ca ON m.measurement_concept_id = ca.descendant_concept_id
WHERE c.cohort_definition_id = $TARGET_COHORT_ID
AND m.measurement_date BETWEEN c.cohort_start_date - INTERVAL $RECENT_DAYS DAY AND c.cohort_start_date
GROUP BY c.subject_id
"""
measurements_df = execute(connection, measurements_query) |> DataFrame

# Procedures: count of past procedures grouped by hierarchy
procedures_query = """
SELECT c.subject_id,
       COUNT(DISTINCT ca.ancestor_concept_id) AS procedure_count
FROM $SCHEMA.$COHORT_TABLE c
JOIN $SCHEMA.procedure_occurrence po ON c.subject_id = po.person_id
JOIN $SCHEMA.concept_ancestor ca ON po.procedure_concept_id = ca.descendant_concept_id
WHERE c.cohort_definition_id = $TARGET_COHORT_ID
AND po.procedure_date BETWEEN c.cohort_start_date - INTERVAL $RECENT_DAYS DAY AND c.cohort_start_date
GROUP BY c.subject_id
"""
procedures_df = execute(connection, procedures_query) |> DataFrame

# Observations: count and latest observation value before index
observations_query = """
SELECT c.subject_id,
       COUNT(DISTINCT ob.observation_concept_id) AS observation_count,
       MAX(ob.value_as_number) AS max_observation_value
FROM $SCHEMA.$COHORT_TABLE c
JOIN $SCHEMA.observation ob ON c.subject_id = ob.person_id
WHERE c.cohort_definition_id = $TARGET_COHORT_ID
AND ob.observation_date BETWEEN c.cohort_start_date - INTERVAL $RECENT_DAYS DAY AND c.cohort_start_date
GROUP BY c.subject_id
"""
observations_df = execute(connection, observations_query) |> DataFrame

# merging all features into a single DataFrame
features_df = outerjoin(demographics_df, conditions_df, on=:subject_id)
features_df = outerjoin(features_df, drugs_df, on=:subject_id)
features_df = outerjoin(features_df, measurements_df, on=:subject_id)
features_df = outerjoin(features_df, procedures_df, on=:subject_id)
features_df = outerjoin(features_df, observations_df, on=:subject_id)

CSV.write(joinpath(OUTPUT_DIR, "plp_features.csv"), features_df)
println("Feature extraction complete!")

close!(connection)
