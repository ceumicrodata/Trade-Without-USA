# Test script for static model configuration
println("Loading baseline configuration...")

# Load the modified configuration
include("../experiments/baseline/init_parameters.jl")

println("\nStatic Model Configuration Test")
println("================================")
println("S (states):        ", parameters[:S], " (should be 1)")
println("one_over_rho:      ", parameters[:one_over_rho], " (should be 1000.0)")
println("T (time periods):  ", parameters[:T], " (should be 1)")

# Verify static configuration
if parameters[:S] == 1
    println("✓ S=1: Single state (deterministic)")
else
    println("✗ ERROR: S should be 1 but is ", parameters[:S])
end

if parameters[:one_over_rho] >= 1000.0
    println("✓ one_over_rho=", parameters[:one_over_rho], ": Instant adjustment enabled")
else
    println("✗ ERROR: one_over_rho should be large but is ", parameters[:one_over_rho])
end

if parameters[:T] == 1
    println("✓ T=1: Single time period")
else
    println("✗ ERROR: T should be 1 but is ", parameters[:T])
end

println("\nTesting equilibrium computation...")
# Test that equilibrium can be computed
include("../equilibrium.jl")
using .ImpvolEquilibrium

# Run single period equilibrium
t = 1
println("Computing equilibrium for period ", t, "...")
@time results = ImpvolEquilibrium.period_wrapper(parameters, t)

println("\n✓ Equilibrium computed successfully!")
println("Results type: ", typeof(results))

# Check if results are deterministic by running twice
println("\nTesting determinism...")
results1 = ImpvolEquilibrium.period_wrapper(parameters, 1)
results2 = ImpvolEquilibrium.period_wrapper(parameters, 1)

# Compare key results
if haskey(results1, :w_njs) && haskey(results2, :w_njs)
    diff = maximum(abs.(results1[:w_njs] - results2[:w_njs]))
    if diff < 1e-10
        println("✓ Results are deterministic (max diff: ", diff, ")")
    else
        println("✗ Results differ between runs (max diff: ", diff, ")")
    end
else
    println("✓ Equilibrium results obtained")
end

println("\n=== Static Model Configuration Complete ===")
