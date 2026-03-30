# BART and BartIO.jl

BART (Berkeley Advanced Reconstruction Toolbox) is a C-based MRI reconstruction
toolbox with command-line and Python integration paths.
It provides a large set of MRI reconstruction utilities used in research workflows.

Important note:

- The toolbox is for research use (not diagnostic use).

## Minimal BART pipeline example

A minimal `phantom -> nufft -i` example is shown below.

```bash
bart phantom -k -t traj kspace
bart nufft -i traj kspace image
```

## BartIO.jl from Julia

BartIO.jl is used in this workflow as a Julia-side interface to BART commands
and BART file I/O patterns. Common usage examples include:

- `set_bart_path("/path/to/bart")`
- `read_cfl(...)`
- `write_cfl(...)`
- `bart(nargout, "cmd", ...)`

### Example usage in Julia

```julia
using BartIO

set_bart_path("/path/to/bart")

traj = bart(1, "traj -x 128 -y 256 -r")
k_phant = bart(1, "phantom -k -t", traj)
im_phant = bart(1, "nufft -i", traj, k_phant)

write_cfl("k_phant", k_phant)
k2 = read_cfl("k_phant")
```

This is functionally equivalent to CLI calls and keeps the experiment orchestrated
inside Julia.

It also keeps file exchange explicit, because BART data can be written and read
through `.cfl/.hdr` in the same script that performs reconstruction calls.

## Why BartIO is valuable in this workflow

- run BART without leaving Julia orchestration
- compare BART output with MRIReco output in one script/notebook
- preserve reproducibility using Julia-side metadata and plotting

## Official sources

- https://bart-doc.readthedocs.io/en/latest/intro.html
- https://github.com/MagneticResonanceImaging/BartIO.jl