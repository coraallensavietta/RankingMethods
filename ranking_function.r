### Weighted Loss Ranking Functions ###

## Cora Allen-Coleman Summer 2018 ##

## Includes:
    # Weighted Loss Ranking
    # Weight Creation
  #Simulation/Experiment Functions:
    # SelectNP, SimData, PostSamples
    # RunSimulation
    # RankMetric, RankMetricDF(not finished)

#Step 0: Load Packages.                 #first time: install.packages("rstan", "clue")
library(rstan)
library(dplyr)
library(rstanarm)
library(clue)

set.seed(10)

### Ranking Function for Extracting Parameters and Ranking ### 

WeightedLossRanking <- function(model = NULL, sampleMatrix = NULL, parameter = NULL, loss = 2,  
                                f=identity, 
                                rankWeights = rep(1, times = n), itemweights = rep(1, times = n)){
# Computes optimal ranking for a list of estimates
#   
# Args:
#   model: a stan model for the estimates
#   sampleMatrix: a matrix of samples. dim = n samples by n items. Result of PostSamples function
#   parameter: parameter to rank, as a string. Only necessary if inputting model rather than sampleMatrix.
#   loss: an exponent indicating the loss function for ranking. options: 2=square, 1=absolute, 0=zero
#   f: scale for loss calculation. options: identity, rank
#   rankWeights: a vector of length equal to number of items to be ranked. Weights positions.
#   itemweights: a vector of length equal to number of items to be ranked. Weights items.
#
# Returns:
#   totalLoss
#   optimal ranking for a list of estimates
  
# Dependencies: rstan, clue
  
  if (!is.null(sampleMatrix)){ #checks for sampleMatrix
    i = sampleMatrix
    #print(dim(i)) #TODO remove
  } else if (!is.null(model)){ #checks for model
    print("model check") #TODO remove
    i <- rstan::extract(model, pars=parameter)[[1]] #extract samples from model
  }
  rho_i <- apply(i, 1, f) #apply function/scale transformation to matrix i. Should this be on cols (2)?
  rho_j <- apply(rho_i, 2, sort) #sort transformed samples (matrix j) so each column is sorted
  n <- ncol(i) #n = # items to be ranked

  if (loss == 0){
    #Q: this doesn't make sense unless we're on the rank scale, right? 
    #TODO give an error if user tries to use another scale
    LossRnk <- matrix(NA,n,n)
    for (i in 1:n) {
      for (j in 1:n) {
        LossRnk[i,j] <- rankWeights[j]*itemweights[i]*mean(m_rho_i[i,]!=m_rho_j[j,])
        }
    }
    return(solve_LSAP(LossRnk))
  } else{ #all other loss cases
    LossRnk <- matrix(NA,n,n)
    for (i in 1:n) {
      for (j in 1:n) {
        LossRnk[i,j] <- rankWeights[j]*itemweights[i]*mean(abs((rho_i[i,]-rho_j[j,]))^loss)
      }
    }
    totalLoss = sum(LossRnk)
    
    return(list(LossRnk, solve_LSAP(LossRnk)))
  }
}

  
RankingWeights <- function(numItems = 20, priority = "top", steepness = .9){
  # Computes optimal ranking for a list of estimates. Largest weight is always 1.
  #   
  # Args:
  #   numItems: number of items to rank
  #   priority: focus for ranking. "even" to evenly weight, "top" to prioritize top ranked items, "bottom" for bottom ranked items, "both" for both. 
  #   steepness: size of e between 0 and 1. Smaller e creates steeper weights. Larger e creates more even weights. Planning to test 3 (slow, steady, steep)
  #
  # Returns:
  #   vector of weights
  
  weights <- vector(length = numItems)
  items <- seq(1:numItems)
  
  if (priority == "even"){
    weights = rep(1, times = numItems)
  } else if (priority == "top"){
    weights = steepness^(items-1)
  } else if (priority == "bottom"){
    # reverse version (you care about last items only)
    weights = steepness^((numItems-items))
  } else if (priority == "both"){
    # weights = c(1, e, e^2, ..., e^(n+1/2) middle, ..., e^2, e, 1)
    #for even, repeats same weight at bottom. (if numItems = 20, items 10 and 11 will both have the smallest weight)
    #for odd, one item will have smallest weight. (if numItems = 21, item 11 will have the smallest weight)
    weights = steepness^(items-1) #top
    weights[(round(numItems/2 + 0.1) + 1):numItems] = steepness^(items[(round(numItems/2)):0]-1) #bottom/second half
  } else {
    return("Priority must be given as 'even', 'top', 'bottom', or 'both'.")
  }
  return(weights)
}


SelectNP <- function(N = 25, a_p = 1, b_p = 1, n_min = 10, n_max = 30, a_n = 1, b_n = 1,
                     n_assignment_method = "ascending"){
  # function to simulate n, p from parameters. Deterministic.
  #   
  # Args:
  #   N: number of items to rank
  #   a_p: Shape parameter alpha for beta distribution to determine gaps in p. Allows for equal or nonequal gap size.
  #   b_p: Shape parameter beta for beta distribution to determine gaps in p. Allows for equal or nonequal gap size.
  #   n_min: minimum number of counts/tries for each binomial variable
  #   n_max: maximum number of counts/tries for each binomial variable
  #   a_n: Shape parameter alpha for beta distribution to determine gaps in n. Allows for equal or nonequal gap size.
  #   b_n: Shape parameter alpha for beta distribution to determine gaps in n. Allows for equal or nonequal gap size.
  #   n_assignment_method. Possibilities: "ascending" for assign in order, "descending" for assign in reverse order, 
  #   "random" for random assignment
  #
  # Returns:
  #   one matrix with 2 columns (n, p) and N rows
  #
  # Dependencies: 
  
  output <- matrix(data = NA, nrow = N, ncol = 3, 
                   dimnames = list(seq(1:N), c("item", "n", "p"))) #rows 1 to N, columns n, p
  #item (county, etc)
  output[,1] <- seq(1:N)
  #n
  output[,2] <- round(n_min + (n_max-n_min)*qbeta(1:N/(N+1), a_n, b_n), digits=0) #quantiles
  #p
  output[,3] <- qbeta((1:N)/(N+1), a_p, b_p)
  
  return(output)
}


SimData <- function(matrix){
  #simulates data from a dataframe of n, p
  
  # Args:
  #   matrix of deterministic n, p: A list of matrices containing N rows and 2 columns (n, p). Result of SelectNP where:
  #     n is the true attempts/tries/counts
  #     p is the true p
  #
  # Returns: 
  #   matrix of N rows and 2 columns (n, y) where n is attempts and y is successes
  #   alternative formulation (not used here): matrix of N rows and n_sim columns and make ONE deterministic n vector
  # 
  # Dependencies:
  
  N <- length(matrix[,1]) #number of items to rank (from SelectNP matrix)
  
  output <- matrix(data = NA, nrow = N, ncol = 3, 
                   dimnames = list(seq(1:N), c("item","n", "y")))
  #item
  output[,1] <- seq(1:N)
  #n (These are deterministic.)
  output[,2] <- matrix[,2] #
  #y counts (These vary randomly.)
  output[,3] <- rbinom(N, size = matrix[,2], prob = matrix[,3]) 
  return(output)
}

PostSamples <- function(data){  
  #gets posterior samples from data using a dataframe of n, p
  
  # Args:
  #   matrix of N rows and 2 columns (n, y) where n is attempts and y is successes. Output of SimData
  #
  # Returns: 
  #   one matrix of posterior samples. The matrix has one row for each iteration, one column for each item parameter estimated
  # 
  # Dependencies: rstanarm
  
  library(rstanarm)
  options(mc.cores = parallel::detectCores())
  
  model1 <- stan_glmer(cbind(y, n - y) ~ (1|item), data = as.data.frame(data), iter = 3000, #default iter = 2000
                       family = binomial(link=logit), prior_intercept = normal(0, 5),
                       prior_aux = cauchy(0,1),
                       seed = 12345)
  output <- as.matrix(model1, regex_pars = "b[(Intercept) item:[0-9]+]") 
  return(output)
}

PostSamplesEB <- function(data){  
  #gets posterior samples from data using a dataframe of n, p using empirical bayes. Should be more efficient
  
  # Args:
  #   matrix of N rows and 2 columns (n, y) where n is attempts and y is successes. Output of SimData
  #
  # Returns: 
  #   one matrix of posterior samples. The matrix has one row for each iteration, one column for each item parameter estimated
  # 
  # Dependencies: lme4, mgcv
  library(mgcv)
  library(lme4)
  
  model1 <- glmer(cbind(y, n - y) ~ (1|item), data = as.data.frame(data),
                       family = binomial(link=logit))
  coef <- fixef(model1)[1] + ranef(model1)$item #gives only random effects, need to add fix effects
  #varcov of fixed and random effects
  fix_var <- vcov(model1)[1]
  vc <- matrix(nrow = nrow(coef), ncol = nrow(coef), 0)
  ran_vars <- attr(ranef(model1, condVar=TRUE)[[1]], "postVar") 
  diag(vc) <- fix_var + ran_vars #bc var(sum) = sum(vars)
  output <- rmvn(1000, coef$'(Intercept)', vc) #creates posterior
  return(output)
}

RunSimulation <- function(N = 10, a_p = 1, b_p = 1, n_min = 10, n_max = 30, a_n = 1, b_n = 1, #data
                          n_assignment_method = "ascending", 
                          rankPriority = "top", rankSteepness = .9, #rankWeights
                          parameter = NULL, loss = 2, f=identity, #ranking settings
                          n_sim = 1,
                          fileRoot = "/Users/cora/git_repos/RankingMethods/results/"){
  #combines all the above functions to run simulations
  # Args:
  #   for SelectNP:
  #   N: number of items to rank
  #   a_p: Shape parameter alpha for beta distribution to determine gaps in p. Allows for equal or nonequal gap size.
  #   b_p: Shape parameter beta for beta distribution to determine gaps in p. Allows for equal or nonequal gap size.
  #   n_min: minimum number of counts/tries for each binomial variable
  #   n_max: maximum number of counts/tries for each binomial variable
  #   a_n: Shape parameter alpha for beta distribution to determine gaps in n. Allows for equal or nonequal gap size.
  #   b_n: Shape parameter alpha for beta distribution to determine gaps in n. Allows for equal or nonequal gap size.
  #   n_assignment_method. Possibilities: "ascending" for assign in order, "descending" for assign in reverse order, 
  #     "random" for random assignment
  #   rankPriority: can be a list
  #   rankSteepness: can be a list
  #   loss: an exponent indicating the loss function for ranking. options: 2=square, 1=absolute, 0=zero can be a list
  #   f = scale on which to rank. can be a list
  #   n_sim: number of simulations. (reps)
  #   fileRoot: file path used to create file for ranking results df
  #
  # Returns: 
  #   list of matrices of posterior samples, one column for each item
  #   saves .RData of settings, totalLoss, and ranking
  # 
  # Dependencies: rstanarm, clue
  settings <- SelectNP(N, a_p, b_p, n_min, n_max, a_n, b_n, n_assignment_method) #this happens once per experiment
  
  rankWeights <- as.data.frame(matrix(nrow = 0, ncol = 3))
  names(rankWeights) <- c("rw", "rankPriority", "rankSteepness")
  for (rp in rankPriority){
    for (rs in rankSteepness){
      rw <- list(as.double(RankingWeights(numItems = N, priority = rp, steepness = rs)))
      rankWeights[nrow(rankWeights) + 1,] <- list(I(rw), rp, rs)
    }
  }

  for (i in 1:n_sim){   #for each simulation
    data <- SimData(settings)
    post <- PostSamples(data)

    for (l in loss){ #loss types square and absolute
      for (iden in f){
        for (rp in rankPriority){
          for (rs in rankSteepness){
            rankFunctionResult <- WeightedLossRanking(sampleMatrix = post, parameter = parameter, loss = l, f=iden,
                                rankWeights = filter(rankWeights, rankPriority == rp, rankSteepness == rs)$rw[[1]])

            totalLoss <- as.numeric(sum(rankFunctionResult[[1]])) #this is an nxn rank matrix, so loss = sum(matrix)
            ranks <- list(as.integer(rankFunctionResult[[2]]))
            #adds parameters, total loss, and rankings to returnDF data frame as a new row of data
            currResults[1, 1:14] <- c(i, N, a_p, b_p, n_min, n_max, a_n, b_n, #TODO need to figure out way to save that doesnt overwrite
                           n_assignment_method,
                           rp, rs,
                           iden, l, totalLoss)
            currResults$ranking[1] <- ranks
          returnDF <- rbind(returnDF, currResults)
        }
      }
    }
    }
  }
  return(returnDF)
}

# A testing metric for use with simulated data
##function metric to see if rankObject's top ranked items match true top items MATRIX
RankMetric <- function(rankObject = NULL, settings = NULL, order = "largest", topN = 5){
  # function metric to see if our top number matches true top five for Binomial model
  #   
  # Args:
  #   rankObject: an output of WeightedLossRanking.
  #   originalData: a data frame with column of item IDs, n, true probabilities
  #   order: largest (largest to smallest) or smallest (smallest to largest)
  #   topN: an integer number of top items to compare
  #
  # Returns:
  #   logical vector
  #
  # Dependencies: rstan, clue, dplyr
  
  rankedData <- array(data = NA, dim=c(length(settings[,1]), 4))
  rankedData[,1:3] <- settings
  rankedData[,4] <- as.integer(rankObject) #adds rank order from WeightedLossRanking (rank orders items from smallest to highest)
  
  if (order == "largest"){
    true <- rankedData[order(rankedData[,3]),] #sort by TRUE p
    rankedData <- rankedData[order(rankedData[,4]),] #sort by calculated rank (col 4)
  } else if (order == "smallest"){
    true <- rankedData[order(-rankedData[,3]),] #sort by TRUE p #TODO need to reverse
    rankedData <- rankedData[order(-rankedData[,4]),] #sort by calculated rank (col 4)
  } else {
    stop("order must be input as either 'largest' or 'smallest'")
  }
  #check if each item in true top N is in ranking top N, return boolean
  return(true[1:10, 1] %in% rankedData[1:10, 1])
}
