include("../calibrate_params.jl")
using .CalibrateParameters

println("Testing calibration with filtered data...")

# Create a parameters dictionary
parameters = Dict{Symbol, Any}()

# Set some required parameters
parameters[:sigma] = 0.999
parameters[:theta] = 4.0
parameters[:eta] = 4.0
parameters[:S] = 1  # Single state for static model

# Run calibration (it will load from data/impvol_data.jld2)
CalibrateParameters.calibrate_parameters!(parameters)

# Check what T was detected
println("\nCalibration complete!")
println("Detected dimensions:")
println("  N (countries): ", parameters[:N])
println("  J (sectors):   ", parameters[:J])
println("  T (time):      ", parameters[:T])
println("  S (states):    ", parameters[:S])

if parameters[:T] == 1
    println("\n✓ Calibration correctly detected T=1 from filtered data")
else
    println("\n✗ ERROR: T should be 1 but is ", parameters[:T])
end