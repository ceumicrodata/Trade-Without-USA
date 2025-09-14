include("read_data.jl")

println("Testing import_shares loading...")
println("import_shares dimensions: ", size(import_shares_full))
println("Import shares should have dimensions (m,n,j,t) = (25,25,24,36)")
println("But the loaded dimensions suggest time is in position 3")