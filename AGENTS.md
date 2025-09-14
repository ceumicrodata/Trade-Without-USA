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

### 4. Computing New Moments
Here’s where moments are computed and how they are written to tables, so you can adapt them for
different actual vs counterfactual moments.

Where moments are computed

• File: output.jl (module ImpvolOutput)
• Entry point: write_results(parameters, rootpath="experiments/baseline/", key=:real_GDP,
bool_detrend=true, dirsdown=1, pattern=r"jld2$")
 • Reads country list: data/country_name.txt
 • Recurses under directories one level below rootpath (dirsdown=1), i.e., scenario folders like
 experiments/baseline/actual and experiments/baseline/no_usa
 • For each results.jld2 file, loads the time-sorted results with read_results + sort_results
 • Builds a 4D array for the chosen variable key using make_series(results, key):
  • shape: (m, n, j, t) with s already collapsed to first state
 • Aggregates across sectors: series = cat(dims=ndims(sectoral_series), sum(sectoral_series, dims=3))
 • Computes the “moment” as a time variance:
  • calculate_volatilities(series, parameters, bool_detrend) detrends log(x) with DetrendUtilities.
  detrend if bool_detrend=true, then returns var over the last axis (time)
  • With the current setup (Todo #1 makes T=1), this returns a zero variance; for new cross-sectional
  moments you’ll want to swap this to a cross-sectional or bilateral aggregation



How results are assembled

• A DataFrame stats is initialized with columns per scenario and derived columns:
 • Scenario columns (DataFrame columns): actual, no_usa (and legacy columns if present)
 • Each scenario column is assigned per-country statistics:
  • stats[!, symbol_name] = dropdims(calculate_volatilities(...), dims=(1,3,4))
  • symbol_name is the folder name at that directory depth (e.g., :actual or :no_usa)

• Derived columns (currently configured for the old paper’s decomposition):
 • trade_barriers, diversification, specialization are computed as percentage differences based on
 specific scenario columns
 • These will need updating for your new moment and new scenarios (e.g., replace kappa1972 logic)


How the table is written

• The table is written to CSV at:
 • path: rootpath * "/output_table.csv"
 • For baseline, that’s experiments/baseline/output_table.csv
• The driving script is table.jl:
 • It sets minimal parameters and calls:
  • ImpvolOutput.write_results(parameters, ARGS[1], :real_GDP, true)
 • The Makefile calls table.jl with the experiment directory as argument:
  • experiments/%/output_table.csv: ...; julia --project table.jl $(dir $@)



What to change to compute your new moment

• Pick or construct your moment inside write_results:
 • Instead of calculate_volatilities, compute your new statistic from series
 • Examples:
  • Cross-sectional mean or weighted sum at t=1: mean(series[:,:,:,1], dims=(2,3))
  • Bilateral statistic by country-pair, then reduce to country-level
  • Any function of results[t][2] existing keys like :real_GDP, :w_njs, :P_njs, :E_mjs

• Populate both scenario columns explicitly:
 • stats.actual = <your_moment from experiments/baseline/actual>
 • stats.no_usa = <your_moment from experiments/baseline/no_usa>
• If you still need the decomposition columns, redefine them accordingly or remove them from the
DataFrame

Quick reference to useful helpers

• read_results(path): loads JLD2 “results”
• sort_results(results): sorts by time index
• make_series(results, key): stacks key across t, returns 4D array (m, n, j, t)
• calculate_volatilities(x, parameters, bool_detrend, range=:): detrend + variance over time
• Table writer: CSV.write(rootpath * "/output_table.csv", stats)

If you want, I can implement a new moment computation (e.g., country-level change in real_GDP between
actual and no_usa at t=1), wire it into output.jl, and update table.jl to reflect the new outputs.