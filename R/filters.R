#' Apply a zero-phase low-pass, high-pass, band-pass, or band-stop FIR filter.
#'
#' Apply a zero-phase low-pass, high-pass, band-pass, or band-stop filter of the  FIR (finite impulse response) class to every segment of an `eeg_lst`. These filters are adapted from the default filters in [MNE package](https://mne-tools.github.io) (v 0.0.17.1)  of [python](https://www.python.org/). For background information about the FIR vs IIR filters, see [here](https://martinos.org/mne/dev/auto_tutorials/plot_background_filtering.html#sphx-glr-auto-tutorials-plot-background-filtering-py).
#'
#' * `eeg_filt_low_pass()` Low-pass or high-cut filter.
#' * `eeg_filt_high_pass()` High-pass or low-cut filter.
#' * `eeg_filt_band_pass()` Band-pass filter.
#' * `eeg_filt_band_stop()` Band-stop filter.
#'
#'
#' @param .data A channel or an eeg_lst.
#' @param freq A single cut frequency for `eeg_filt_low_pass` and `eeg_filt_high_pass`, two edges for
#'   `eeg_filt_band_pass` and `eeg_filt_band_stop`.
#' @param ... Channels to apply the filters to. All the channels by default.
#' @param config Other parameters passed in a list to the ICA method. (Not implemented)
#' @param na.rm =TRUE will set to NA the entire segment that contains an NA, otherwise the filter will stop with an error.
#' @return A channel or an eeg_lst.
#' @family preprocessing functions
#'
#' @examples
#' library(dplyr)
#' library(ggplot2)
#' data("data_faces_ERPs")
#' data_ERPs_filtered <- data_faces_ERPs %>%
#'   eeg_filt_low_pass(freq = 1)
#' # Compare the ERPs
#' data_faces_ERPs %>%
#'   select(O1, O2, P7, P8) %>%
#'   plot() +
#'   facet_wrap(~.key)
#' data_ERPs_filtered %>%
#'   select(O1, O2, P7, P8) %>%
#'   plot() +
#'   facet_wrap(~.key)
#' @name filt
NULL
# > NULL

#' @rdname filt
#' @export
eeg_filt_low_pass <- function(.data, ..., freq = NULL, config = list(), na.rm = FALSE) {
  UseMethod("eeg_filt_low_pass")
}

#' @rdname filt
#' @export
eeg_filt_high_pass <- function(.data, ..., freq = NULL, config = list(), na.rm = FALSE) {
  UseMethod("eeg_filt_high_pass")
}
#' @rdname filt
#' @export
eeg_filt_band_pass <- function(.data, ..., freq = NULL, config = list(), na.rm = FALSE) {
  UseMethod("eeg_filt_band_pass")
}
#' @rdname filt
#' @export
eeg_filt_band_stop <- function(.data, ..., freq = NULL, config = list(), na.rm = FALSE) {
  UseMethod("eeg_filt_band_stop")
}

#' @export
eeg_filt_low_pass.eeg_lst <- function(.data, ..., freq = NULL, config = list(), na.rm = FALSE) {
  h <- create_filter(
    l_freq = NULL,
    h_freq = freq,
    sampling_rate = sampling_rate(.data), config = config
  )
  .data$.signal <- filt_eeg_lst(.data$.signal, ..., h = h, na.rm = na.rm)
  .data
}
#' @export
eeg_filt_high_pass.eeg_lst <- function(.data, ..., freq = NULL, config = list(), na.rm = FALSE) {
  h <- create_filter(
    l_freq = freq,
    h_freq = NULL,
    sampling_rate = sampling_rate(.data), config = config
  )
  .data$.signal <- filt_eeg_lst(.data$.signal, ..., h = h, na.rm = na.rm)
  .data
}
#' @export
eeg_filt_band_stop.eeg_lst <- function(.data, ..., freq = NULL, config = list(), na.rm = FALSE) {
  if (length(freq) != 2) stop("freq should contain two frequencies.")
  if (freq[1] <= freq[2]) {
    stop("The first argument of freq should be larger than the second one.")
  }

  h <- create_filter(
    l_freq = freq[1],
    h_freq = freq[2],
    sampling_rate = sampling_rate(.data), config = config
  )
  .data$.signal <- filt_eeg_lst(.data$.signal, ..., h = h, na.rm = na.rm)
  .data
}
#' @export
eeg_filt_band_pass.eeg_lst <- function(.data, ..., freq = NULL, config = list(), na.rm = FALSE) {
  if (length(freq) != 2) stop("freq should contain two frequencies.")
  if (freq[1] >= freq[2]) {
    stop("The first argument of freq should be smaller than the second one.")
  }

  h <- create_filter(
    l_freq = freq[1],
    h_freq = freq[2],
    sampling_rate = sampling_rate(.data), config = config
  )
  .data$.signal <- filt_eeg_lst(.data$.signal, ..., h = h, na.rm = na.rm)
  .data
}
#' @noRd
filt_eeg_lst <- function(.signal, ..., h, na.rm = FALSE) {
  .signal <- data.table::copy(.signal)
 
  ch_sel <- sel_ch(.signal, ...)

  if (na.rm == FALSE) {
    NA_channels <- ch_sel[.signal[, purrr::map_lgl(.SD, anyNA), .SDcols = (ch_sel)]]
    if (length(NA_channels) > 0) {
      stop("Missing values in the following channels: ", paste(NA_channels, sep = ","), "; use na.rm =TRUE, to proceed setting to NA the entire segment that contains an NA", call. = FALSE)
    }
  }

  .signal[, (ch_sel) := lapply(.SD, overlap_add_filter, h),
    .SDcols = (ch_sel), by = ".id"
  ]
  .signal
}
