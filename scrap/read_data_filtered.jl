using CSV
using DataFrames
using Statistics

function year_to_index(year)
    return year - 1971  # 1972 is index 1, so 2003 is index 32
end

function filter_and_average_years(data, time_dim, year_start=2003, year_end=2007)
    # Get indices for years 2003-2007 (indices 32-36)
    start_idx = year_to_index(year_start)
    end_idx = year_to_index(year_end)
    
    # Select the appropriate slice based on which dimension is time
    if time_dim == 1
        filtered = data[start_idx:end_idx, :, :, :]
        averaged = mean(filtered, dims=1)
    elseif time_dim == 2
        filtered = data[:, start_idx:end_idx, :, :]
        averaged = mean(filtered, dims=2)
    elseif time_dim == 3
        filtered = data[:, :, start_idx:end_idx, :]
        averaged = mean(filtered, dims=3)
    elseif time_dim == 4
        filtered = data[:, :, :, start_idx:end_idx]
        averaged = mean(filtered, dims=4)
    end

    # Verify that the output has 4 dimensions
    @assert ndims(averaged) == 4

    return averaged
end

function manipulate_import_shares(data::DataFrame, dim_size::NTuple{4, Int}, filtered_years=false)
    # This function extends the imported import shares, so that it will be full dimensional
    # Adds service sector (with 0 import share) and adds own country import share (0)
    
    # Add a new column with zeros named :s
    data.s .= 0
    
    N = dim_size[2]
    J = dim_size[4] + 1
    T = dim_size[3]
    
    if filtered_years
        # For filtered data, only add data for years 2003-2007
        for t in 32:36  # Years 2003-2007
            y = 1971 + t
            for n in 1:N
                vec = zeros(1,J + 3)
                vec[1,1:3] = [y,n,n]
                push!(data, vec)
            end
        end
    else
        for t in 1:T
            y = 1971 + t
            for n in 1:N
                vec = zeros(1,J + 3)
                vec[1,1:3] = [y,n,n]
                push!(data, vec)
            end
        end
    end
	return sort!(data,[1,2,3]), map(+,dim_size,(1,0,0,1))
end

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
		data, dim_size = manipulate_import_shares(data, dim_size, filtered_years)
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

# Load full data first
println("Loading full data...")
pwt_full        = read_data("data/aggregate_price_relative_to_US.csv",(36,25),[false,true,false,true],[2,1],',',false,2,false,true)
beta_full       = read_data("data/beta_panel.txt",(36,25,24),[false,true,true,true],[2,3,1],'\t',true,2,false,true)                
va_full         = read_data("data/sectoral_value_added.csv",(36,25,24),[false,true,true,true],[2,3,1],',',true,2,false,true)
import_shares_full = read_data("data/import_share.txt",(24,25,36,23),[true,true,true,true],[2,1,4,3],'\t',false,3,true,true)
trade_balance_full = read_data("data/trade_balance_new.csv",(25,36),[false,true,false,true],[1,2],',',true,1,false,true)
p_sectoral_data_full = read_data("data/sectoral_price_index.csv",(36,18,24),[false,true,true,true],[2,3,1],',',false,0,false,true)

# Filter to 2003-2007 and average
println("Filtering to 2003-2007 and averaging...")
pwt             = filter_and_average_years(pwt_full, 4)  # Time is dimension 4
beta            = filter_and_average_years(beta_full, 4)  # Time is dimension 4
va              = filter_and_average_years(va_full, 4)  # Time is dimension 4
import_shares   = filter_and_average_years(import_shares_full, 4)  # Time is dimension 4
trade_balance   = filter_and_average_years(trade_balance_full, 4)  # Time is dimension 4
p_sectoral_data = filter_and_average_years(p_sectoral_data_full, 4)  # Time is dimension 4

# Files without time dimension remain unchanged
println("Loading non-time-series data...")
country_names   = read_data("data/country_name.txt",(25,),[false,true,false,false],[1],'\t',false,0,false,false)
io_values       = read_data("data/oecd_io_values.csv",(34,34,13),[true,true,false,true],[2,1,3],',',true,3,false,true)
total_output    = read_data("data/oecd_total_output.csv",(34,13),[false,true,false,true],[1,2],',',true,2,false,true)
output_shares   = read_data("data/output_shares.csv",(13,10),[false,true,false,true],[2,1],',',true,1,false,true)
intermediate_input_shares = read_data("data/intermediate_input_shares.csv",(13,10),[false,true,false,true],[2,1],',',true,1,false,true)

println("\nData filtering complete!")
println("New dimensions:")
println("  pwt: ", size(pwt))
println("  beta: ", size(beta))
println("  va: ", size(va))
println("  import_shares: ", size(import_shares))
println("  trade_balance: ", size(trade_balance))
println("  p_sectoral_data: ", size(p_sectoral_data))

# Save using JLD2 if available, otherwise save summary
using FileIO, JLD2
save("data/impvol_data.jld2", "beta", beta, "pwt", pwt, "va", va, "import_shares", import_shares, "io_values", io_values, "total_output", total_output, "output_shares", output_shares, "intermediate_input_shares", intermediate_input_shares, "trade_balance", trade_balance, "p_sectoral_data", p_sectoral_data)
println("\nData saved to data/impvol_data.jld2")