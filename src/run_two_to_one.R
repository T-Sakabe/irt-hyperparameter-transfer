library(mirtjml)
library(dplyr)
library(ggplot2)
library(MASS)

#-----------------------------------------
# 1. Load data
#-----------------------------------------
# Set the paths according to the transfer setting
path_A_1 <- "data/CIFAR10_binary_results.csv"
path_A_2 <- "data/QuickDraw_binary_results.csv"
path_B <- "data/FER2013_binary_results.csv"
DatasetA_1 <- read.csv(path_A_1, header = FALSE) # source dataset 1
DatasetA_2 <- read.csv(path_A_2, header = FALSE) # source dataset 2
DatasetB <- read.csv(path_B, header = FALSE) # target dataset

datasets_existing <- list(DatasetA_1, DatasetA_2)
binary_toAllModel <- make_binary_AllModel(datasets_existing)
dim(binary_toAllModel)
binary_toSmallModel <- DatasetB

K <-  2 # dimensionality of the ability (1 or 2 in the paper)
cat("K = ", K, "\n")

#-----------------------------------------
# 2. Ability Estimation on the Source Dataset
#-----------------------------------------

repeat_until_valid <- TRUE
start_time_all <- Sys.time()
col_correct_rates_A <- colMeans(binary_toAllModel)
cols_to_keep_A <- which(col_correct_rates_A > 0 & col_correct_rates_A < 1)
binary_AllModel <- binary_toAllModel[, cols_to_keep_A]

# Repeat item selection and parameter estimation until convergence
while(repeat_until_valid){
  
  #item selection
  res_sample <- sample_items_by_acc(binary_AllModel, total_sample = 500, n_groups = 10)
  binary_AllModel_conv <- res_sample$binary_sampled
  dim(binary_AllModel_conv)
  res_sample$group_table
  
  #parameter estimation
  res_fit_all <- run_mirtjml_checked(response = as.matrix(binary_AllModel_conv),   K = K)
  if (res_fit_all$rotation_converged){
    repeat_until_valid <- FALSE
  }
}

end_time_all <- Sys.time()
AllModel_sec <- as.numeric(difftime(end_time_all, start_time_all, units = "secs"))
cat("AllModel time",AllModel_sec, "\n")
fit_all <- res_fit_all$fit
theta_all   <- fit_all$theta_hat


#-----------------------------------------
# 2. Item Parameter Estimation on the Target Dataset
#-----------------------------------------
# Select hyperparameter configurations for item parameter estimation
n_models_small <- 10
index_SmallModel <- sample_uniform_accuracy_models(binary_toAllModel, num_models = n_models_small, num_bins = 10)
subset_small <- binary_toSmallModel[index_SmallModel, ]
theta_common_A <- theta_all[index_SmallModel, ]

start_time <- Sys.time()
col_correct_rates_small <- colMeans(subset_small)
cols_to_keep_small <- which(col_correct_rates_small > 0 & col_correct_rates_small < 1)
binary_SmallModel <- subset_small[, cols_to_keep_small]

binary_SmallModel_base <- binary_SmallModel

block_size <- 100
max_conv_blocks <- 5
max_trial <- 10000

b_list <- list()
a_list <- list()
theta_list <- list()
idx <- 1
count_conv <- 0
trial <- 1

# Repeat item selection and parameter estimation
while (count_conv < max_conv_blocks &&
       ncol(binary_SmallModel_base) >= block_size &&
       trial <= max_trial) {
  cat("Trial:", trial, 
      " / Remaining items:", ncol(binary_SmallModel_base), "\n")
  trial <- trial + 1
  sel_idx <- sample(ncol(binary_SmallModel_base), size = block_size, replace = FALSE)
  binary_i <- as.matrix(binary_SmallModel_base[, sel_idx, drop = FALSE])
  binary_i_shuffled <- binary_i[, sample(ncol(binary_i)), drop = FALSE]
  res_fit_small <- run_mirtjml_checked(binary_i_shuffled, K = K)
  if (res_fit_small$rotation_converged) {
    cat("  Converged! (conv blocks:", count_conv + 1, ")\n")
    
    fit_small   <- res_fit_small$fit
    theta_small <- fit_small$theta_hat
    
    theta_common_B <- theta_small
    a_mat <- fit_small$A_hat   # discrimination
    d_vec <- fit_small$d_hat   # difficulty
    
    if (K == 1) {
      equate_res <- equate_1d(theta_common_A, theta_common_B, a_mat)
      
      R <- equate_res$R
      theta_small_aligned <- equate_res$theta_aligned
      a_rot <- equate_res$a_rot
      
      b_list[[idx]]    <- d_vec
      a_list[[idx]]    <- a_rot
      theta_list[[idx]] <- theta_small_aligned
      
    } else {
      proc <- svd(t(theta_common_B) %*% theta_common_A)
      R <- proc$u %*% t(proc$v)
      
      theta_small_aligned <- theta_small %*% R
      a_mat_rot <- a_mat %*% R
      
      b_list[[idx]]    <- d_vec
      a_list[[idx]]    <- a_mat_rot
      theta_list[[idx]] <- theta_small_aligned
    }
    idx <- idx + 1
    count_conv <- count_conv + 1
    
    binary_SmallModel_base <- binary_SmallModel_base[, -sel_idx, drop = FALSE]
  } else {
    cat("  Not converged.\n")
  }
}
cat("Total converged blocks:", count_conv, "\n")

b_vec_conv <- unlist(b_list, use.names = FALSE)
a_mat_rot_conv <- do.call(rbind, a_list)

#-----------------------------------------
# 3. Performance Prediction based on IRT
#-----------------------------------------
logistic_mirtjml <- function(theta_vec, a_vec, b) {
  1 / (1 + exp(- (sum(a_vec * theta_vec) + b)))
}

n_models <- nrow(theta_all)
n_items  <- nrow(a_mat_rot_conv)

prob_mat <- matrix(0, nrow = n_models, ncol = n_items)
for (i in 1:n_models) {
  for (j in 1:n_items) {
    prob_mat[i, j] <- logistic_mirtjml(theta_all[i, ], a_mat_rot_conv[j, ], b_vec_conv[j])
  }
}
predicted_acc <- rowMeans(prob_mat)

end_time <- Sys.time()

SmallModel_sec <- as.numeric(difftime(end_time, start_time, units = "secs"))
print(paste0("Elapsed time: ", SmallModel_sec, " sec"))
cat("Small time",SmallModel_sec, "\n")


#-----------------------------------------
# (4. Comparison with true accuracy)
#-----------------------------------------
true_acc <- rowMeans(binary_toSmallModel)

plot(true_acc, predicted_acc, xlab = "True Accuracy", ylab = "Predicted Accuracy",
     main = "Accuracy Comparison")
abline(0, 1, col = "red")

true_rank <- rank(-true_acc, ties.method = "min")
pred_rank <- rank(-predicted_acc, ties.method = "min")

plot(true_rank, pred_rank, xlab = "True Rank", ylab = "Predicted Rank",
     main = "Ranking Comparison")
abline(0, 1, col = "blue")

top_true <- which.max(true_acc)
top_pred <- which.max(predicted_acc)

#-----------------------------------------
# 5. Save results
#-----------------------------------------
true_acc_All <- rowMeans(binary_AllModel_conv)
firstAcc_All <- true_acc_All[index_SmallModel]
sorted_index_SmallModel <- index_SmallModel[order(firstAcc_All, decreasing = TRUE)]
true_acc <- rowMeans(binary_toSmallModel)
firstAcc <- true_acc[sorted_index_SmallModel]

ord <- order(predicted_acc, decreasing = TRUE)
ord_no_small <- ord[!ord %in% index_SmallModel]

ord_with_small_first <- c(sorted_index_SmallModel, ord_no_small)

true_acc_by_small_pred <- true_acc[ord_with_small_first]
predicted_acc_by_small_pred <- predicted_acc[ord_with_small_first]
model_idx_by_small_pred <- ord_with_small_first

head(cbind(model_idx_by_small_pred,
           predicted_acc_by_small_pred,
           true_acc_by_small_pred), 15)
