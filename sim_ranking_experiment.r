#Testing for WeightedLossRanking function
#TODO ask Ron if we should/how to vary gap size without varying n

##IDEA
##increase gaps until trivial. decrease until broken/impossible. 
#think of this as an experiment. what experimental conditions do we need to run to get a sense of behavior.

#Step 0: Load
library(rstan)
library(dplyr)
#AND run entire ranking_function.r, ranking_metric.r files. 
set.seed(10)

#STEP 1: Simulate Different Types of Data
## Binomial Random Intercept n = 100 ## EVEN GAPS
#increase gaps until trivial. decrease until broken/impossible.
## PARAMETERS ##
gaps <- c(0.01, 0.1) #gap sizes tested here
topN = 10

#initialize arrays and lists
even <- array(data = NA, dim=c(length(gaps),4,10001)) #3 dim array with 4 matrices, 4 col and N rows (max = 10001) each
even_model <- vector("list", length(gaps)) #list of rank objects for each of the 4 matrices
even_rank <- vector("list", length(gaps))

even_metric_results <- #rank_metric results for each of the 4 matrices mr, 
  data.frame(metric_results = logical(length = 5))

for (i in 1:4){ #length(gaps)
  N = length(seq(from = 0, to = 1, by = gaps[i]))
  even[i, 1, 1:N] <- seq(from = 1, to = N, by = 1) #ITEM
  even[i, 2, 1:N] <- seq(from = 0, to = 1, by = gaps[i]) #P
  even[i, 3, 1:N] <- rep(as.integer(100),times = N) #SIZE
  even[i, 4, 1:N] <- rbinom(n = N, size = even[i, 3, 1:N], even[i, 2, 1:N]) #SIM SUCCESSES

  ## DATA FOR STAN##
  rstan_options(auto_write = TRUE)
  options(mc.cores = parallel::detectCores())
  sim_data = list(
    N = N, #N or numRows
    item = even[i, 1, 1:N], #ITEM ID
    sizeN = as.integer(even[i, 3, 1:N]), #same as cafes$n #SIZE
    count = as.integer(even[i, 4, 1:N]) #SIM SUCCESSES
  ) 
  #MODEL
  even_model[[i]] <- stan(file="/Users/cora/git_repos/RankingMethods/sim_randInt.stan",data=sim_data, seed = 10)
  
  even_rank[[i]] <- WeightedLossRanking(model = even_model[[i]], parameter = "p", loss = 2, lossTotal = TRUE)
  
  #compare using rankMetric, add to dataframe of results
  nam <- paste("gap", i, sep = "")
  even_metric_results$new <- RankMetric(even_rank[[i]], even[i, 1:4, 1:N], order = "largest", topN = 5)
  colnames(even_metric_results)[i+1] <- nam
}

#save results to a file
write.csv(even_metric_results, file = "/Users/cora/git_repos/RankingMethods/results/even_gaps_RankMetric_results.csv")


#TODO repeat above with uneven gap size
#try with bigger gaps, random unif on a range to have arbitrary gaps
#increase gaps until trivial. decrease until broken/impossible. 

#TODO repeat with testing over variation in N

#TODO add weights. How does this compare to not weighting at all?