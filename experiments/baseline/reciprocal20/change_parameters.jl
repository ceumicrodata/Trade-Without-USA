# parameters that govern counterfactual
include("../../../utils.jl")
parameters[:kappa_mnjt][25,:,:,:] .= parameters[:kappa_mnjt][25,:,:,:] ./ 1.20
parameters[:kappa_mnjt][:,25,:,:] .= parameters[:kappa_mnjt][:,25,:,:] ./ 1.20
