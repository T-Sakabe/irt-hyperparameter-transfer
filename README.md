# Hyperparameter Transfer Using Item Response Theory

This repository provides the code and data for the paper **"Hyperparameter Transfer Using Item Response Theory"**. Hyperparameter optimization (HPO) is computationally expensive when performed independently for each dataset. Existing transfer-based HPO methods rely on observed performance metrics and do not explicitly disentangle configuration capability from dataset characteristics. This work proposes an IRT-based hyperparameter transfer method that separates these factors and enables efficient transfer.

<p align="center">
  <img src="./image/Method_Overview.png" alt="Overview of the proposed IRT-based hyperparameter transfer method" width="100%"><br>
</p>

---

## Data

The provided data contain **binary prediction results**:

* Rows: hyperparameter configurations
* Columns: data samples
* Values:

  * `1` = correct prediction
  * `0` = incorrect prediction

These data are the same as those used in the experiments in the paper.

---

## Usage

### 1. Set data paths

Update the data paths in the script according to the transfer setting:

```r
path_source <- "data/cifar10_binary_results.csv"
path_target   <- "data/fer2013_binary_results.csv"
```

### 2. Run

#### One-to-one transfer

```bash
Rscript src/run_one_to_one.R
```

#### Two-to-one transfer

```bash
Rscript src/run_two_to_one.R
```

---

## Repository Structure

```bash
.
├── src/
│   ├── run_one_to_one.R     # one source -> one target
│   ├── run_two_to_one.R     # multiple sources -> one target
│   └── utils.R              # utility functions
├── data/
│   ├── cifar10_binary_results.csv
│   ├── fer2013_binary_results.csv
│   └── quickdraw_binary_results.csv
├── image/
│   └── Method_Overview.png
└── README.md
