sample_uniform_accuracy_models <- function(data, num_models = 100, num_bins = 10) {

  accuracy_scores <- rowMeans(data, na.rm = TRUE)
  
  bins <- cut(accuracy_scores, breaks = seq(0, 1, length.out = num_bins + 1), include.lowest = TRUE)
  bin_levels <- levels(bins)
  
  models_per_bin <- floor(num_models / num_bins)
  remainder <- num_models %% num_bins
  
  selected_indices <- c()
  leftover_candidates <- c()
  
  for (i in seq_along(bin_levels)) {
    bin_level <- bin_levels[i]
    candidates <- which(bins == bin_level)
    
    draw_count <- models_per_bin + ifelse(i <= remainder, 1, 0)
    
    if (length(candidates) >= draw_count) {
      selected <- sample(candidates, draw_count)
    } else {
      selected <- candidates
      leftover_candidates <- c(leftover_candidates, setdiff(candidates, selected))
    }
    
    selected_indices <- c(selected_indices, selected)
  }
  
  if (length(selected_indices) < num_models) {
    all_indices <- 1:nrow(data)
    remaining_pool <- setdiff(all_indices, selected_indices)
    n_needed <- num_models - length(selected_indices)
    
    if (length(remaining_pool) >= n_needed) {
      selected_indices <- c(selected_indices, sample(remaining_pool, n_needed))
    } else {
      warning("Not enough unique models to reach num_models.")
      selected_indices <- c(selected_indices, remaining_pool)
    }
  }
  
  return(selected_indices)
}


make_binary_AllModel <- function(datasets) {
  valid_lengths <- sapply(datasets, function(ds) length(get_valid_cols(ds)))
  
  num_items <- min(valid_lengths)
  cat("num_items:", num_items, "\n")
  
  selected_list <- lapply(datasets, function(ds) {
    idx <- select_items_random(ds, num_items)
    ds[, idx, drop = FALSE]
  })
  
  binary_AllModel <- do.call(cbind, selected_list)
  return(binary_AllModel)
}


run_mirtjml_checked <- function(response, K) {
  rotation_converged <- TRUE
  
  fit <- withCallingHandlers(
    {
      mirtjml_expr(response = response, K = K)
    },
    warning = function(w) {
      msg <- conditionMessage(w)
      if (grepl("convergence not obtained in GPFoblq", msg)) {
        rotation_converged <<- FALSE
        invokeRestart("muffleWarning")
      }
    }
  )
  
  list(
    fit = fit,
    rotation_converged = rotation_converged
  )
}


sample_items_by_acc <- function(binary_AllModel,
                                total_sample = 500,
                                n_groups     = 10,
                                replace_if_few = FALSE) {
  item_p <- colMeans(binary_AllModel, na.rm = TRUE)
  
  breaks <- seq(0, 1, length.out = n_groups + 1)
  
  item_group <- cut(
    item_p,
    breaks = breaks,
    right = FALSE,       # [a, b)
    include.lowest = TRUE
  )
  
  if (total_sample %% n_groups != 0) {
    stop("total_sample must be divisible by n_groups for balanced sampling.")
  }
  n_per_group <- total_sample / n_groups
  
  sample_col_idx <- unlist(
    lapply(levels(item_group), function(g) {
      idx <- which(item_group == g)
      
      if (length(idx) == 0) {
        stop(paste0("No items found in interval ", g, "."))
      }
      
      if (!replace_if_few && length(idx) < n_per_group) {
        stop(paste0("Fewer than ", n_per_group, " items found in interval ", g,
                    " (only ", length(idx), " available).")
             )
      }
      
      sample(idx,
             size    = n_per_group,
             replace = replace_if_few && (length(idx) < n_per_group))
    })
  )
  
  shuffle_order <- sample(seq_along(sample_col_idx))
  sample_col_idx_shuffled <- sample_col_idx[shuffle_order]
  
  binary_sampled <- binary_AllModel[, sample_col_idx_shuffled]
  
  sampled_group_table <- table(item_group[sample_col_idx_shuffled])
  
  tracking <- data.frame(
    sampled_position = seq_along(sample_col_idx_shuffled),
    original_col     = sample_col_idx_shuffled,
    original_group   = as.character(item_group[sample_col_idx_shuffled]),
    stringsAsFactors = FALSE
  )
  
  list(
    binary_sampled            = binary_sampled,
    sampled_index_original    = sample_col_idx,
    sampled_index_shuffled    = sample_col_idx_shuffled,
    item_p                    = item_p,
    item_group                = item_group,
    group_table_sampled       = sampled_group_table,
    tracking                  = tracking
  )
}

equate_1d <- function(theta_common_A, theta_common_B, a_mat) {
  inner_prod <- sum(theta_common_A * theta_common_B, na.rm = TRUE)
  R <- sign(inner_prod)
  if (R == 0) {
    R <- 1
  }
  
  theta_aligned <- theta_common_B * R
  
  a_rot <- a_mat * as.numeric(R)
  
  list(
    R = R,
    theta_aligned = theta_aligned,
    a_rot = a_rot
  )
}


get_valid_cols <- function(dataset) {
  col_correct_rates <- colMeans(dataset)
  which(col_correct_rates > 0 & col_correct_rates < 1)
}

select_items_random <- function(dataset, num_items) {
  col_correct_rates <- colMeans(dataset)
  valid_cols <- which(col_correct_rates > 0 & col_correct_rates < 1)
  
  num_items <- min(num_items, length(valid_cols))
  
  selected <- sample(valid_cols, num_items)
  return(selected)
}
