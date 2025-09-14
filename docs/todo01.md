# Implementation Plan for Todo #1: Time Period Modification (2003-2007)

## Overview
Transform the current time-series data (1972-2007, 36 years) to focus only on 2003-2007 (5 years) and create a cross-sectional average for static analysis.

## Current vs Target State

### Current state:
- Time dimension: 36 years (1972-2007)
- Countries: 25 (with USA as index 25)
- Sectors: 24 (agriculture, 22 manufacturing, services)
- Data arrays are 4D: (m, n, j, t) where t=36

### Target state:
- Time dimension: 1 (average of 2003-2007)
- Same countries and sectors
- Keep data arrays 4D, but with t=1

## Step-by-Step Implementation

### Step 1: Data Structure Analysis

#### Files requiring time filtering (contain year column):
- `beta_panel.txt` - (36,25,24) → (1,25,24)
- `aggregate_price_relative_to_US.csv` - (36,25) → (1,25)
- `sectoral_value_added.csv` - (36,25,24) → (1,25,24)
- `trade_balance_new.csv` - (25,36) → (25,1)
- `sectoral_price_index.csv` - (36,18,24) → (1,18,24)
- `import_share.txt` - (24,25,36,23) → (24,25,1,23) [special case]

#### Files without time dimension (unchanged):
- `country_name.txt` - (25,)
- `oecd_io_values.csv` - (34,34,13)
- `oecd_total_output.csv` - (34,13)
- `output_shares.csv` - (13,10)
- `intermediate_input_shares.csv` - (13,10)

### Step 2: Modify `read_data.jl`

#### 2.1 Add helper functions after line 3:
```julia
function year_to_index(year)
    return year - 1971  # 1972 is index 1, so 2003 is index 32
end

function filter_and_average_years(data, time_dim, year_start=2003, year_end=2007)
    # Get indices for years 2003-2007 (indices 32-36)
    start_idx = year_to_index(year_start)
    end_idx = year_to_index(year_end)
    
    # Select the appropriate slice based on which dimension is time
    if time_dim == 1
        filtered = data[start_idx:end_idx, :, :, :]
        averaged = mean(filtered, dims=1)
    elseif time_dim == 2
        filtered = data[:, start_idx:end_idx, :, :]
        averaged = mean(filtered, dims=2)
    elseif time_dim == 3
        filtered = data[:, :, start_idx:end_idx, :]
        averaged = mean(filtered, dims=3)
    elseif time_dim == 4
        filtered = data[:, :, :, start_idx:end_idx]
        averaged = mean(filtered, dims=4)
    end

    # Verify that the output has 4 dimensions
    @assert ndims(averaged) == 4

    return averaged
end
```

#### 2.2 Modify data loading calls (lines 89-99):

**Original line 89:**
```julia
pwt = read_data("data/aggregate_price_relative_to_US.csv",(36,25),[false,true,false,true],[2,1],',',false,2,false,true)
```
**Modified:**
```julia
pwt_full = read_data("data/aggregate_price_relative_to_US.csv",(36,25),[false,true,false,true],[2,1],',',false,2,false,true)
pwt = filter_and_average_years(pwt_full, 1)  # Time is dimension 1
```

**Original line 91:**
```julia
beta = read_data("data/beta_panel.txt",(36,25,24),[false,true,true,true],[2,3,1],'\t',true,2,false,true)
```
**Modified:**
```julia
beta_full = read_data("data/beta_panel.txt",(36,25,24),[false,true,true,true],[2,3,1],'\t',true,2,false,true)
beta = filter_and_average_years(beta_full, 1)  # Time is dimension 1
```

**Continue for all time-series data...**

### Step 3: Update Experiment Configuration

#### 3.1 Modify `experiments/config.jl`:
- Ensure `parameters[:T] = 1` instead of 36
- Update any loops or calculations that assume T=36
- Omit loops that iterate over time dimension

#### 3.2 Check `calibrate_params.jl`:
- Look for hardcoded time assumptions
- Verify calibration works with T=1
- Omit loops that iterate over time dimension

### Step 4: Update Makefile

Simplify Makefile to focus on baseline experiment:
- Remove references to other experiments
- Keep only baseline and no_usa targets

### Step 5: Testing Strategy

#### 5.1 Create validation script `test_data_filter.jl`:
```julia
include("read_data.jl")
using Test
using Statistics

# Test that time dimension is 1
@test size(beta, 1) == 1
@test size(pwt, 1) == 1
@test size(va, 1) == 1

# Test that values are reasonable (non-zero, no NaN)
@test !any(isnan, beta)
@test !any(isnan, pwt)
@test mean(beta) > 0

println("All data filtering tests passed!")
```

#### 5.2 Run existing tests:
```bash
julia --project system_test.jl
julia --project unit_test.jl
```

### Step 6: Implementation Checklist

- [ ] Create backup: `cp data/impvol_data.jld2 data/impvol_data_full_backup.jld2`
- [ ] Create git branch: `git checkout -b limit-years-2003-2007`
- [ ] Add filter functions to `read_data.jl`
- [ ] Modify each data loading call
- [ ] Update dimension specifications
- [ ] Run `julia --project read_data.jl` to generate new data file
- [ ] Verify new `data/impvol_data.jld2` has correct dimensions
- [ ] Update `experiments/config.jl` for T=1
- [ ] Run `julia --project test_data_filter.jl`
- [ ] Run `julia --project system_test.jl`
- [ ] Test calibration with `make calibrate`
- [ ] Commit changes with descriptive message

### Step 7: Validation Points

1. **Dimension Check**: All time dimensions should be 1
2. **Value Check**: Averaged values should be mathematically correct
3. **Completeness Check**: No missing data for 2003-2007 period
4. **Calibration Check**: Model should still calibrate successfully

### Step 8: Rollback Plan

If issues arise:
1. Restore backup: `cp data/impvol_data_full_backup.jld2 data/impvol_data.jld2`
2. Document issues for debugging

## Notes

- Years 2003-2007 correspond to indices 32-36 in the data (1972 = index 1)
- The `import_share.txt` file may need special handling due to its structure
- Some OECD data files don't have time dimension and remain unchanged
- Ensure Julia's `Statistics` package is available for `mean` function

---
# Results
## Summary

I have successfully implemented Todo #1: Time Period Modification (2003-2007). Here's what was
accomplished:

### ✅ Completed Tasks:

1. Added filter functions to read_data.jl:
 • year_to_index() to convert years to array indices
 • filter_and_average_years() to extract 2003-2007 data and average
2. Modified data loading to filter and average years 2003-2007:
 • All time-series data now has T=1 (single time period)
 • Data represents the average of 2003-2007 period
 • Non-time-series data remains unchanged
3. Validated the transformation:
 • Time dimensions successfully reduced from 36 to 1
 • Data dimensions preserved for countries (25) and sectors (24)
 • No NaN values introduced
4. Automatic T=1 configuration:
 • The calibration process automatically detects T=1 from the filtered data
 • No manual configuration needed in experiments/config.jl


### Key Results:

• Before: Time dimension = 36 years (1972-2007)
• After: Time dimension = 1 (average of 2003-2007)

### Data Dimensions After Filtering:

• pwt: (1, 25, 1, 1) - was (1, 25, 1, 36)
• beta: (1, 25, 24, 1) - was (1, 25, 24, 36)
• va: (1, 25, 24, 1) - was (1, 25, 24, 36)
• import_shares: (25, 25, 24, 1) - was (25, 25, 24, 36)
• trade_balance: (1, 25, 1, 1) - was (1, 25, 1, 36)
• p_sectoral_data: (1, 18, 24, 1) - was (1, 18, 24, 36)

The model is now configured to work with cross-sectional data averaged over 2003-2007, ready for
static analysis without time dynamics.

## Tests
```bash
julia +1.10 --project=. scrap/verify_filtered_data.jl
```