# Train and evaluate models: L1-Logistic Regression, Random Forest, XGBoost

import CSV
import DataFrames:
    DataFrame,
    select,
    Not
import CategoricalArrays:
    categorical,
    levels
import MLJ
import MLJLinearModels
import MLJDecisionTreeInterface
import MLJBase: machine
import MLJ:
    fit!,
    predict
using ROCAnalysis
using Distributions
using MLJXGBoostInterface

const OUTPUT_DIR = joinpath(@__DIR__, "..", "output")

train_df = CSV.read(joinpath(OUTPUT_DIR, "train.csv"), DataFrame)
test_df  = CSV.read(joinpath(OUTPUT_DIR, "test.csv"), DataFrame)

train_df.outcome = categorical(string.(train_df.outcome), levels=["0", "1"])
test_df.outcome  = categorical(string.(test_df.outcome), levels=["0", "1"])

y_train = train_df.outcome
X_train = select(train_df, Not(:outcome))
y_test  = test_df.outcome
X_test  = select(test_df, Not(:outcome))

# trains, predicts, and computes AUC
function evaluate_model(model, X_train, y_train, X_test, y_test)
    m = machine(model, X_train, y_train; scitype_check_level=0)
    fit!(m, verbosity=0)
    preds = predict(m, X_test)
    pos_label = levels(y_train)[2]

    probs = [Float64(pdf(p, pos_label)) for p in preds]
    true_vals = [x == pos_label ? 1.0 : 0.0 for x in y_test]
    auc_val = auc(ROCAnalysis.roc(probs, true_vals))
    return auc_val, m
end

# L1-regularized Logistic Regression (baseline as per paper)
logreg_model = MLJLinearModels.LogisticClassifier(penalty = :l1, lambda = 0.0428)
auc_logreg, mach_logreg = evaluate_model(logreg_model, X_train, y_train, X_test, y_test)
println("L1-regularized Logistic Regression AUC: ", auc_logreg)

# Random Forest
rf_model = MLJDecisionTreeInterface.RandomForestClassifier(n_trees=100, max_depth=10)
auc_rf, mach_rf = evaluate_model(rf_model, X_train, y_train, X_test, y_test)
println("Random Forest AUC: ", auc_rf)

# XGBoost
gbm_model = MLJXGBoostInterface.XGBoostClassifier(num_round=100, max_depth=5, eta=0.1)
auc_gbm, mach_gbm = evaluate_model(gbm_model, X_train, y_train, X_test, y_test)
println("XGBoost AUC: ", auc_gbm)
