# Interoperability (PythonCall/C++)

In MRI research, interoperability is not just a convenience layer. It is often the
practical bridge between simulation, reconstruction, visualization, and existing
lab tooling. Teams rarely start from a blank slate. Some components already live in
Julia, some in Python, and many mature reconstruction tools are still C/C++ based.

For this reason, this workflow treats Julia as the orchestration language and uses
interoperability deliberately: keep data movement explicit, keep dependencies
project-scoped, and keep the reconstruction path reproducible across machines.

Core interoperability principles used here:

- keep language boundaries explicit
- keep environment setup project-local
- keep data exchange formats visible and reproducible

PythonCall provides the Julia/Python bridge used here. It supports importing
Python modules directly from Julia, calling Python functions, and converting values
explicitly with `pyconvert` when Julia-native types are required.

It also provides wrapper types around Python objects and integrates with CondaPkg
for project-level dependency management.

### Minimal PythonCall pattern

```julia
using PythonCall

np = pyimport("numpy")
arr = np.arange(8)
```

If a BART Python module is available in the environment, it can be imported
in the same style and called from Julia.

```julia
using PythonCall

bart_py = pyimport("bart")
out = bart_py.bart(1, "version")
```

This directly demonstrates the "import and call BART Python functions from Julia" path.

## C/C++ toolchain interoperability context

In this workflow, BART represents the C/C++ side of the ecosystem.

In practice, Julia can interact with BART through three main paths:

- BartIO.jl for Julia-native command calls and `.cfl/.hdr` handling
- direct CLI calls for command-level reproducibility
- Python wrapper access through PythonCall when Python helpers already exist

## When to use what

- Prefer BartIO.jl when:
	- you want Julia-first scripts
	- you need direct `.cfl/.hdr` handling
	- you want low cross-language overhead

- Prefer PythonCall when:
	- your team already uses Python notebooks or helper modules
	- a required component is available only in Python
	- hybrid prototyping speed is the priority

- Use direct CLI calls when:
	- validating exact BART command behavior
	- matching published command pipelines
	- debugging wrapper-independent differences

## Official sources

- https://juliapy.github.io/PythonCall.jl/stable/pythoncall/
- https://juliapy.github.io/PythonCall.jl/stable/pythoncall-reference/
- https://bart-doc.readthedocs.io/en/latest/intro.html