#' Change working directory by pattern matching
#'
#' Searches for directories matching a pattern and changes into the best match.
#' When a single match is found, navigates directly. When multiple matches exist,
#' a scoring system disambiguates: directory name length and/or full path length
#' can each be weighted toward "short" or "long" via their respective arguments.
#' Scores are additive — both \code{dirname} and \code{dirpath} can be set
#' simultaneously, each contributing to the same score vector. If no tiebreaker
#' is specified (all scores remain 0), all matches are printed and the function
#' returns invisibly without changing the working directory.
#'
#' @param name Character. Regex pattern to match against directory names.
#' @param rec Logical. Whether to search recursively. Default \code{FALSE}.
#' @param from Character. Root path for the search. Default \code{"."}.
#' @param dirname Character or NULL. Tiebreaker based on the directory's
#'   basename length: \code{"short"} favors shorter names,
#'   \code{"long"} favors longer names. Default \code{NULL} (ignored).
#' @param dirpath Character or NULL. Tiebreaker based on the full path length:
#'   \code{"short"} favors shallower paths,
#'   \code{"long"} favors deeper paths. Default \code{NULL} (ignored).
#' @param igncase Logical. Case-insensitive matching. Default \code{TRUE}.
#'   (Note: currently passed to the search but not forwarded to \code{grep};
#'   reserved for future use.)
#'
#' @return Invisibly returns the new working directory path, or the character
#'   vector of matches when no tiebreaker resolves ambiguity.
#'
#' @examples
#' \dontrun{
#' cdir("data")                          # navigate to a dir matching "data"
#' cdir("proj", rec = TRUE, dirname = "short")  # prefer shortest-named match
#' cdir("src",  rec = TRUE, dirpath = "short")  # prefer shallowest match
#' }
#'
#' @export
cdir <- function(
    name,
    rec      = FALSE,
    from     = ".",
    dirname  = NULL,
    dirpath  = NULL,
    igncase  = TRUE
) {

  if (!is.null(dirname))
    stopifnot(dirname %in% c("short", "long"))

  if (!is.null(dirpath))
    stopifnot(dirpath %in% c("short", "long"))

  dirs <- grep(
    pattern = name,
    x       = list.dirs(from, recursive = rec),
    value   = TRUE,
  )

  if (length(dirs) == 0)
    stop("No se encontró ningún directorio")

  # Exact single match: navigate immediately
  if (length(dirs) == 1) {
    setwd(dirs)
    return(invisible(getwd()))
  }

  # Scoring: each criterion adds/subtracts character counts.
  # Higher score = better match. "short" penalises length (subtracts),
  # "long" rewards it (adds). Both criteria are independent and cumulative.
  score <- rep(0, length(dirs))

  if (!is.null(dirname)) {
    if (dirname == "short")
      score <- score - nchar(basename(dirs))  # shorter basename → less subtracted → higher score
    else
      score <- score + nchar(basename(dirs))
  }

  if (!is.null(dirpath)) {
    if (dirpath == "short")
      score <- score - nchar(dirs)            # shorter full path → less subtracted → higher score
    else
      score <- score + nchar(dirs)
  }

  # No tiebreaker resolved anything: report all matches and bail
  if (all(score == 0)) {
    cat("Múltiples coincidencias:\n")
    print(dirs)
    return(invisible(dirs))
  }

  best <- which.max(score)

  setwd(dirs[best])
  invisible(getwd())
}

#' Fuzzy-find files and/or directories by pattern
#'
#' Lists all files, directories, or both under a root path and filters them
#' using a regex pattern. Combines \code{list.files()} and \code{list.dirs()}
#' so that the \code{"all"} type truly returns every path, deduplicating
#' entries that would otherwise appear in both.
#'
#' @param pattern Character. Regex pattern to match against paths.
#' @param from Character. Root path for the search. Default \code{"."}.
#' @param recursive Logical. Whether to search recursively. Default \code{TRUE}.
#' @param ignore.case Logical. Case-insensitive matching. Default \code{TRUE}.
#' @param type Character. One of \code{"all"}, \code{"file"}, or \code{"dir"}.
#'   Controls whether to search files only, directories only, or both.
#'   Matched with \code{match.arg()}, so partial strings are accepted.
#'
#' @return Character vector of matching paths (full names).
#'
#' @examples
#' \dontrun{
#' fzfind("README")                  # find any README file or dir
#' fzfind("\\.csv$", type = "file")  # find CSV files only
#' fzfind("raw", type = "dir")       # find dirs containing "raw"
#' }
#'
#' @export
fzfind <- function(
    pattern,
    from       = ".",
    recursive  = TRUE,
    ignore.case = TRUE,
    type       = c("all", "file", "dir")
) {

  type <- match.arg(type)

  files <- list.files(
    path         = from,
    recursive    = recursive,
    full.names   = TRUE,
    include.dirs = TRUE
  )

  dirs <- list.dirs(
    path      = from,
    recursive = recursive,
    full.names = TRUE
  )

  # Merge candidate pools according to requested type
  paths <- switch(
    type,
    all  = unique(c(files, dirs)),
    file = files,
    dir  = dirs
  )

  grep(
    pattern     = pattern,
    x           = paths,
    value       = TRUE,
    ignore.case = ignore.case
  )
}

#' Navigate up n levels in the directory tree
#'
#' Repeatedly applies \code{dirname()} to the current working directory
#' and then changes into the resulting path. Equivalent to running \code{cd ../..}
#' \code{n} times in a shell.
#'
#' @param n Integer. Number of levels to go up. Default \code{1}.
#'
#' @return Invisibly returns the new working directory path.
#'
#' @examples
#' \dontrun{
#' cdp()    # go up one level
#' cdp(3)   # go up three levels
#' }
#'
#' @export
cdp <- function(n = 1) {
  wd <- getwd()
  for (i in seq_len(n)) wd <- dirname(wd)
  setwd(wd)
  invisible(wd)
}

#' Change directory and list its contents
#'
#' Convenience wrapper that calls \code{cdir()} to navigate to a matching
#' directory and then returns \code{list.files()} from that location.
#'
#' @param path Character. Pattern passed to \code{cdir()} for directory matching.
#'
#' @return Character vector of filenames in the matched directory,
#'   as returned by \code{list.files()}.
#'
#' @examples
#' \dontrun{
#' cdls("data")   # navigate to "data" dir and list its files
#' }
#'
#' @export
cdls <- function(path) {
  cdir(path)
  list.files()
}

#' List files with metadata
#'
#' Returns a data frame of file metadata for all files in a directory,
#' using \code{file.info()}. Equivalent to \code{ls -la} but as an R object.
#'
#' @param path Character. Directory to inspect. Default \code{"."}.
#'
#' @return A data frame with one row per file and columns including
#'   \code{size}, \code{isdir}, \code{mtime}, \code{ctime}, \code{atime}, etc.
#'   Row names are the full file paths.
#'
#' @examples
#' \dontrun{
#' rla()           # metadata for current directory
#' rla("~/data")   # metadata for a specific directory
#' }
#'
#' @export
rla <- function(path = ".") {
  file.info(list.files(path, full.names = TRUE))
}
