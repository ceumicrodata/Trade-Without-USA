# Implementation Plan for Todo #2: Static Model Configuration

## Overview
Transform the dynamic stochastic model into a static deterministic model by removing random shocks, adjustment costs, and forward-looking expectations. This simplifies the model to focus on comparative static analysis between scenarios.

## Current vs Target State

### Current state:
- **Random shocks**: S = 101 states (stochastic productivity shocks)
- **Adjustment costs**: one_over_rho = 0.0 (infinite adjustment cost, no reallocation)
- **Dynamic equilibrium**: Forward-looking expectations over multiple states
- **Time dynamics**: Although T=1 now, model still has stochastic elements

### Target state:
- **No random shocks**: S = 1 (single deterministic state)
- **No adjustment costs**: one_over_rho = very large (instant adjustment)

## Step-by-Step Implementation

### Step 1: Understanding Current Parameter Structure

#### Files to modify:
- `experiments/config.jl` - Sets S = 101 by default
- `experiments/baseline/init_parameters.jl` - Sets one_over_rho = 0.0
- All scenario files that loop over states

#### Current behavior:
- Model solves for expected values over 101 possible productivity realizations
- Labor cannot adjust (one_over_rho = 0.0 means infinite adjustment cost)
- Equilibrium involves forward-looking expectations

### Step 2: Modify experiments/config.jl

#### 2.1 Set single state (S=1):
```julia
# Change from:
if !haskey(parameters, :S)
    parameters[:S] = 101
end

# To:
if !haskey(parameters, :S)
    parameters[:S] = 1  # Single state for static model
end
```

#### 2.2 Remove random seed (no longer needed):
```julia
# Comment out or remove:
# Random.seed!(1499)  # Not needed for deterministic model
```

### Step 3: Modify experiments/baseline/init_parameters.jl

#### 3.1 Enable instant adjustment:
```julia
# Change from:
parameters[:one_over_rho] = 0.0  # No adjustment

# To:
parameters[:one_over_rho] = 1000.0  # Very large = instant adjustment
# Note: Using large finite value instead of Inf to avoid numerical issues
```

### Step 4: Simplify Equilibrium Computation

#### 4.1 Check equilibrium.jl for state loops:
- Verify that S=1 simplifies the expected value calculations
- Expected value functions should collapse to single values
- No need for probability distributions over states

#### 4.2 Modify scenario execution (in scenario.jl files):
```julia
# Current parallel execution over time:
@time results = pmap(t -> (t, ImpvolEquilibrium.period_wrapper(parameters, t)), 1:parameters[:T])

# With T=1 and S=1, this becomes a single computation:
@time results = [(1, ImpvolEquilibrium.period_wrapper(parameters, 1))]
```

### Step 5: Remove Stochastic Elements

#### 5.1 Productivity shocks:
- Check for `nu_njt` or productivity shock parameters
- With S=1, these should be constant (no variation across states)

#### 5.2 Variance calculations:
- Remove variance/covariance calculations

### Step 6: Testing Strategy

#### 6.1 Create test script `scrap/test_static_model.jl`:
```julia
include("../experiments/baseline/init_parameters.jl")

println("Static Model Configuration Test")
println("================================")
println("S (states):        ", parameters[:S], " (should be 1)")
println("one_over_rho:      ", parameters[:one_over_rho], " (should be large)")
println("T (time periods):  ", parameters[:T], " (should be 1)")

# Test that equilibrium can be computed
include("../equilibrium.jl")
using .ImpvolEquilibrium

# Run single period equilibrium
t = 1
results = ImpvolEquilibrium.period_wrapper(parameters, t)

println("\nEquilibrium computed successfully!")
println("Number of results: ", length(results))
```

### Step 7: Validation Checklist

- [ ] S = 1 in experiments/config.jl
- [ ] one_over_rho = large value in init_parameters.jl
- [ ] No random seed setting
- [ ] Equilibrium computes without errors
- [ ] Results are deterministic (no randomness)
- [ ] Computation is faster (no state loops)
- [ ] Results are identical across multiple runs

### Step 8: Implementation Order

1. **Backup current configuration**: Save current parameter files
2. **Modify experiments/config.jl**: Set S=1
3. **Modify experiments/baseline/init_parameters.jl**: Set large one_over_rho
4. **Test equilibrium computation**: Run test script
5. **Verify deterministic results**: Run twice, compare outputs
6. **Update documentation**: Note static model configuration

## Expected Outcomes

### Computational benefits:
- Faster computation (1 state vs 101 states)
- Deterministic results (reproducible without seeds)
- Simpler debugging (no stochastic variation)

### Model interpretation:
- Pure comparative statics
- No uncertainty or risk considerations
- Instant adjustment to shocks
- Focus on long-run equilibrium differences

## Potential Issues and Solutions

### Issue 1: Numerical instability with one_over_rho = Inf
**Solution**: Use large finite value (e.g., 1000.0 or 10000.0)

### Issue 2: Code expects multiple states
**Solution**: Ensure array dimensions handle S=1 correctly

### Issue 3: Expected value calculations
**Solution**: With S=1, E[X] = X (no averaging needed)

## Notes

- This configuration makes the model purely static and deterministic
- Suitable for analyzing long-run effects of trade policy changes
- Removes business cycle and uncertainty considerations
- Focus shifts to comparative advantage and trade patterns
