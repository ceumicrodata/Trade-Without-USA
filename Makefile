.PHONY: data install tables template calibrate
CALIBRATION = calibrate_params.jl calibration_utils.jl experiments/config.jl data/impvol_data.jld2
EQULIBRIUM = utils.jl equilibrium.jl experiments/config.jl
COLUMNS = actual no_usa
# CES experiments removed
TABLES = baseline
.PRECIOUS: $(foreach table,$(TABLES),$(foreach column,$(COLUMNS),experiments/$(table)/$(column)/results.jld2))

# default number of Julia threads to use. otherwise `make tables PROCS=12`
PROCS = 1
JULIA = julia +1.10 --project -p$(PROCS)

tables: experiments/baseline/output_table.csv
# ces_tables removed

# this takes too long to run, only run if explicitly asked `make S500`
# S500 target removed

calibrate: $(foreach table,$(TABLES),experiments/$(table)/common_parameters.jld2) 

# CES-related targets removed

experiments/%/common_parameters.jld2: experiments/%/init_parameters.jl $(CALIBRATION) 
	cd $(dir $@) && $(JULIA) init_parameters.jl

define run_experiment
experiments/$(1)/%/results.jld2: $(EQULIBRIUM) experiments/$(1)/common_parameters.jld2 experiments/$(1)/%/scenario.jl experiments/$(1)/%/change_parameters.jl 
	@echo " + Compiling '$$@'"
	cd $$(dir $$@) && $(JULIA) scenario.jl > errors.log 2>&1
endef

$(foreach experiment,$(TABLES),$(eval $(call run_experiment,$(experiment))))

experiments/%/output_table.csv: $(foreach column,$(COLUMNS),experiments/%/$(column)/results.jld2) output.jl table.jl
	$(JULIA) table.jl $(dir $@)

data: data/impvol_data.jld2
data/impvol_data.jld2: read_data.jl data/*.csv data/*.txt
	$(JULIA) read_data.jl

# template target removed

# install the Julia package dependencies
install: install.jl
	$(JULIA) install.jl

# Removed paper-specific copy rules; build focuses on baseline/no_usa only
