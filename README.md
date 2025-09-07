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

## Usage

To reproduce the experimental results, users should follow the steps below:

  - The user-specified configuration files are stored under the directory `test/config/`. Replace the paths of `Spectacle` in user-specified file under the line `addpath 1` with their own path. Users can also specify other configurations, such as topk and tops.
  - Users need to edit the executable scripts permission using the command `chmod -R 777 *`.
  - The corresponding log will be stored under directory `output/`.
    

