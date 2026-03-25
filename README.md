# irt-hpo-transfer

This repository provides the implementation and data for the paper:

**"Hyperparameter Transfer Using Item Response Theory"**

## Overview

Hyperparameter optimization (HPO) is computationally expensive, especially when performed independently for each dataset.  
This work proposes a transfer-based HPO method using **Item Response Theory (IRT)**, which separates:

- the **latent capability of hyperparameter configurations**, and  
- the **characteristics of datasets**

This enables efficient hyperparameter transfer with only a small number of evaluations on the target dataset.

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
