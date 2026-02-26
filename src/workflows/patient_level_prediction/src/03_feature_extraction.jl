# Extract features from OMOP CDM: demographics, conditions, drugs, measurements, procedures, observations

import InvertedIndices: Not
import DBInterface: execute
import DataFrames: DataFrame, outerjoin, select!
using CSV: CSV
import Dates: year, today

const OUTPUT_DIR = joinpath(@__DIR__, "..", "output")
const COHORT_TABLE = "cohort"
const RECENT_DAYS = 365

mkpath(OUTPUT_DIR)

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
demographics_df = DataFrame(execute(conn, demographics_query))

ref_year = year(today())
demographics_df[!, :age] = ref_year .- demographics_df[!, :year_of_birth]
select!(demographics_df, Not(:year_of_birth))

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
conditions_df = DataFrame(execute(conn, conditions_query))

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
drugs_df = DataFrame(execute(conn, drugs_query))

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
measurements_df = DataFrame(execute(conn, measurements_query))

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
procedures_df = DataFrame(execute(conn, procedures_query))

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
observations_df = DataFrame(execute(conn, observations_query))

features_df = outerjoin(demographics_df, conditions_df; on=:subject_id)
features_df = outerjoin(features_df, drugs_df; on=:subject_id)
features_df = outerjoin(features_df, measurements_df; on=:subject_id)
features_df = outerjoin(features_df, procedures_df; on=:subject_id)
features_df = outerjoin(features_df, observations_df; on=:subject_id)

CSV.write(joinpath(OUTPUT_DIR, "plp_features.csv"), features_df)
println("Feature extraction complete!")
