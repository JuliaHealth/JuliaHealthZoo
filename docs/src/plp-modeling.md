# Training and Evaluation

## Train-Test Split

The dataset is randomly split 80/20. A fixed random seed (`rng = 42`) makes the split reproducible - anyone running the workflow gets the same partition.

```julia
using MLJ, CategoricalArrays

train_idx, test_idx = partition(eachindex(df.outcome), 0.8; shuffle = true, rng = 42)

X_train = df[train_idx, Not(:outcome, :subject_id)]
X_test  = df[test_idx,  Not(:outcome, :subject_id)]

# MLJ classifiers expect a categorical target
y_train = categorical(string.(df[train_idx, :outcome]))
y_test  = df[test_idx, :outcome]
```

The `Not(:outcome, :subject_id)` selector drops the label and the patient ID from the feature matrix - the model should see neither.

![Train-Test Split](public/train_test_splitting.png)

## Training Models with MLJ.jl

[MLJ.jl](https://alan-turing-institute.github.io/MLJ.jl/stable/) provides a single, consistent interface for working with machine learning models in Julia. The same `machine → fit! → predict` pattern works across all model families, making it easy to swap algorithms without restructuring code.

![MLJ Ecosystem](public/mlj.png)

Three models are trained and compared. The evaluation metric is **AUC** (Area Under the ROC Curve): a value of 1.0 is perfect, 0.5 is random guessing.

```julia
using ROCAnalysis

function evaluate_model(model, X_train, y_train, X_test, y_test)
    mach = machine(model, X_train, y_train)
    fit!(mach; verbosity = 0)
    probs = pdf.(predict(mach, X_test), "1")       # P(outcome = 1) for each patient
    return auc(roc(probs, y_test .== 1))
end
```

### Logistic Regression with L1 Regularization

Logistic regression is a transparent, interpretable baseline. L1 regularization (Lasso) pushes the coefficients of irrelevant features to zero, effectively selecting the most informative predictors.

See: [MLJLinearModels.jl documentation](https://juliaai.github.io/MLJLinearModels.jl/stable/)

```julia
using MLJLinearModels

log_reg = MLJLinearModels.LogisticClassifier(penalty = :l1, lambda = 0.01)
auc_lr  = evaluate_model(log_reg, X_train, y_train, X_test, y_test)
println("Logistic Regression  AUC: $auc_lr")
```

A lower `lambda` means less regularization (more coefficients are non-zero). This can be tuned with `MLJ.TunedModel`.

### Random Forest

Random forests build many decision trees on random subsets of the data and average their predictions. They handle non-linear relationships well, require little preprocessing, and are robust to noisy features.

See: [MLJDecisionTreeInterface.jl documentation](https://github.com/JuliaAI/MLJDecisionTreeInterface.jl)

```julia
using MLJDecisionTreeInterface

rf     = MLJDecisionTreeInterface.RandomForestClassifier(n_trees = 100)
auc_rf = evaluate_model(rf, X_train, y_train, X_test, y_test)
println("Random Forest        AUC: $auc_rf")
```

Increasing `n_trees` improves stability at the cost of runtime.

### XGBoost

XGBoost (eXtreme Gradient Boosting) trains trees sequentially, each one correcting the residual errors of the previous. It is often the strongest performer on tabular clinical data.

See: [MLJXGBoostInterface.jl documentation](https://github.com/JuliaAI/MLJXGBoostInterface.jl)

```julia
using MLJXGBoostInterface

xgb     = MLJXGBoostInterface.XGBoostClassifier(num_round = 100, max_depth = 5)
auc_xgb = evaluate_model(xgb, X_train, y_train, X_test, y_test)
println("XGBoost              AUC: $auc_xgb")
```

`num_round` controls the number of boosting rounds; `max_depth` controls tree complexity.

## Full Pipeline Summary

The complete PLP workflow in one view:

| Step | Package |
|------|---------|
| Study initialization | `HealthBase.jl` |
| Cohort download | `OHDSIAPI.jl` |
| Data loading | `TOML` + `DBInterface.jl` |
| Cohort SQL translation | `OHDSICohortExpressions.jl` + `FunSQL.jl` |
| Feature extraction | `DuckDB.jl` + `DataFrames.jl` |
| Outcome labeling | `DataFrames.jl` |
| Imputation & standardization | `Statistics` (stdlib) |
| Categorical encoding | `CategoricalArrays.jl` |
| Train-test split | `MLJ.jl` |
| Modeling | `MLJLinearModels.jl` · `MLJDecisionTreeInterface.jl` · `MLJXGBoostInterface.jl` |
| Evaluation | `ROCAnalysis.jl` |

The entire workflow is driven by a single `config.toml` and runs reproducibly with:

```bash
julia --project=. run.jl
```

## References

- Reps, J. M., et al. (2018). Design and implementation of a standardized framework to generate and evaluate patient-level prediction models using observational healthcare data. *JAMIA*, 25(8), 969–975. https://doi.org/10.1093/jamia/ocy032
- [OHDSI Common Data Model](https://ohdsi.github.io/CommonDataModel/)
- [ATLAS Demo Tool](https://atlas-demo.ohdsi.org/#/cohortdefinitions)
- [JuliaHealth on GitHub](https://github.com/JuliaHealth)
