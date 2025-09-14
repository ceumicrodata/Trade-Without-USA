module ImpvolOutput
	using JLD2
	using FileIO
	using CSV
	using Missings
	using Plots
	using HypothesisTests
	using Distributions
	using DataFrames
	using Logging
	using FilePathsBase

	include("calibration_utils.jl")
	global_logger(ConsoleLogger(stderr, Logging.Debug))

	function read_results(path = "experiments/baseline/actual/results.jld2")
		file = jldopen(path, "r")
		return file["results"]
	end

	function list_keys(results)
		for (key, value) in results[1][2]
			println(key)
		end
	end

	function make_series(results, key = :real_GDP)
		# Only the first element in the shock dimension is interesting, the rest are there only for optimizaton purposes used in the algorithm
		return results[key][:,:,:,1]
	end

	function calculate_volatilities(x, parameters, bool_detrend::Bool, range=:)
		if bool_detrend
			x_c, x_t = DetrendUtilities.detrend(log.(x),parameters[:bp_weights])
		else
			x_c = log.(x)
		end

		# time is the last dimension
		return var(x_c[:,:,:,range],dims=ndims(x_c))
	end

	function plot_model_vs_data(plot_data::Tuple, title::String)
		# data and model are expected to be of dimension N x T
		# length of label should be equal N
		data = plot_data[1]
		model = plot_data[2]
		label = plot_data[3]

		data = permutedims(data,(2,1))
		model = permutedims(model,(2,1))

		size(data,2) == size(model,2) || error("You can only compare matching time series between the model outcome and data")

		colors = distinguishable_colors(size(data,2))

		ENV["GKSwstype"] = "gksqt"
		fig = Plots.plot()
		for i in 1:size(data,2)
			Plots.plot!([data[:,i] model[:,i]], color = colors[i,1], ls = [:solid :dash], label = [label[i,1] ""], title = title)
		end
		return fig
	end


	function plot_data(path = "experiments/baseline/actual/results.jld2", key = :real_GDP, country_range = ":")
		# output: "data, model, label", as an input for the function 'plot_model_vs_data'
		data = load("data/impvol_data.jld2")
		gdp_d = squeeze(sum(data["va"],3), (1,3))
		gdp_d = Float64.(collect(Missings.replace(gdp_d, NaN)))
		gdp_d = gdp_d[eval(parse(country_range)),:]

		pwt = squeeze(data["pwt"], (1,3))
		pwt = Float64.(collect(Missings.replace(pwt, NaN)))
		pwt = pwt[eval(parse(country_range)),:]

		cpi = CSV.read("data/cpi.csv", header = true)
		cpi = permutedims(convert(Array, cpi)[:,2:end], (2,1))
		cpi = cpi ./ cat(2, cpi[:,24]) # 24 = 1995-base
		cpi = Float64.(collect(Missings.replace(cpi, NaN)))
		cpi = cpi[eval(parse(country_range)),:]

		xr = CSV.read("data/exchange_rates.csv", header = true)
		xr = permutedims(convert(Array, xr)[:,2:end], (2,1))
		xr = Float64.(collect(Missings.replace(xr, NaN)))
		xr = xr[eval(parse(country_range)),:]

		country_names = CSV.read("data/country_name.txt", header = false, types = [String])
		country_names = country_names[:1][eval(parse(country_range))]

		results = sort_results(read_results(path))
		gdp_m = make_series(results, key)
		gdp_m = sum(gdp_m[1,eval(parse(country_range)),:,:],2)
		gdp_m = squeeze(gdp_m, 2)

		gdp_d = gdp_d ./ cpi .* xr
		#gdp_d = gdp_d ./ pwt

		# normalization: model(1972) = data(1972)
		gdp_m = gdp_m .* (gdp_d[:,1] ./ gdp_m[:,1])

		return log.(gdp_d), log.(gdp_m), country_names
	end

	################ Running the 'plot_data' function ################
	# include("output.jl")
	# plt_dta = ImpvolOutput.plot_data() # with the desired arguments if needed
	# Base.print_matrix(IOContext(STDOUT, :limit => false), plt_dta[3]) # to check the countries' position
	# idx = zeros(length(plt_dta[3]))
	# idx[6], idx[10], idx[11], idx[13], idx[15], idx[16], idx[24], idx[25] = 1, 1, 1, 1, 1, 1, 1, 1
	# idx = idx .== 1
	# ImpvolOutput.plot_model_vs_data((plt_dta[1][idx,:], plt_dta[2][idx,:], plt_dta[3][idx]), "GDP")
	# # solid line = data, dashed line = model
	##################################################################


	function write_results(parameters, rootpath = "experiments/baseline/", key = :real_GDP, bool_detrend = true, dirsdown = 1, pattern = r"jld2$")
		# Cross-sectional moments at t=1 for each scenario
		# Read country names
		country_names = CSV.read("data/country_name.txt", DataFrame; header = false, types = [String])
		println("Dimensions of country_names: ", size(country_names))

		# Create 'stats' DataFrame with new schema for cross-sectional moments
		stats = DataFrame(
			country_names = country_names[!, 1],
			gdp_actual = Vector{Float64}(undef, size(country_names, 1)),
			gdp_no_usa = Vector{Float64}(undef, size(country_names, 1)),
			exports_actual = Vector{Float64}(undef, size(country_names, 1)),
			exports_no_usa = Vector{Float64}(undef, size(country_names, 1)),
			imports_actual = Vector{Float64}(undef, size(country_names, 1)),
			imports_no_usa = Vector{Float64}(undef, size(country_names, 1))
		)
		println("Dimensions of stats: ", size(stats))

		# Fill 'stats' DataFrame with cross-sectional moments
		for col in ["actual", "no_usa"]
			results = read_results(joinpath(rootpath, col, "results.jld2"))

			# Compute GDP by country (sum over sectors)
			gdp_series = make_series(results, :real_GDP)  # (1,N,J,S)
			gdp_country = sum(gdp_series[1, :, :], dims=2)[:]  # sum over sectors j for each country n

			# Compute exports and imports from E_mjs (expenditures)
			E = make_series(results, :E_mjs)  # (M,1,J) where M=importers, N=exporters
			D = make_series(results, :d_mnjs)  # (M,N,J) where M=importers, N=exporters, J=sectors, import shares
			# exclucde own country from imports
			for n = 1:parameters[:N]
				D[n, n, :] .= 0.0
			end
			# FIXME: no, E is expenditure, we have to compute exports and imports from that
			imports_country = sum(E .* D, dims=(2,3))[:]  # sum over sectors j and exporters n for each importer m
			exports_country = sum(E .* D, dims=(1,3))[:]  #

			# Assign to appropriate columns
			if col == "actual"
				stats[!, :gdp_actual] = gdp_country
				stats[!, :exports_actual] = exports_country
				stats[!, :imports_actual] = imports_country
			elseif col == "no_usa"
				stats[!, :gdp_no_usa] = gdp_country
				stats[!, :exports_no_usa] = exports_country
				stats[!, :imports_no_usa] = imports_country
			end
			# round all variables to integer
			stats[!, :gdp_actual] = round.(stats.gdp_actual)
			stats[!, :gdp_no_usa] = round.(stats.gdp_no_usa)
			stats[!, :exports_actual] = round.(stats.exports_actual)
			stats[!, :exports_no_usa] = round.(stats.exports_no_usa)
			stats[!, :imports_actual] = round.(stats.imports_actual)
			stats[!, :imports_no_usa] = round.(stats.imports_no_usa)			
		end

		# compute percentage change relative to actual
		# round to 1 decimal place
		stats[!, :gdp_pct_change] = round.(100 * (stats.gdp_no_usa .- stats.gdp_actual) ./ stats.gdp_actual, digits=1)
		stats[!, :exports_pct_change] = round.(100 * (stats.exports_no_usa .- stats.exports_actual) ./ stats.exports_actual, digits=1)
		stats[!, :imports_pct_change] = round.(100 * (stats.imports_no_usa .- stats.imports_actual) ./ stats.imports_actual, digits=1)

		@debug stats

		CSV.write(rootpath * "/output_table.csv", stats)
	end
	

	################ Running the 'write_results' function ################
	# include("output.jl")
	# parameters = Dict{Symbol, Any}()
	# parameters[:N] = 25
	# parameters[:bp_weights] = [0.774074394803123, -0.201004684236153, -0.135080548288772,-0.050951964876636]
	# stats = ImpvolOutput.write_results(parameters)
	######################################################################


end

