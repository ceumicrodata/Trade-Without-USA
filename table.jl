include("output.jl")
using .ImpvolOutput
using FileIO, JLD2

# Usage: julia table.jl <rootpath> <scenario>
# Example: julia table.jl experiments/baseline/ no_usa

rootpath = ARGS[1]
scenario = ARGS[2]

# load file with parameters
parameters = load(rootpath * "common_parameters.jld2")["parameters"]
# add in N to allow the write_results() function to run without full parameters
parameters[:N] = 25
# no need for bp_weights since we're not detrending

ImpvolOutput.write_scenario_results(parameters, rootpath, scenario, :real_GDP, true)