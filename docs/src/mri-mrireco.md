# MRIReco.jl

MRIReco.jl is the reconstruction pillar of this workflow.
Its documentation describes a modular reconstruction framework with both direct
and iterative methods, including compressed sensing approaches such as ADMM.

MRIReco is designed to be both easy to use and flexibly expandable.
That balance is important for this tutorial: readers can start from standard patterns,
then incrementally move to more advanced reconstruction settings.

## Why MRIReco in this workflow

MRIReco is a strong Julia-native reconstruction option for:

- Cartesian and non-Cartesian MRI
- iterative regularized reconstructions
- rapid experimentation with modular imaging operators

## Modular package design

MRIReco documentation highlights the modular ecosystem and references key packages:

- `NFFT.jl` and `FFTW.jl` for fast Fourier transforms
- `Wavelets.jl` for sparsifying transforms
- `LinearOperators.jl` for composable operator-based modeling
- `RegularizedLeastSquares.jl` for modern optimization algorithms

This modularity makes it easier to test new reconstruction ideas without rewriting
the entire pipeline.

From a user workflow perspective, this modular decomposition keeps experiments maintainable:
trajectory handling, operators, and optimization settings can be changed independently,
which is exactly what is needed for careful method comparison.

## Compressed sensing and ADMM

MRIReco supports iterative compressed sensing-style workflows.
ADMM is explicitly documented in the compressed sensing section.
The compressed sensing examples also include a TV-regularized reconstruction configuration.

Example pattern from the documentation (compressed sensing page):

```julia
params = Dict{Symbol, Any}()
params[:reco] = "multiCoil"
params[:reconSize] = (320,320)
params[:senseMaps] = smaps

params[:solver] = ADMM
params[:reg] = TVRegularization(1.e-1, shape = (320, 320))
params[:iterations] = 50
params[:ρ] = 0.1

img_tv = reconstruction(acqDataSub, params)
```

## Sampling patterns to compare

The workflow should compare at least:

- Cartesian
- radial
- spiral

MRIReco explicitly supports varied scanning patterns.
In practice, this allows fair evaluation of reconstruction behavior across trajectories.

From a reader perspective, this is where reconstruction choices become interpretable:
the same algorithmic settings can be compared across Cartesian and non-Cartesian
sampling conditions.

## Suggested evaluation outputs

- reconstructed magnitude images
- residual/error maps vs. reference
- convergence/runtime summaries (where available)

## Official sources

- https://magneticresonanceimaging.github.io/MRIReco.jl/latest/
- https://magneticresonanceimaging.github.io/MRIReco.jl/latest/compressedSensing/
- https://magneticresonanceimaging.github.io/MRIReco.jl/latest/overview/