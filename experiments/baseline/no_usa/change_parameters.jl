include("../../../utils.jl")
parameters[:kappa_mnjt][25,:,:,:] .= ones(size(parameters[:kappa_mnjt][25,:,:,:])) ./ 100000
parameters[:kappa_mnjt][:,25,:,:] .= ones(size(parameters[:kappa_mnjt][:,25,:,:])) ./ 100000
parameters[:kappa_mnjt][25,25,:,:] .= ones(size(parameters[:kappa_mnjt][25,25,:,:]))
