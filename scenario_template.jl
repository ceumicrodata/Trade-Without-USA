# load ImpvolEquilibrium first so that methods are accessible
@everywhere include("../../../equilibrium.jl")
@everywhere using .ImpvolEquilibrium, Logging
@everywhere global_logger(ConsoleLogger(stderr, Logging.Info))

@everywhere using FileIO, JLD2
@everywhere parameters = load("../common_parameters.jld2")["parameters"]

# parameters that govern counterfactual
@everywhere include("change_parameters.jl")

@time results = ImpvolEquilibrium.period_wrapper(parameters, 1)
include("../../../save.jl")