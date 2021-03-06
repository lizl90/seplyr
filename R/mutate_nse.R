



#' mutate non-standard evaluation interface.
#'
#' Mutate a data frame by the mutateTerms.
#' Accepts arbitrary un-parsed expressions as
#' assignments to allow forms such as "Sepal.Length >= 2 * Sepal.Width".
#' (without the quotes).
#' Terms are vectors or lists of the form "lhs := rhs".
#' Semantics are: terms are evaluated left to right if mutate_nse_split_terms==TRUE (the default).
#'
#' Note: this method as the default setting \code{mutate_nse_split_terms = TRUE}, which while
#' safer (avoiding certain known \code{dplyr}/\code{dblyr} issues) can be needlessly expensive
#' and have its own "too long sequence" issues on remote-data systems
#' (please see the side-notes of \url{http://winvector.github.io/FluidData/partition_mutate.html} for some references).
#'
#' @seealso \code{\link{mutate_se}}, \code{\link[dplyr]{mutate}}, \code{\link[dplyr]{mutate_at}}, \code{\link[wrapr]{:=}}
#'
#' @param .data data.frame
#' @param ... expressions to mutate by.
#' @param mutate_nse_split_terms logical, if TRUE into separate mutates (if FALSE instead, pass all at once to dplyr).
#' @param mutate_nse_env environment to work in.
#' @param mutate_nse_printPlan logical, if TRUE print the expression plan
#' @return .data with altered columns.
#'
#' @examples
#'
#'
#' resCol1 <- "Sepal_Long"
#' ratio <- 2
#' compCol1 <- "Sepal.Width"
#'
#' datasets::iris %.>%
#'   mutate_nse(., resCol1 := "Sepal.Length" >= ratio * compCol1,
#'                 "Petal_Short" := "Petal.Length" <= 3.5) %.>%
#'   summary(.)
#'
#'
#' @export
#'
mutate_nse <- function(.data, ...,
                       mutate_nse_split_terms = TRUE,
                       mutate_nse_env = parent.frame(),
                       mutate_nse_printPlan = FALSE) {
  # convert char vector into spliceable vector
  # from: https://github.com/tidyverse/rlang/issues/116
  mutateTerms <- substitute(list(...))
  if(!(is.data.frame(.data) || dplyr::is.tbl(.data))) {
    stop("seplyr::mutate_nse first argument must be a data.frame or tbl")
  }
  if(length(setdiff(names(mutateTerms), ""))>0) {
    stop("seplyr::mutate_nse() all assignments must be of the form a := b, not a = b")
  }
  # mutateTerms is a list of k+1 items, first is "list" the rest are captured expressions
  res <- .data
  len <- length(mutateTerms) # first slot is "list"
  if(len>1) {
    lhs <- vector(len-1, mode='list')
    rhs <- vector(len-1, mode='list')
    for(i in (2:len)) {
      ei <- mutateTerms[[i]]
      if((length(ei)!=3)||(as.character(ei[[1]])!=':=')) {
        stop("mutate_nse terms must be of the form: sym := expr")
      }
      lhs[[i-1]] <- as.character(prep_deref(ei[[2]], mutate_nse_env))
      rhs[[i-1]] <- deparse(prep_deref(ei[[3]], mutate_nse_env))
    }
    res <- mutate_se(res, lhs := rhs,
                     splitTerms = mutate_nse_split_terms,
                     env = mutate_nse_env,
                     printPlan = mutate_nse_printPlan)
  }
  res
}

