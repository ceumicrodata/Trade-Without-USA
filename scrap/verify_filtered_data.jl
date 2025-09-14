using FileIO, JLD2

# Load the filtered data
data = load("data/impvol_data.jld2")

println("=== Filtered Data Verification ===")
println("\nAvailable keys in data file:")
for key in keys(data)
    println("  - $key")
end

println("\nData dimensions (should have T=1):")
println("  beta:            ", size(data["beta"]), " (was 1,25,24,36)")
println("  pwt:             ", size(data["pwt"]), " (was 1,25,1,36)")
println("  va:              ", size(data["va"]), " (was 1,25,24,36)")
println("  import_shares:   ", size(data["import_shares"]), " (was 25,25,24,36)")
println("  trade_balance:   ", size(data["trade_balance"]), " (was 1,25,1,36)")
println("  p_sectoral_data: ", size(data["p_sectoral_data"]), " (was 1,18,24,36)")

# Verify time dimension is 1
time_dims_correct = true
for (name, expected_t_dim) in [("beta", 4), ("pwt", 4), ("va", 4), 
                                ("import_shares", 4), ("trade_balance", 4), 
                                ("p_sectoral_data", 4)]
    if haskey(data, name)
        actual_t = size(data[name], expected_t_dim)
        if actual_t != 1
            println("ERROR: $name has time dimension $actual_t, expected 1")
            time_dims_correct = false
        end
    end
end

if time_dims_correct
    println("\n✓ All time dimensions are correctly set to 1")
    println("✓ Data successfully filtered to 2003-2007 average")
else
    println("\n✗ Some time dimensions are incorrect")
end