#' @title Sobol' Sensitivity Analysis for General ODE Models
#'
#' @description
#'  \code{ODEsobol.default} is the default method of \code{\link{ODEsobol}}. It
#'  performs the variance-based Sobol' sensitivity analysis for general ODE 
#'  models.
#'
#' @param mod [\code{function(Time, State, Pars)}]\cr
#'   model to examine, supplied in the manner as needed for 
#'   \code{\link[deSolve]{ode}} (see example below).
#' @param pars [\code{character(k)}]\cr
#'   names of the parameters to be included as input variables in the Sobol'
#'   sensitivity analysis.
#' @param state_init [\code{numeric(z)}]\cr
#'   vector of \code{z} initial values. Must be named (with unique names).
#' @param times [\code{numeric}]\cr
#'   points of time at which the sensitivity analysis should be executed (vector
#'   of arbitrary length). The first point of time must be greater than zero.
#' @param n [\code{integer(1)}]\cr
#'   number of random parameter values used to estimate the Sobol' sensitivity 
#'   indices by Monte Carlo simulation. Defaults to 1000.
#' @param rfuncs [\code{character(1} or \code{k)}]\cr
#'   names of the functions used to generate the \code{n} random values
#'   for the \code{k} parameters. Can be of length 1 or \code{k}. If of length 
#'   1, the same function is used for all parameters. Defaults to 
#'   \code{"runif"}, so a uniform distribution is assumed for all parameters.
#' @param rargs [\code{character(1} or \code{k)}]\cr
#'   arguments to be passed to the functions in \code{rfuncs}. Can be of length 
#'   1 or \code{k}. If of length 1, the same arguments are used for all 
#'   parameters. Each element of \code{rargs} has to be a string of the form 
#'   \code{"tag1 = value1, tag2 = value2, ..."}, see example below. Default is 
#'   \code{"min = 0, max = 1"}, so (together with the default value of 
#'   \code{rfuncs}) a uniform distribution on [0, 1] is assumed for all 
#'   parameters.
#' @param sobol_method [\code{character(1)}]\cr
#'   either \code{"Jansen"} or \code{"Martinez"}, specifying which modification
#'   of the variance-based Sobol' method shall be used. Defaults to 
#'   \code{"Martinez"}.
#' @param ode_method [\code{character(1)}]\cr
#'   method to be used for solving the differential equations, see 
#'   \code{\link[deSolve]{ode}}. Defaults to \code{"lsoda"}.
#' @param parallel_eval [\code{logical(1)}]\cr
#'   logical indicating if the evaluation of the ODE model shall be performed
#'   parallelized.
#' @param parallel_eval_ncores [\code{integer(1)}]\cr
#'   number of processor cores to be used for parallelization. Only applies if
#'   \code{parallel_eval = TRUE}. If set to \code{NA} (as per default) and 
#'   \code{parallel_eval = TRUE}, 1 processor core is used.
#' @param ... further arguments passed to or from other methods.
#'
#' @return 
#'   List of length \code{length(state_init)} and of class \code{ODEsobol} 
#'   containing in each element a list of the Sobol' sensitivity analysis 
#'   results for the corresponding \code{state_init}-variable (i.e. first order 
#'   sensitivity indices \code{S} and total sensitivity indices \code{T}) for 
#'   every point of time in the \code{times} vector. This list has an extra 
#'   attribute \code{"sobol_method"} where the value of argument 
#'   \code{sobol_method} is stored (either \code{"Jansen"} or 
#'   \code{"Martinez"}).
#'
#' @details
#'   Function \code{\link[deSolve]{ode}} from \code{\link[deSolve]{deSolve}} is 
#'   used to solve the ODE system.
#'   
#'   The sensitivity analysis is done for all state variables and all
#'   timepoints simultaneously. If \code{sobol_method = "Jansen"},
#'   \code{\link[sensitivity]{soboljansen}} from the package 
#'   \code{\link[sensitivity]{sensitivity}}
#'   is used to estimate the Sobol' sensitivity indices and if 
#'   \code{sobol_method = "Martinez"}, \code{\link[sensitivity]{sobolmartinez}}
#'   is used (also from the package \code{\link[sensitivity]{sensitivity}}).
#'
#' @note 
#'   If the evaluation of the model function takes too long, it might be 
#'   helpful to try a different type of ODE-solver (argument \code{ode_method}). 
#'   The \code{ode_method}s \code{"vode"}, \code{"bdf"}, \code{"bdf_d"}, 
#'   \code{"adams"}, \code{"impAdams"} and \code{"impAdams_d"} 
#'   might be faster than the standard \code{ode_method} \code{"lsoda"}.
#'   
#'   If \code{n} is too low, the Monte Carlo estimation of the sensitivity 
#'   indices might be very bad and even produce first order indices < 0 or
#'   total indices > 1. First order indices in the interval [-0.05, 0) and total 
#'   indices in (1, 1.05] are considered as minor deviations and set to 0 
#'   resp. 1 without a warning. First order indices < -0.05 or total indices 
#'   > 1.05 are considered as major deviations. They remain unchanged and a 
#'   warning is thrown. Up to now, first order indices > 1 or total indices < 0
#'   haven't occured yet. If this should be the case, please contact the package
#'   author.
#'
#' @author Stefan Theers, Frank Weber
#' @references J. O. Ramsay, G. Hooker, D. Campbell and J. Cao, 2007,
#'   \emph{Parameter estimation for differential equations: a generalized 
#'   smoothing approach}, Journal of the Royal Statistical Society, Series B, 
#'   69, Part 5, 741--796.
#' @seealso \code{\link[sensitivity]{soboljansen},
#'   \link[sensitivity]{sobolmartinez},
#'   \link{plot.ODEsobol}}
#' 
#' @examples
#' ##### Lotka-Volterra equations #####
#' # The model function:
#' LVmod <- function(Time, State, Pars) {
#'   with(as.list(c(State, Pars)), {
#'     Ingestion    <- rIng  * Prey * Predator
#'     GrowthPrey   <- rGrow * Prey * (1 - Prey/K)
#'     MortPredator <- rMort * Predator
#'     
#'     dPrey        <- GrowthPrey - Ingestion
#'     dPredator    <- Ingestion * assEff - MortPredator
#'     
#'     return(list(c(dPrey, dPredator)))
#'   })
#' }
#' # The parameters to be included in the sensitivity analysis and their lower 
#' # and upper boundaries:
#' LVpars  <- c("rIng", "rGrow", "rMort", "assEff", "K")
#' LVbinf <- c(0.05, 0.05, 0.05, 0.05, 1)
#' LVbsup <- c(1.00, 3.00, 0.95, 0.95, 20)
#' # The initial values of the state variables:
#' LVinit  <- c(Prey = 1, Predator = 2)
#' # The timepoints of interest:
#' LVtimes <- c(0.01, seq(1, 50, by = 1))
#' set.seed(59281)
#' # Sobol' sensitivity analysis (here only with n = 500, but n = 1000 is
#' # recommended):
#' # Warning: The following code might take very long!
#' \donttest{
#' LVres_sobol <- ODEsobol(mod = LVmod,
#'                         pars = LVpars,
#'                         state_init = LVinit,
#'                         times = LVtimes,
#'                         n = 500,
#'                         rfuncs = "runif",
#'                         rargs = paste0("min = ", LVbinf,
#'                                        ", max = ", LVbsup),
#'                         sobol_method = "Martinez",
#'                         ode_method = "lsoda",
#'                         parallel_eval = TRUE,
#'                         parallel_eval_ncores = 2)
#' }
#' 
#' ##### FitzHugh-Nagumo equations (Ramsay et al., 2007) #####
#' FHNmod <- function(Time, State, Pars) {
#'   with(as.list(c(State, Pars)), {
#'     
#'     dVoltage <- s * (Voltage - Voltage^3 / 3 + Current)
#'     dCurrent <- - 1 / s *(Voltage - a + b * Current)
#'     
#'     return(list(c(dVoltage, dCurrent)))
#'   })
#' }
#' # Warning: The following code might take very long!
#' \donttest{
#' FHNres_sobol <- ODEsobol(mod = FHNmod,
#'                          pars = c("a", "b", "s"),
#'                          state_init = c(Voltage = -1, Current = 1),
#'                          times = seq(0.1, 50, by = 5),
#'                          n = 500,
#'                          rfuncs = "runif",
#'                          rargs = c(rep("min = 0.18, max = 0.22", 2),
#'                                    "min = 2.8, max = 3.2"),
#'                          sobol_method = "Martinez",
#'                          ode_method = "adams",
#'                          parallel_eval = TRUE,
#'                          parallel_eval_ncores = 2)
#' }
#' # Just for demonstration purposes: The use of different distributions for the 
#' # parameters (here, the distributions and their arguments are chosen 
#' # completely arbitrarily):
#' # Warning: The following code might take very long!
#' \donttest{
#' demo_dists <- ODEsobol(mod = FHNmod,
#'                        pars = c("a", "b", "s"),
#'                        state_init = c(Voltage = -1, Current = 1),
#'                        times = seq(0.1, 50, by = 5),
#'                        n = 500,
#'                        rfuncs = c("runif", "rnorm", "rexp"),
#'                        rargs = c("min = 0.18, max = 0.22",
#'                                  "mean = 0.2, sd = 0.2 / 3",
#'                                  "rate = 1 / 3"),
#'                        sobol_method = "Martinez",
#'                        ode_method = "adams",
#'                        parallel_eval = TRUE,
#'                        parallel_eval_ncores = 2)
#' }
#'
#' @export
#'

ODEsobol.default <- function(mod,
                             pars,
                             state_init,
                             times,
                             n = 1000,
                             rfuncs = "runif",
                             rargs = "min = 0, max = 1",
                             sobol_method = "Martinez",
                             ode_method = "lsoda",
                             parallel_eval = FALSE,
                             parallel_eval_ncores = NA, ...){

  ##### Input checks ###################################################
  
  assertFunction(mod)
  assertCharacter(pars)
  assertNumeric(state_init)
  assertNamed(state_init, type = "unique")
  assertNumeric(times, lower = 0, finite = TRUE, unique = TRUE)
  times <- sort(times)
  stopifnot(!any(times == 0))
  assertIntegerish(n, lower = 2)
  assertCharacter(rfuncs)
  if(! length(rfuncs) %in% c(1, length(pars))){
    stop("Argument \"rfuncs\" must be of length 1 or of the same length as ",
         "\"pars\"")
  }
  assertCharacter(rargs)
  if(! length(rargs) %in% c(1, length(pars))){
    stop("Argument \"rargs\" must be of length 1 or of the same length as ",
         "\"pars\"")
  }
  if(! all(sapply(rfuncs, exists))){
    stop("At least one of the supplied functions in \"rfuncs\" was not found")
  }
  stopifnot(sobol_method %in% c("Jansen", "Martinez"))
  stopifnot(ode_method %in% c("lsoda", "lsode", "lsodes","lsodar","vode", 
                              "daspk", "euler", "rk4", "ode23", "ode45", 
                              "radau", "bdf", "bdf_d", "adams", "impAdams", 
                              "impAdams_d" ,"iteration"))
  assertLogical(parallel_eval, len = 1)
  assertIntegerish(parallel_eval_ncores, len = 1, lower = 1)
  if(parallel_eval && is.na(parallel_eval_ncores)){
    parallel_eval_ncores <- 1
  }

  ##### Preparation ####################################################
  
  # Number of parameters:
  k <- length(pars)
  # Number of state variables:
  z <- length(state_init)
  # Number of timepoints:
  timesNum <- length(times)
  
  # Adapt the ODE model for argument "model" of soboljansen() resp.
  # sobolmartinez():
  model_fit <- function(X){
    # Input: Matrix X with k columns, containing the random parameter 
    # combinations.
    colnames(X) <- pars
    one_par <- function(i){
      # Resolve the ODE system by using ode() from the package "deSolve":
      ode(state_init, times = c(0, times), mod, parms = X[i, ], 
          method = ode_method)[2:(timesNum + 1), 2:(z + 1), drop = FALSE]
    }
    if(parallel_eval){
      # Run one_par() on parallel nodes:
      local_cluster <- parallel::makePSOCKcluster(names = parallel_eval_ncores)
      parallel::clusterExport(local_cluster, 
                              varlist = c("ode", "mod", "state_init", "z", "X",
                                          "times", "timesNum", "ode_method"),
                              envir = environment())
      res_per_par <- parallel::parSapply(local_cluster, 1:nrow(X), one_par, 
                                         simplify = "array")
      parallel::stopCluster(local_cluster)
    } else{
      # Just use sapply() with "simplify = "array"":
      res_per_par <- sapply(1:nrow(X), one_par, simplify = "array")
    }
    res_per_state <- aperm(res_per_par, perm = c(3, 1, 2))
    dimnames(res_per_state) <- list(NULL, paste0("time", 1:timesNum), 
                                    names(state_init))
    return(res_per_state)
  }
  
  # Create the two matrices containing the parameter samples for Monte Carlo
  # estimation:
  if(length(rfuncs) == 1){
    rfuncs <- rep(rfuncs, length(pars))
  }
  if(length(rargs) == 1){
    rargs <- rep(rargs, length(pars))
  }
  rfunc_calls <- paste0(rfuncs, "(n, ", rargs, ")", collapse = ", ")
  X1 <- matrix(eval(parse(text = paste0("c(", rfunc_calls, ")"))), ncol = k)
  X2 <- matrix(eval(parse(text = paste0("c(", rfunc_calls, ")"))), ncol = k)
  colnames(X1) <- colnames(X2) <- pars
  
  ##### Sensitivity analysis ###########################################
  
  # Sensitivity analysis with either soboljansen() or sobolmartinez()
  # from package "sensitivity":
  if(sobol_method == "Jansen"){
    x <- soboljansen(model = model_fit, X1, X2, nboot = 0)
  } else if(sobol_method == "Martinez"){
    x <- sobolmartinez(model = model_fit, X1, X2, nboot = 0)
  }
  
  # Process the results:
  ST_by_state <- sobol_process(x, pars, times)
  
  # Return:
  class(ST_by_state) <- "ODEsobol"
  attr(ST_by_state, "sobol_method") <- sobol_method
  return(ST_by_state)
}
