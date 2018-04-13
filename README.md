# Ranking Methods
Bayesian ranking methods implementation  

# Testing  
## ranking_testing.r    
- tests ranking_function.r using a simple normal model, normal two-level data, and simple random intercept model.  
- Step 1 listed after Step 2 for ease of testing when editing ranking_function.r  
- relies on several .stan files.  

### Tests Four Sets:    
 - small normal n = 5  
 - normal two-level data from Multilevel Models class  
 - binomial random intercept n = 10 with conflicts (cafe)  
 - NJ n = 21 county LBW  
 - IL n = 102 county LBW  

## ranking_metric.r  
- compare ranking Methods  
- could use total loss?  
- answer how often we meet our goal: how often you meet your goal (% true top 10 in ranking's top 10)?  

## ranking_function.r  
- houses WeightedLossRanking function


# Positional Loss    
## 1. Loss on Ranks   
pros:  
  - accounts for varying levels on uncertainty in the point estimates of various ranked items
cons:  
  - assumes ranks are evenly spaced (TODO check)
### a. Square Error Loss on Ranks
file: loss_on_ranks.r (function = loss_on_ranks)  
### b. Absolute Error Loss on Ranks
file: loss_on_ranks.r (function = loss_on_ranks)  
### c. Zero One Loss on Ranks
file: loss_on_ranks.r (function = loss_on_ranks)  

## 2. Loss on Probability Scale  
pros:
  - accounts for varying levels on uncertainty in the point estimates of various ranked items
cons:  
### a. Square Error Loss on Probability Scale
file:  
### b. Absolute Error Loss on Probability Scale
file:  
### c. Zero One Loss on Probability Scale
file:  

## 3. Loss on Data Scale (same as prob scale for binomial, right?)
(TODO can we be this flexible?)  
pros:  
  - accounts for varying levels on uncertainty in the point estimates of various ranked items
cons:  
  - ranking will depend on data's scale (TODO check this)
### a. Square Error Loss on Point Estimate Scale
file:    
### b. Absolute Error Loss on Probability Scale
file:  
### c. Zero One Loss on Probability Scale
file:  

## 4. Weighted Loss on Rank Scale
pros:  
  - allows users to weight ranked items or positions (or both? TODO add as 2nd step)
  - accounts for varying levels on uncertainty in the point estimates of various ranked items
cons:  
### a. Square Error Loss on Point Estimate Scale
file:   
### b. Absolute Error Loss on Probability Scale
file:  
### c. Zero One Loss on Probability Scale
file:  

# Comparison Loss
## 5. Loss on Ranks  
pros:    
  - accounts for varying levels on uncertainty in the point estimates of various ranked items
cons:    
  - assumes ranks are evenly spaced (TODO check)  
### a. Square Error Loss on Ranks  
file:  
### b. Absolute Error Loss on Ranks  
file:  
### c. Zero One Loss on Ranks  
file:  

# Loss Function-less Ranking Methods  
## 6. Rank by Posterior Means (estimates)  
file: posteriormeans.r  
pros:  
  - simple, typically used across fields
cons:  
  - ignores varying levels on uncertainty in the point estimates of various ranked items

## 7. Henderson & Newton Threshold Functions (R Value)
see their package (maybe include here)  


# Possible Additions:
- multilevel modeling from Ron's earlier student (name?) into ranking  
- comparison loss functions with weighting  
- additional ranking methods by other authors  

# Packages to Reference:
- PLMIX: An R package for modeling and clustering partially ranked data https://arxiv.org/pdf/1612.08141.pdf    
- pmr https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3665468/     
- mederrRank https://cran.r-project.org/web/packages/mederrRank/mederrRank.pdf   
- http://jmlr.csail.mit.edu/papers/volume12/weng11a/weng11a.pdf  


## Paper Timeline ##
Feb 2018: abstract to JSM (accepted April 2018)  
April 2018: draft program + outline paper  
May 2018: finish program + rough draft of methods section  
June 2018: simulations + draft paper   
July 2018: write paper, write talk, practice talk   
July 28-30: JSM talk  
August 2018: send paper to Ron for final edits, submit  

## TODO   
- fix WeightedLossRanking function when loss = 0
- make the function faster?
- ranking_metric create way to compare rankings (a metric?) could use total loss?
- ranking_metric create a metric that allows you to test how often you meet your goal
(% true top 10 in ranking's top 10).

## Function specific TODOs (older)
## Future Work Notes ##
## TODO 3 outer product of the matrix to vectorize to replace double for loops. vectorizing apply outer product
## TODO loss for zero one loss
## TODO Q: for rank, must use r function sort. How can we fix this? OR is this fine?
## TODO should there be autoscaling of original matrix to prevent numbers that are too small?
## TODO add checks for invalid inputs

## TODO Add heuristic methods for LSAP + compare. Look for papers by Louis' group

## TODO Compare weighting strategies.
##  Q: what should epsilon be? When do we have numerical stability problems?
##  LSAP might act weirdly with actual 0 weights (this is a problem with Louis)
##  what we really want is orders of magnitude between weights. (weights dont need to sum to one. To normalize, divide each by sum)
##  e.g. c(1, e, e^2, e^3) then normalize if you want. TODO question: what should epsilon be? When do we have numerical stability problem
##  Q: does our 1, e, e^2 etc work better than 1, 1, 1, 0, 0, 0, (these zeros will all be tied).
##  Epsilon losses automatically breaks ties. Mostly want to show that it doesnt change answer about top 10 + ranking of bottom set will be better.
##  Q: do I really want to have cliffs? Should it be smooth, gradual? How would we make this smooth? Are there various ways to try to get the good points of cliff functions.
##  Can you make a smooth function that performs as well as cliffs? Is there a natural cliff? (page views on google?)
##  Then is this related to threshold functions? e.g. i just care about my item, everyone else is less important
##  Smoothness might be desireable in situations where you see the whole list. (college rankings)

## TODO create visualizations: D3.js? this could be a good situation to use weights based on people's interests. Show different weight vectors.
