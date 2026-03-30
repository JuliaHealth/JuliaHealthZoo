# MRI Simulation and Reconstruction in Julia

MRI simulation and reconstruction are core parts of open-source computational imaging research.
Before testing methods on scanner-acquired data, researchers often need controlled synthetic data,
reproducible reconstructions, and fair cross-method comparisons.

This MRI track is designed around that research workflow.

In open-source imaging research, reproducibility is as important as algorithm quality.
Researchers need to share acquisition assumptions, reconstruction settings, and output comparisons
in a way that other groups can rerun without hidden proprietary dependencies.

MRI simulation is useful because it provides known ground truth conditions. Reconstruction is useful
because it connects those conditions to interpretable images and quantitative metrics.
Together, simulation and reconstruction create a practical loop for method development, validation,
and transparent comparison.

## Open-Source Research Context

In practice, MRI method development usually needs all of the following:

1. A simulation path to generate reproducible raw data.
2. A reconstruction path for baseline and advanced methods.
3. A comparison path across tools and language ecosystems.
4. Clear documentation so experiments can be repeated by others.

Julia is used here as the orchestration layer for those steps.

This documentation is written to keep that loop easy to follow from a user perspective:
start from high-level context, move through package-specific pages, and then consolidate into
an end-to-end implementation page once the code workflow is finalized.

## What This Tutorial Set Covers

This tutorial is intentionally split into focused pages. Package-level details are documented in those pages, not here.

- [KomaMRI.jl](mri-komamri.md)
- [MRIReco.jl](mri-mrireco.md)
- [BART and BartIO.jl](mri-bart-bartio.md)
- [Interoperability (PythonCall/C++)](mri-interop.md)
- [End-to-End Workflow](mri-workflow.md)

