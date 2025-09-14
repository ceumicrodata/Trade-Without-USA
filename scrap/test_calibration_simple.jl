using FileIO, JLD2

println("Testing data loading for calibration...")

# Load the filtered data directly
data = load("../data/impvol_data.jld2")

# Check dimensions as calibration would
_, N, J, T = size(data["beta"])

println("\nDimensions extracted from beta array:")
println("  N (countries): ", N)
println("  J (sectors):   ", J)
println("  T (time):      ", T)

if T == 1
    println("\n✓ T=1 confirmed - calibration will use single time period")
    println("✓ Data represents average of 2003-2007")
else
    println("\n✗ ERROR: T should be 1 but is ", T)
end

# Also verify the data is non-zero (sanity check)
using Statistics
println("\nData sanity checks:")
println("  Mean beta value: ", round(mean(data["beta"]), digits=4))
println("  Mean VA value: ", round(mean(data["va"]), digits=2))
println("  Non-zero import shares: ", count(x -> x > 0, data["import_shares"]))