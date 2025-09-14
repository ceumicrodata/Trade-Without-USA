# Scope

- Replace time-variance moments with cross-sectional means at t=1.
- Compute three country-level moments per scenario:
  - GDP
  - total exports
  - total imports
- Populate columns for both scenarios: actual and no_usa.

# Where to hook changes

- File: output.jl (module ImpvolOutput)
- Function: write_results(parameters, rootpath, key, bool_detrend, dirsdown, pattern)
- Helper: make_series(results, key) already stacks desired key across time, returning a 4D array (m,n,j,t) with s collapsed.

# Data availability in results

- GDP: results[t][2][:real_GDP] is available (computed by compute_real_gdp!)
- Exports and imports derive from trade shares and expenditures:
 - random_variables keys in equilibrium:
  - :E_mjs (importer m’s nominal expenditure by sector)
  - :d_mnjs (trade shares, destination m importing from source n)
  - Prices are already deflated to US units via deflate_all_nominal_variables!, so nominal consistency
  holds across scenarios.

- Construct exports and imports:
 - Imports_m = sum over n,j of E_mjs[m,n,j] = sum_n sum_j E_mjs[m,n,j]
 - Exports_n = sum over m,j of E_mjs[m,n,j] = sum_m sum_j E_mjs[m,n,j]
 - Note: E_mjs has dims (m,n,j,1). With T=1, use [:,:,:,1].


# Exact computations

- For each scenario results:
 - Load results, sort, and extract series:
  - real_GDP_series = make_series(results, :real_GDP)  # (m,n,j,t) with GDP on n,j
   - Aggregate by country: GDP_n = sum(real_GDP_series[1, n, :, 1], dims=3) → drop dims → vector
   length N

 - Imports:
  - E_mjs_series = make_series(results, :E_mjs)        # (m,n,j,t)
  - Imports_m = sum(E_mjs_series[m, :, :, 1], dims=(2,3)) → vector length M=N
 - Exports:
  - Exports_n = sum(E_mjs_series[:, n, :, 1], dims=(1,3)) → vector length N

- “Total” here is a pure sum across sectors (and bilateral partners) since T=1:
 - total GDP by country: sum over sectors / J
 - total exports by country: sum over destinations, sectors / (N*J)
 - total imports by country: sum over sources, sectors / (N*J)


# Implementation steps

## 1. In output.jl, add scenario-wise extraction alongside existing loop:

- Replace calculate_volatilities with three new computations per scenario:
 - gdp_country = dropdims(sum(make_series(…,:real_GDP)[1, :, :, 1], dims=3), dims=3)
 - E = make_series(…,:E_mjs)
 - imports_country = dropdims(sum(E[:, :, :, 1], dims=(2,3)), dims=(2,3))  # sum over partner n and sector j for each m
 - exports_country = dropdims(sum(E[:, :, :, 1], dims=(1,3)), dims=(1,3))  # sum over destination m and sector j for each n

## 2. Build the stats DataFrame schema

- Columns:
 - country_names
 - gdp_actual, gdp_no_usa
 - exports_actual, exports_no_usa
 - imports_actual, imports_no_usa
- Remove legacy volatility/decomposition columns (trade_barriers, diversification, specialization)

## 3. Scenario assignment

- For each scenario folder under experiments/baseline/ (actual, no_usa):
 - Compute vectors for gdp_country, exports_country, imports_country
 - Assign to columns by scenario suffix.


## 4. Table writing

- CSV.write(rootpath * "/output_table.csv", stats)
- Ensure table.jl still calls write_results(parameters, ARGS[1], :real_GDP, false)
 - bool_detrend not needed now; set false or ignore the parameter
 - key argument is irrelevant if you compute all three keys inside write_results


## 5. Sanity checks

- Dimensions: All vectors length N=25
- Units: All values in US-deflated nominal units (consistent across scenarios)
- With USA index 25, check large changes under no_usa


# Minimal code sketch (inside write_results)

- real_GDP:
 - gdp_series = make_series(sorted_results, :real_GDP)   # (1,N,J,1)
 - gdp_country = vec(dropdims(sum(gdp_series[1, :, :, 1], dims=2), dims=2))  # size N
- E_mjs:
 - E = make_series(sorted_results, :E_mjs)               # (M,N,J,1)
 - imports_m = vec(dropdims(sum(E[:, :, :, 1], dims=(2,3)), dims=(2,3)))     # M=N
 - exports_n = vec(dropdims(sum(E[:, :, :, 1], dims=(1,3)), dims=(1,3)))     # N


# Deliverable impact

- Produces a single CSV per experiment with per-country columns for actual and no_usa across three metrics.
- No time variance, consistent with T=1 static cross-section.