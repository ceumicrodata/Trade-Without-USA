using CSV
using DataFrames
using Statistics
using FileIO

# Include the filtering functions and data loading
include("read_data_filtered.jl")

# Try to save as JLD2
println("\nAttempting to save filtered data...")

try
    using JLD2
    save("data/impvol_data.jld2", "beta", beta, "pwt", pwt, "va", va, 
         "import_shares", import_shares, "io_values", io_values, 
         "total_output", total_output, "output_shares", output_shares, 
         "intermediate_input_shares", intermediate_input_shares, 
         "trade_balance", trade_balance, "p_sectoral_data", p_sectoral_data)
    println("✓ Data successfully saved to data/impvol_data.jld2")
catch e
    println("JLD2 failed, trying alternative save method...")
    
    # Save as binary files using Julia's serialization
    using Serialization
    
    data_dict = Dict(
        "beta" => beta,
        "pwt" => pwt,
        "va" => va,
        "import_shares" => import_shares,
        "io_values" => io_values,
        "total_output" => total_output,
        "output_shares" => output_shares,
        "intermediate_input_shares" => intermediate_input_shares,
        "trade_balance" => trade_balance,
        "p_sectoral_data" => p_sectoral_data
    )
    
    serialize("data/impvol_data.jls", data_dict)
    println("✓ Data saved to data/impvol_data.jls using Julia serialization")
    
    # Also create a compatibility wrapper
    open("data/load_data.jl", "w") do f
        write(f, """
        # Compatibility wrapper for loading filtered data
        using Serialization
        
        function load_filtered_data()
            return deserialize("data/impvol_data.jls")
        end
        
        # For compatibility with code expecting JLD2
        function load(fname::String)
            if endswith(fname, ".jls")
                return deserialize(fname)
            else
                # Assume it's asking for the main data file
                return deserialize("data/impvol_data.jls")
            end
        end
        """)
    end
    println("✓ Created data/load_data.jl compatibility wrapper")
end