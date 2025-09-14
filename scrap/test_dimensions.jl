using FileIO
using CSV
using DataFrames

function read_data(relativepath::String, dim_size::NTuple, in_pos::Array{Bool,1}, out_pos::Array{Int64,1}, delim::Char, header::Bool, drop::Int64, indic::Bool, convfloat::Bool, filtered_years=false)
	# relativepath - gives the relative path of the data to be imported
	# dim_size     - gives the size of each dimension the data should be stored in julia,
	#                their product should correspond to the number of datapoints in the dataset
	#                to be imported, order should be appropriate
	# in_pos       - gives existing dimensions in the input data matrix 
	#                corresponding to mnjt ordering notation as expected (but not restricted) in the output,
	#                its length nevertheless defines the dimensionality of the output matrix
	# out_pos      - gives the position of each dimension in the output matrix
	#                as in the order of argument 'dim_size',
	#                the order prefarabely corresponds to mnjt
	#                m - importer country, n - exporter country, j - sector, t - period
	# delim        - delimiter of the CSV.read command
	# header       - header of the CSV.read command
	# drop         - drop the first 'drop' number of columns in the input data matrix
	# indic        - indicator for reading import shares
	#
	# example: read_data("data/raw_imputed/beta_panel.txt",(36,25,24),[false,true,true,true],[2,3,1],'\t',true,2,false)

	length(dim_size) == count(in_pos) || error("Each dimension should be present in the input matrix")
	any(x -> x <= length(in_pos), out_pos) || error("The output matrix cannot be more than $(length(in_pos))-dimensional")
	unique(out_pos) == out_pos || error("Each output dimension should be unique")

	length(dim_size) == length(out_pos) || error("Each dimension should have its own output position and vice versa")

	data = CSV.read(relativepath, header = header, delim = delim, DataFrame)

	# Part purely for manipulating import shares
	if indic
		# Skip manipulation for now
	end
	# End of manipulation

	data = Matrix(data)
	if drop > 0
		data = data[:,(drop + 1):end]
	end
	prod(size(data)) == prod(dim_size) || error("The number of datapoints ($(prod(size(data)))) should match the product of elements in argument 'dim_size' ($(prod(dim_size)))")

	# Reshape the data according to dim_size
	data = reshape(data, dim_size)
	data = permutedims(data, out_pos)

	pos = (1:length(in_pos))[in_pos]
	new_size = [1, 1, 1, 1]
	for i in 1:length(dim_size)
		new_size[pos[i]] = dim_size[out_pos[i]]
	end

	data = reshape(data, new_size...)

	if convfloat
		data = collect(Missings.replace(data,NaN))
		data = convert(Array{Float64,length(in_pos)},data)
	end

	@debug "Data read successfully from $relativepath"
	@debug "Size of data is $(size(data))"

	return data
end

# Test loading and check dimensions
println("Loading pwt...")
pwt = read_data("data/aggregate_price_relative_to_US.csv",(36,25),[false,true,false,true],[2,1],',',false,2,false,true)
println("pwt dimensions: ", size(pwt))

println("\nLoading beta...")
beta = read_data("data/beta_panel.txt",(36,25,24),[false,true,true,true],[2,3,1],'\t',true,2,false,true)
println("beta dimensions: ", size(beta))

println("\nLoading va...")
va = read_data("data/sectoral_value_added.csv",(36,25,24),[false,true,true,true],[2,3,1],',',true,2,false,true)
println("va dimensions: ", size(va))

println("\nLoading trade_balance...")
trade_balance = read_data("data/trade_balance_new.csv",(25,36),[false,true,false,true],[1,2],',',true,1,false,true)
println("trade_balance dimensions: ", size(trade_balance))

println("\nLoading p_sectoral_data...")
p_sectoral_data = read_data("data/sectoral_price_index.csv",(36,18,24),[false,true,true,true],[2,3,1],',',false,0,false,true)
println("p_sectoral_data dimensions: ", size(p_sectoral_data))