import DBInterface: execute
import FunSQL: reflect, render
import OHDSICohortExpressions: translate
using DataFrames

target_def = read(TARGET_JSON, String)
outcome_def = read(OUTCOME_JSON, String)

function build_cohort(definition, cohort_id, conn)
    catalog = reflect(conn; schema=SCHEMA, dialect=:duckdb)
    sql = render(catalog, translate(definition; cohort_definition_id=cohort_id))
    execute(
        conn,
        """
    INSERT INTO $SCHEMA.cohort
    SELECT * FROM ($sql) AS foo;
""",
    )
end

execute(
    conn,
    "DELETE FROM $SCHEMA.cohort WHERE cohort_definition_id IN ($TARGET_COHORT_ID, $OUTCOME_COHORT_ID)",
)

for (defn, id, label) in [
    (target_def, TARGET_COHORT_ID, TARGET_LABEL),
    (outcome_def, OUTCOME_COHORT_ID, OUTCOME_LABEL),
]
    println("Building: $label ...")
    try
        build_cohort(defn, id, conn)
        n = DataFrame(
            execute(
                conn,
                "SELECT COUNT(*) AS n FROM $SCHEMA.cohort WHERE cohort_definition_id = $id",
            ),
        )[
            1, :n
        ]
        println("Done - $n rows")
    catch e
        msg = sprint(showerror, e)
        error(
            """
      ✗ Cohort build failed for: $label (id=$id)

        Error: $msg

        This usually means the cohort JSON downloaded from ATLAS is missing a field
        that OHDSICohortExpressions.jl expects (e.g. CollapseSettings).

        Possible fixes:
          1. Open the cohort in ATLAS, ensure it is fully configured, then re-export / re-run.
          2. Check the JSON at: $(id == TARGET_COHORT_ID ? TARGET_JSON : OUTCOME_JSON)
          3. Browse valid cohort definitions at: https://atlas-demo.ohdsi.org/#/cohortdefinitions
      """,
        )
    end
end
