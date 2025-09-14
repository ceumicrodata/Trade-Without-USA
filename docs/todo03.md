# Title: Implementation Plan for Todo #3: Experiment Simplification

## Overview

• Reduce the project to two scenarios only: baseline (actual) and a single counterfactual (no_usa),
removing all other experiments, sub-scenarios, and Makefile targets that support them.

## Current vs Target

• Current: Multiple experiments (CES*, theta*, rho*, S500, labor_adjustment, trade_imbalance,
no_io_linkages, china_1972, no_china) and multiple sub-scenarios per experiment (actual, kappa1972,
nosectoral, nosectoral_kappa1972). Makefile builds many tables and copies outputs into paper-specific
names.
• Target: Keep only:
 • experiments/baseline/actual
 • experiments/baseline/no_usa
 • Makefile builds just these two outputs


## Step-by-Step Changes

### 1. Prepare no_usa counterfactual

- Rename experiments/no_china/actual to experiments/baseline/no_usa
- Move experiments/no_china/actual/init_parameters.jl to experiments/baseline/no_usa/change_parameters.jl

### 2. Prune experiments directory

• Keep only experiments/baseline/actual and experiments/baseline/no_usa
• Remove all others: CES, CES0.5, CES1.5, theta2, theta8, rho0005, rho002, S500, labor_adjustment,
no_io_linkages, trade_imbalance, china_1972
• Feel free to `git rm` everything, we are under version control

### 3. Simplify Makefile (surgical edits)

• Set only one scenario column:
 • COLUMNS = actual no_usa
• Limit experiments to one:
 • TABLES = baseline
• Keep generic rules (define run_experiment, experiments/%/output_table.csv) as-is
• Remove unused targets:
 • ces_tables, S500, admissible_eos
 • All output/tableX.csv copy rules (table1..8 mapping)
 • template target (optional)
• Define a minimal tables target:
 • tables: experiments/baseline/output_table.csv


### 4. Keep calibrate and data rules

• Retain install, data, and calibrate rules (they work generically with TABLES and COLUMNS)
• No changes to PROCS or JULIA settings

### 5. Validate build

• Rebuild data if needed: julia +1.10 --project=. read_data.jl
• Install deps: make install
• Calibrate: make calibrate
• Run both experiments: make tables
• Verify outputs exist:
 • experiments/baseline/output_table.csv

### 6. Sanity checks

• Confirm there is no reference to removed experiments in the Makefile or scripts
• Grep for removed names (CES, theta, rho, S500, no_io_linkages, trade_imbalance, china_1972) and
delete or update references if any remain

### 7. Documentation updates

• Update README build instructions to reflect the two-scenario workflow:
 • run data, install, calibrate, tables
• Note that only baseline and no_usa are supported


