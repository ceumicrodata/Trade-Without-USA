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

## Model Adaptation for Trade-Without-USA Analysis

### 1. Time Period Modification
- **Limit data to 2003-2007**: Filter time dimension to years 2003-2007 only
- **Create cross-section**: Average across these 5 years to obtain a single cross-sectional dataset
- **Implementation**: Modify data loading in `read_data.jl` to filter and average time periods

### 2. Static Model Configuration
- **Disable random shocks**: Set `S=1` (single state) to eliminate stochastic elements
- **Remove adjustment costs**: Set `one_over_rho = Inf` (or very large number) for instant adjustment
- **Simplify equilibrium**: Focus on static equilibrium without forward-looking expectations
- **Implementation**: Modify parameters in experiment init files to enforce static behavior

### 3. Experiment Simplification
- **Keep only baseline experiment**: Retain `experiments/baseline/` directory
- **Remove other experiments**: Delete CES variants, theta variants, rho variants, etc.
- **Maintain two scenarios**: Keep only `actual` and modified counterfactual scenarios
- **Makefile update**: Simplify targets to focus on single experiment output

### 4. No-USA Counterfactual Setup
- **Modify target country**: Change from China (index 5) to USA (index 25)
- **Set trade barriers**: In `experiments/no_usa/init_parameters.jl`:
  ```julia
  parameters[:kappa_mnjt][25,:,:,:] = ones(size(parameters[:kappa_mnjt][25,:,:,:])) ./ 100000
  parameters[:kappa_mnjt][:,25,:,:] = ones(size(parameters[:kappa_mnjt][:,25,:,:])) ./ 100000
  parameters[:kappa_mnjt][25,25,:,:] = ones(size(parameters[:kappa_mnjt][25,25,:,:]))
  ```
- **Rename experiment**: Change directory from `no_china` to `no_usa`
- **Note**: USA is country index 25 in the data structure (last country in the list)