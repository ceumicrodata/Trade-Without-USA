# Agent Instructions for Trade-Without-USA Repository

## Build/Test Commands
- **Run all experiments**: `make tables` (uses Julia parallel processing)
- **Run specific table**: `make output/table1.csv`
- **Install dependencies**: `julia --project install.jl` or `make install`
- **Run single test**: `julia --project system_test.jl` or `julia --project unit_test.jl`
- **Julia execution**: Always use `julia --project` to ensure correct package environment
- **Parallel execution**: Default uses 8 Julia threads (`PROCS=8`), adjust in Makefile as needed

## Code Style Guidelines
- **Module structure**: Use Julia modules with explicit exports (e.g., `module ImpvolEquilibrium`)
- **Imports**: Use `include()` for local files, `using` for packages, place at file top
- **Array dimensions**: Store all variables as 4D arrays (m,n,j,t) or (m,n,j,s) for conformity
- **Type annotations**: Prefer explicit types in function signatures and data structures
- **Naming**: Use descriptive snake_case for functions/variables, CamelCase for modules/types
- **Error handling**: Use `@assert` for preconditions, proper error messages for user-facing errors
- **File paths**: Always use relative paths from project root
- **Data formats**: CSV for tabular data, JLD2 for Julia objects, avoid hardcoded parameters
- **Documentation**: Keep functions focused with single responsibility, comment complex algorithms
- **Testing**: Place tests in separate files (unit_test.jl, system_test.jl)