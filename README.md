# ContrRep_ASEJ

This repository contains the code, the benchmarks and the experimental results of the paper
"ContrRep: Search-Based Repair of DNN Controllers of AI-Enabled CPSs".

## Abstract

Modern Cyber-Physical Systems (CPSs) are increasingly adopting Deep Neural Networks (DNNs) as controllers, giving rise to a new class of systems known as AI-enabled CPSs. DNNs may occasionally make incorrect control decisions, leading to failures of AI-enabled CPSs. In this paper, we propose ContrRep, a search-based repair approach for DNN controllers of AI-enabled CPSs. ContrRep takes as input some tests that violate a system-level specification, and uses a search-based approach to change the value of some weights of the DNN controller with the goal of passing all the tests. ContrRep proposes three fitness functions to guide the search: a function (DISC) that only considers the number of passing tests, and two other functions (CONT_ALL and CONT_NEG) that also consider the robustness of the test execution, i.e., how far the tests are from passing or failing. ContrRep further proposes a heuristic method that avoids executing all the tests and, in this way, speeds up the search. Experimental results on real-world benchmarks show that ContrRep is able to effectively repair the DNN controllers. In particular, the two fitness functions CONT_ALL and CONT_NEG obtain better results, as they provide a more fine-grained guidance during the search. The heuristic method for fitness computation can substantially decrease the computational cost of the search, at a small expense in repair effectiveness.

## Benchmarks

| Paper | Folder | Faulty DNN controller | K | Population |
|---|---|---|---|---|
| ACC<sup>C1</sup> | `benchmark/ACC1_Phi1` | `ACC4_FFNN_trainbfg_15_15_15_ep_100_Nor_20250527` | 10 | 20 |
| ACC<sup>C2</sup> | `benchmark/ACC1_Phi2` | `ACC5v_FFNN_traingdx_15_15_15_ep_50_Nor_20250702` | 10 | 20 |
| ACC<sup>C3</sup> | `benchmark/ACC2_Phi1` | `ACC4_FFNN_trainoss_30_30_30_ep_100_Nor_20250528` | 35 | 70 |
| ACC<sup>C4</sup> | `benchmark/ACC2_Phi2` | `ACC5v_FFNN_traincgf_30_30_30_ep_50_Nor_20250704` | 35 | 70 |
| AFC<sup>C5</sup> | `benchmark/AFC1_Phi1` | `AFC1_FFNN_trainscg_15_15_15_ep_1000_Nor_20250518` | 10 | 20 |
| AFC<sup>C6</sup> | `benchmark/AFC1_Phi2` | `AFC2_FFNN_trainscg_15_15_15_ep_1000_Nor_20250717` | 10 | 20 |
| AFC<sup>C7</sup> | `benchmark/AFC2_Phi1` | `AFC1_FFNN_trainrp_15_15_15_15_ep_1000_Nor_20250519` | 15 | 30 |
| AFC<sup>C8</sup> | `benchmark/AFC2_Phi2` | `AFC2_FFNN_trainscg_15_15_15_15_ep_500_Nor_20250717` | 15 | 30 |
| UUV<sup>C9</sup> | `benchmark/uuv` | `uuv_tanh_2_15_2x32_broken` | 20 | 40 |
| MC<sup>C10</sup> | `benchmark/mc` | `mc_sig_2x16_broken` | 5 | 10 |

K is the number of suspicious weights repaired, and the DE population size is 2K.
Each benchmark folder contains the Simulink model (ACC and AFC) or the network in YAML format (UUV and MC), the 100 test inputs used during the repair (`*_testCaseNum_100.mat`; for UUV and MC, `UUV_Phi_1_*.mat` and `MC_Phi_1_*.mat`), and the $10^4$ held-out inputs used to assess generalisation (`*_testCaseNum_10000_val.mat`).

`benchmark/normalization/` contains the input/output normalisation parameters (`ps_x`, `ps_y`) of the ACC and AFC controllers. The original files also contain the training data of the controllers (more than 100 MB each); since the repair only reads `ps_x` and `ps_y`, only these two variables are included.

## Project Structure

```
ContrRep_ASEJ/
├── analysis/                      # one script per table of the paper (see "Analysis" below)
│   └── private/                   # helpers shared by the analysis scripts
├── benchmark/                     # the 10 faulty benchmarks (see the table above)
├── DE/                            # differential evolution
│   └── fitness/                   # fitness functions (see "Naming" below)
├── results/                       # results of all the runs reported in the paper
│   ├── <benchmark>/DE/            # ContrRep runs
│   ├── <benchmark>/random/        # Random baseline runs
│   └── valEval/                   # assessment of the repaired controllers on the 10^4 held-out inputs
├── src/ContrRep.m                 # main class: fault localisation, repair, calibration, validation
├── test/
│   ├── config/{ACC,AFC,UUV,MC}/   # experiment configurations
│   ├── sim_real_{flrep,calib,valeval}.py     # script generators for ACC and AFC (Simulink)
│   ├── nonsim_real_{flrep,calib,valeval}.py  # script generators for UUV and MC (MATLAB simulators)
│   └── scripts/                   # generated MATLAB scripts are written here
├── util/                          # fault localisation, simulation, statistics and other helpers
├── Makefile, run                  # run all the generated scripts
└── LICENSE
```

## Requirements

- MATLAB with Simulink, Deep Learning Toolbox and Parallel Computing Toolbox (a MATLAB licence is needed)
- [Breach](https://github.com/decyphir/breach), used to compute the robustness of the STL specifications
- Python >= 3.6, only to generate the experiment scripts (standard library only)

The original Python simulators of UUV and MC (`benchmark/uuv/uuv.py`, `benchmark/mc/mc.py`) additionally need `numpy`, `pandas`, `scipy`, `torch` and `pyyaml`; they are not needed for the repair, which uses the MATLAB re-implementations of the two simulators.

## Installation

1. Clone this repository. All the files are stored directly in git, so no extra step is needed to obtain the models and the results.
2. Install Breach: start MATLAB, set up a C/C++ compiler with `mex -setup`, navigate to the `breach/` folder and run `InstallBreach`.
3. Point the configurations to your local copies of this repository and of Breach. Every configuration starts with the two placeholder paths `/path/to/ContrRep_ASEJ` and `/path/to/breach`; for example:

   ```
   cd test/config
   sed -i 's|/path/to/ContrRep_ASEJ|/home/me/ContrRep_ASEJ|; s|/path/to/breach|/home/me/breach|' */*
   ```

   (On macOS, use `sed -i ''` instead of `sed -i`.)

## Reproducing the Experiments

Each step generates MATLAB scripts from a configuration and then runs them.
The generators are run from `test/`, and the generated scripts from the repository root, where they write their results.

### 1. Repair

For ACC and AFC (configurations `config/{ACC,AFC}/rfFR<i><j>`, where `<i>` is the controller and `<j>` the specification):

```
cd test
python sim_real_flrep.py config/AFC/rfFR12      # AFC^{C6}
cd ..
make                                            # or: sh test/scripts/<generated script>
```

For UUV and MC:

```
cd test
python nonsim_real_flrep.py config/MC/rfFR     # MC^{C10}
cd ..
make
```

The results are written to `results/<benchmark>/<DE|random>/tops_<K>_popSize_<2K>_gen_50/`.
The main fields of the configurations are:

- `budget`: number of runs (the paper reports 10 runs; a run whose result already exists is skipped, so the budget can be increased later);
- `searchMode`: `DE` for ContrRep, `random` for the Random baseline (for `random`, list only `expdis` under `fitnessMode`, since every listed fitness function starts a separate set of runs);
- `fitnessMode`: the fitness functions to run (see "Naming" below);
- `scaleParam`: scale parameter of the search bounds (2 in RQ1–RQ3; 1.5 and 3 in RQ4);
- `coreNum`: number of parallel workers.

### 2. Calibration of the approximate fitness

The runs with the approximate fitness (ContrRep-Fast) are calibrated afterwards: the tests skipped by the approximate fitness are executed for all the individuals of the first and of every fifth generation (`calibStep`), and `calibBestIndLog` and `calibFullPopLog` are added to the result files:

```
cd test
python sim_real_calib.py config/AFC/rfCalib12          # nonsim_real_calib.py config/MC/calib_rf for UUV and MC
cd ..
make
```

### 3. Assessment on the held-out inputs

The repaired controller of each run is executed on the $10^4$ held-out inputs; the outcome is written to `results/valEval/`:

```
cd test
python sim_real_valeval.py config/AFC/rfValEval12      # nonsim_real_valeval.py config/MC/valEval_rf for UUV and MC
cd ..
make
```

### 4. Analysis

Each script in `analysis/` reads `results/` and prints the LaTeX rows of the tables of the paper it is named after (`rq<RQ>_tab<table>_<content>.m`); it can be run in MATLAB from any folder, e.g., `run('analysis/rq123_tab4to7_cmExec.m')`.

| Script | Paper | Content |
|---|---|---|
| `rq123_tab4to7_cmExec.m` | Tables 4–7 | correctness measure (CM) on the 100 test inputs and on the 10^4 held-out inputs, executed tests, and paired Cohen's d between approaches |
| `rq3_tab8_ordAssump.m` | Table 8 | validity of the ordering assumption behind the approximate fitness |
| `rq4_tab9to10_scaleSens.m` | Tables 9–10 | change of CM and executed tests with the scale parameters 1.5 and 3 |
| `rq4_tab11_solSpread.m` | Table 11 | position of the repaired weights for the scale parameters 1.5, 2 and 3 |
| `rq5_tab12_repPres.m` | Table 12 | percentages of repaired (Rep.) and preserved (Pres.) tests |
| `sec6_lexCoeff.m` | Section 6.4 | how often the weight λ = 10^4 of the fitness lets an individual passing fewer tests win the selection |

The ISAR column of Tables 4–7 and 12 is read from the results of the ISAR runs (`results/contrrep/` of the ISAR repository, expected next to this repository as `../ISAR`); without them, that column is left empty and the effect sizes are computed among the other approaches.

## Naming

Result files are named
`<controller>_bug_<lb>_<ub>_K_<K>_tssize_100_scaleParam_<s>_searchmode_<DE|random>_fitmode_<fitness>_budget_<run>_geni_<last generation>.mat`.

| `fitmode` in file names and configurations | Approach in the paper |
|---|---|
| `expdis` | CR<sup>exact</sup> DISC |
| `expcon1` | CR<sup>exact</sup> CONT_ALL |
| `expcon3` | CR<sup>exact</sup> CONT_NEG |
| `cheapincrdis` | CR<sup>approx</sup> DISC |
| `cheapincrcon1` | CR<sup>approx</sup> CONT_ALL |
| `cheapincrcon3` | CR<sup>approx</sup> CONT_NEG |
| `expdis` with `searchmode_random` | Random |

Each result file contains, for every generation, the best individual found so far (`bestIndLog`) and the whole population with the robustness of each test (`fullPopLog`); the calibrated runs also contain `calibBestIndLog` and `calibFullPopLog`.
The repaired controller of a run is the best individual of the last generation that was run, i.e., `bestIndLog(g).bestInd`, where `g` is the last non-empty generation of `fullPopLog` (`calibBestIndLog(g).bestInd` for the approximate fitness); if it does not pass more tests than the original controller, the original controller is kept.

## License

See [LICENSE](LICENSE).
