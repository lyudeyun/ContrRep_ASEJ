# ContrRep_ASEJ

This repository reports the code and the benchmarks for the paper "ContrRep: Search-Based Repair of DNN
Controllers of AI-Enabled CPSs".

## Abstract
Modern Cyber-Physical Systems (CPSs) are increasingly adopting Deep Neural Networks (DNNs) as controllers, giving rise to a new class of systems known as AI-enabled CPSs. DNNs may occasionally make incorrect control decisions, leading to failures of AI-enabled CPSs. In this paper, we propose ContrRep, a search-based repair approach for DNN controllers of AI-enabled CPSs. ContrRep takes as input some tests that violate a system-level specification, and uses a search-based approach to change the value of some weights of the DNN controller with the goal of passing all the tests. ContrRep proposes three fitness functions to guide the search: a function (DISC) that only considers the number of passing tests, and two other functions (CONT_ALL and CONT_NEG) that also consider the robustness of the test execution, i.e., how far the tests are from passing or failing. ContrRep further proposes a heuristic method that avoids executing all the tests and, in this way, speeds up the search. Experimental results on real-world benchmarks show that ContrRep is able to effectively repair the DNN controllers. In particular, the two fitness functions CONT_ALL and CONT_NEG obtain better results, as they provide a more fine-grained guidance during the search. The heuristic method for fitness computation can substantially decrease the computational cost of the search, at a small expense in repair effectiveness.

## System Requirements

- Operating system: Linux / MacOS / Windows
- Matlab (Simulink/Stateflow) version: >= 2020a (Matlab license needed)
- Python version: >= 3.3
- MATLAB toolboxes dependency: 
  1. [Simulink](https://www.mathworks.com/products/simulink.html)
  2. [Deep Learning Toolbox](https://www.mathworks.com/products/deep-learning.html)

## Installation

- Install [Breach](https://github.com/decyphir/breach)
  1. start matlab, set up a C/C++ compiler using the command `mex -setup`. (Refer to [here](https://www.mathworks.com/help/matlab/matlabexternal/changing-default-compiler.html) for more details.)
  2. navigate to `breach/` in Matlab command line, and run `InstallBreach`
- Install Git Large File Storage
  1. for linux:
     ```
     curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
     sudo apt-get install git-lfs
     git lfs install
     ```
  2. for mac:
     ```
     brew install git-lfs
     git lfs install
     ```
- Retrieve the dataset stored in the form of a large file by the following command `git lfs pull`

## Project Structure

```
  ContrRep_ASEJ/
  ├── benchmark/                  # 10 Faulty Benchmarks
  │   ├── ACC1_Phi1/              # ACC1 model with Phi1 specification
  │   ├── ACC1_Phi2/              # ACC1 model with Phi2 specification
  │   ├── ACC2_Phi1/              # ACC2 model with Phi1 specification
  │   ├── ACC2_Phi2/              # ACC2 model with Phi2 specification
  │   ├── AFC1_Phi1/              # AFC1 model with Phi1 specification
  │   ├── AFC1_Phi2/              # AFC1 model with Phi2 specification
  │   ├── AFC2_Phi1/              # AFC2 model with Phi1 specification
  │   ├── AFC2_Phi2/              # AFC2 model with Phi2 specification
  │   ├── mc/                     # MC model
  │   └── uuv/                    # UUV model
  ├── DE/                         # Differential Evolution algorithm
  │   └── fitness/                # Fitness function implementations
  ├── result/                     # Experimental results
  │   ├── ACC1_Phi1/             # ACC1 + Phi1 results (DE + random)
  │   ├── ACC1_Phi2/             # ACC1 + Phi2 results (DE + random)
  │   ├── ACC2_Phi1/             # ACC2 + Phi1 results (DE + random)
  │   ├── ACC2_Phi2/             # ACC2 + Phi2 results (DE + random)
  │   ├── AFC1_Phi1/             # AFC1 + Phi1 results (DE + random)
  │   ├── AFC1_Phi2/             # AFC1 + Phi2 results (DE + random)
  │   ├── AFC2_Phi1/             # AFC2 + Phi1 results (DE + random)
  │   ├── AFC2_Phi2/             # AFC2 + Phi2 results (DE + random)
  │   ├── MC/                    # MC results (DE + random)
  │   └── UUV/                   # UUV results (DE + random)
  ├── src/                       # Source code
  │   └── AutoPatch.m            # Main class file
  ├── test/                      # Repair files and configurations
  │   ├── config/                # Repair configurations
  │   │   ├── ACC/               # ACC configs
  │   │   ├── AFC/               # AFC configs
  │   │   ├── MC/                # MC configs
  │   │   └── UUV/               # UUV configs
  │   └── scripts/               # The generated executable scripts
  │   ├── nonsim_real_calib.py   # CR^{approx} calibration with UUV and MC benchmarks
  │   ├── sim_real_calib.py      # CR^{approx} calibration with ACC and AFC benchmarks
  │   ├── nonsim_real_flrep.py   # CR^{approx} repair with UUV and MC benchmarks
  │   └── sim_real_flrep.py      # CR^{approx} repair with ACC and AFC benchmarks
  └── util/                      # Utility functions and tools
      ├── actCriteria/           # Activation criteria functions
      ├── Cohen's_d/             # Cohen's d effect size computation
      ├── FL/                    # Fault localization utilities
      ├── mannWhitneyUTest/      # Mann-Whitney U test implementation
      ├── par/                   # Parallel processing utilities
      ├── repair/                # Repair algorithm implementations
      ├── train/                 # Neural network training utilities
      ├── varghaDelaneyA12/      # Vargha-Delaney A12 effect size
      └── yaml/                  # YAML file handling utilities
```

## Usage

To reproduce the experimental results, users should follow the steps below:

### Running Experiments on Simulink-Based Benchmarks (ACC and AFC)

For the **ACC** and **AFC** benchmarks, which are based on Simulink models, the workflow is as follows:

1. Navigate to the `test` directory of the repository.  
2. Edit the corresponding configuration file under `config/ACC` or `config/AFC`. The provided configurations are set to default values.  
3. Run the repair script:  

   ```
   python sim_real_flrep.py config/[benchmark]/rfFR[num1][num2]
   ```
   \[benchmark\]: either ACC or AFC; \[num1\]: specifies the controller structure \[num2\]: specifies the system specification.

   For example,

   ```
   python sim_real_flrep.py config/AFC/rfFR_1_2
   ```
   This runs the repair for AFC1_spec2, which corresponds to AFC^{C_{6}} in the paper.
4. After the repair finishes, calibrate the CR^heuristic method to obtain the actual CM values:
   ```
   python sim_real_calib.py config/[benchmark]/rfCalib[num1][num2]
   ```
### Running Experiments on Python-Based Benchmarks (UUV and MC)

For the **UUV** and **MC** benchmarks, which are based on Simulink models, the workflow is as follows:

1. Navigate to the `test` directory of the repository.  
2. Edit the corresponding configuration file under `config/UUV` or `config/MC`. The provided configurations are set to default values.  
3. Run the repair script:  

   ```
   python nosim_real_flrep.py config/[benchmark]/flRepair_rf
   ```
   \[benchmark\]: either UUV or MC

   For example,

   ```
   python nosim_real_flrep.py config/MC/flRepair_rf
   ```
   This runs the repair for MC, which corresponds to MC^{C_{10}} in the paper.
4. After the repair finishes, calibrate the CR^heuristic method to obtain the actual CM values:
   ```
   python nosim_real_calib.py config/[benchmark]/calib_rf
   ```
