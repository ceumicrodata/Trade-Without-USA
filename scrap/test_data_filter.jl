using Test
using Statistics

# Run the filtered data loading
include("read_data_filtered.jl")

println("\n=== VALIDATION TESTS ===")

# Test that time dimension is 1 for all time-series data
@test size(beta, 4) == 1
@test size(pwt, 4) == 1
@test size(va, 4) == 1
@test size(import_shares, 4) == 1
@test size(trade_balance, 4) == 1
@test size(p_sectoral_data, 4) == 1

println("✓ All time dimensions are 1")

# Test that values are reasonable (non-zero, no NaN)
@test !any(isnan, beta)
@test !any(isnan, pwt)
@test !any(isnan, va)
@test mean(beta) > 0
@test mean(va) > 0

println("✓ No NaN values, data is non-zero")

# Test that the other dimensions are preserved
@test size(beta, 2) == 25  # Countries
@test size(beta, 3) == 24  # Sectors
@test size(import_shares, 1) == 25  # Importers
@test size(import_shares, 2) == 25  # Exporters

println("✓ Country and sector dimensions preserved")

# Test non-time-series data is unchanged
@test length(country_names) == 25
@test size(io_values, 1) == 34
@test size(io_values, 2) == 34

println("✓ Non-time-series data unchanged")

println("\n=== ALL VALIDATION TESTS PASSED ===")
println("\nSummary of filtered data dimensions:")
println("  beta: ", size(beta), " (was (1,25,24,36))")
println("  pwt: ", size(pwt), " (was (1,25,1,36))")
println("  va: ", size(va), " (was (1,25,24,36))")
println("  import_shares: ", size(import_shares), " (was (25,25,24,36))")
println("  trade_balance: ", size(trade_balance), " (was (1,25,1,36))")
println("  p_sectoral_data: ", size(p_sectoral_data), " (was (1,18,24,36))")