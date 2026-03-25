# Hyperparameter Transfer Using Item Response Theory

This repository provides the code and data for the paper:

**"Hyperparameter Transfer Using Item Response Theory"**

Hyperparameter optimization (HPO) is computationally expensive, especially when performed independently for each dataset.  
This work proposes a transfer-based HPO method using **Item Response Theory (IRT)**, which separates:

- the **latent ability of hyperparameter configurations**, and  
- the **characteristics of datasets**

This enables efficient hyperparameter transfer with only a small number of evaluations on the target dataset.  
This repository provides code and data for offline transfer-based HPO experiments.

<p align="center">
  <img src="./image/Method_Overview.png" alt="Overview of the proposed IRT-based hyperparameter transfer method" width="100%"><br>
</p>

---

## Key Idea

In this framework:

- Hyperparameter configurations are treated as **examinees**
- Data samples are treated as **test items**

Using IRT, we estimate:

- **Ability parameters** of hyperparameter configurations (from source datasets)
- **Item parameters** of target datasets (from limited evaluations)

By linking these latent spaces, the performance of all configurations on the target dataset can be predicted **without exhaustive evaluation**.

---

## Data

The provided datasets contain **binary prediction results**:

* Rows: hyperparameter configurations
* Columns: data samples
* Values:

  * `1` = correct prediction
  * `0` = incorrect prediction

These datasets are the same as those used in the experiments in the paper.

---

## Usage

### 1. Set dataset paths

Update the dataset paths in the script according to the transfer setting:

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
