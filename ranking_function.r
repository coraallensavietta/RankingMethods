### Weighted Loss Function for Ranking by Position ###

## Cora Allen-Coleman Spring 2018 ##

  # Includes:
    # Weighted Loss Ranking Function
    # Weight Creation Function


library(rstan)
library(clue)

### Ranking Function for Extracting Parameters and Ranking ### 

WeightedLossRanking <- function(model = NULL, sampleMatrix = NULL, parameter = NULL, loss = 2,  f=identity, 
                                rankweights = rep(1, times = n), itemweights = rep(1, times = n), lossTotal = FALSE){
# Computes optimal ranking for a list of estimates
#   
# Args:
#   model: a stan model for the estimates
#   sampleMatrix: a matrix of samples. dim = n samples by n items. Result of PostSamples function
#   parameter: parameter to rank, as a string. Only necessary if inputting model rather than sampleMatrix.
#   loss: an exponent indicating the loss function for ranking. options: 2=square, 1=absolute, 0=zero
#   f: scale for loss calculation. options: identity, rank
#   rankweights: a vector of length equal to number of items to be ranked. Weights positions.
#   itemweights: a vector of length equal to number of items to be ranked. Weights items.
#   lossTotal: if TRUE, provides total loss
#
# Returns:
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
        LossRnk[i,j] <- rankweights[j]*itemweights[i]*mean(m_rho_i[i,]!=m_rho_j[j,])
        }
    }
    if (lossTotal == TRUE){
      print(paste("Total Loss: ", sum(LossRnk)))
    }
    return(solve_LSAP(LossRnk))
  } else{ #all other loss cases
    LossRnk <- matrix(NA,n,n)
    for (i in 1:n) {
      for (j in 1:n) {
        LossRnk[i,j] <- rankweights[j]*itemweights[i]*mean(abs((rho_i[i,]-rho_j[j,]))^loss)
      }
    }
    if (lossTotal == TRUE){
      print(paste("Total Loss: ", sum(LossRnk)))
    }
    return(solve_LSAP(LossRnk))
  }
}

RankingWeights <- function(priority = "top"){
  # Computes optimal ranking for a list of estimates. Largest weight is always 1.
  #   
  # Args:
  #   priority: focus for ranking. "even" to evenly weight, "top" to prioritize top ranked items, "bottom" for bottom ranked items, "both" for both. 
  #   steepness: size of e
  #
  # Returns:
  #   vector of weights
  

  
}

#TODO notes wed may 8
#write a function to generate weights

#Weights: 
# w_i = e^(i-1) where i is the rank position (vary e here. e = 1 is unweighted. then decrease e size 3 total e sizes: slow, gradual, steeply)
# reverse version (you care about last only)
# curve version (care about both ends, dont care about middle). Need to know middle rank. Then 
# weights = c(1, e, e^2, ..., e^(n+1/2) middle, ..., e^2, e, 1)
# we should always make the top weight 1 so that things are comperable (always relative to largest)