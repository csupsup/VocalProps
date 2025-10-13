#' @title Get Frog Call Properties
#
#' @description This custom function automates the extraction of 15 commonly used temporal and spectral call properties for analyzing frog calls.
#' Cleaned and standardized call samples must be placed in one folder, and the call format should be in .wav. 
#' 
#' @param path Folder directory containing the calls.
#'
#' @examples
#' call.dir <- system.file("extdata", "calls", package = "VocalProps")
#'
#' prop.df <- get_vocal_props(path = call.dir)
#'
#' head(prop.df)
#' 
#' ## write results to a csv 
#' #write.csv(prop.df, "frog_call_prop.csv", row.names = FALSE)
#'
#' @references
#' Köhler J, Jansen M, Rodríguez A, Kok PJR, Toledo LF, Emmrich M, Glaw F, Haddad CFB, Rödel M-O, Vences M (2017). The use of bioacoustics in anuran taxonomy: theory, terminology, methods and recommendations for best practice. Zootaxa 4251: 1–124. https://doi.org/10.11646/zootaxa.4251.1.1
#'
#' Xie J, Towsey M, Zhang J, Roe P (2018) Frog call classification: a survey. Artificial Intelligence Review, 49: 375–391.
#'
#' Xie J, Towsey M, Zhang J, Roe P (2020) Investigation of Acoustic and Visual Features for Frog Call Classification. Journal of Signal Processing Systems, 92: 23–36.
#'
#' Prasad VK, Chuang M-F, Das A, Ramesh K, Yi Y, Dinesh KP, Borzée A (2022) Coexisting good neighbours: acoustic and calling microhabitat niche partitioning in two elusive syntopic species of balloon frogs, Uperodon systoma and U. globulosus (Anura: Microhylidae) and potential of individual vocal signatures. BMC Zoology, 7: 27. 
#'
#' @importFrom stats fft
#' @importFrom future plan multisession sequential availableCores
#' @importFrom tuneR readWave
#' @importFrom future.apply future_lapply
#' @importFrom data.table data.table rbindlist
#' @importFrom utils txtProgressBar setTxtProgressBar
#' @importFrom zoo na.locf
#' @return A data frame containing the extracted call properties.
#' @export

get_vocal_props <- function(path = "examples/") {
  ## Extract properties from a single WAV file
  get_properties <- function(call_file) {
    call <- readWave(call_file)
    call_data <- call@left
    fs <- call@samp.rate
    N <- length(call_data)

    ## Time-domain properties
    max_amplitude <- max(call_data)
    min_amplitude <- min(call_data)
    max_index <- which.max(call_data)
    end_index <- N

    ## Rise Time (ms)
    rise_time_index <- which(call_data[1:max_index] > 0.1 * max_amplitude)[1]
    if (is.na(rise_time_index)) rise_time_index <- 1
    rise_time <- (max_index - rise_time_index) / fs * 1000

    ## Fall Time (ms)
    fall_time_index <- which(call_data[max_index:end_index] < 0.1 * max_amplitude)[1]
    if (!is.na(fall_time_index)) {
      fall_time_index <- fall_time_index + max_index - 1
    } else {
      fall_time_index <- end_index
    }
    fall_time <- (fall_time_index - max_index) / fs * 1000

    ## Call Duration (ms)
    call_duration <- (end_index - rise_time_index) / fs * 1000

    ## Power (dB)
    max_power <- max(call_data^2)
    delta_power_db <- 10 * log10(max_power)

    ## Frequency-domain properties
    fft_result <- fft(call_data)
    fft_magnitude <- Mod(fft_result)
    freq <- seq(0, N - 1) * (fs / N)
    half_length <- floor(N / 2)

    mag_half <- fft_magnitude[1:half_length]
    freq_half <- freq[1:half_length]

    ## Dominant and low peak frequencies (positive frequencies)
    peak_indices <- order(mag_half, decreasing = TRUE)
    dominant_freq <- freq_half[peak_indices[1]] / 1000
    low_peak_frequency <- if (length(peak_indices) > 1) freq_half[peak_indices[2]] / 1000 else NA

    ## High peak frequency: largest spectral peak in upper half
    upper_mag <- fft_magnitude[(half_length + 1):N]
    upper_freq <- freq[(half_length + 1):N]
    if (length(upper_mag) > 0 && any(upper_mag > 0)) {
      high_idx <- which.max(upper_mag)
      high_peak_frequency <- upper_freq[high_idx] / 1000
    } else {
      high_peak_frequency <- NA
    }

    ## Average frequency and wavelength
    avg_freq <- mean(freq_half[mag_half > 0]) / 1000
    avg_wavelength <- 343 / (avg_freq * 1000)

    ## Spectral centroid and bandwidth
    spectral_centroid <- sum(freq_half * mag_half) / sum(mag_half) / 1000
    BWspread <- sqrt(sum(((freq_half - spectral_centroid * 1000)^2) * mag_half) / sum(mag_half)) / 1000

    ## Zero Crossing Rate
    sgn <- sign(call_data)
    sgn[sgn == 0] <- NA
    sgn <- na.locf(sgn, na.rm = FALSE)
    sgn[is.na(sgn)] <- 0
    crossings <- sum(abs(diff(sgn))) / 2
    zcr <- (2 * crossings) / (N - 1)
    zcr_per_sec <- zcr * fs

    ## Dominant call rate estimation
    dominant_frequency_indices <- which(freq_half == dominant_freq * 1000)
    rate_of_dominant_call <- if (length(dominant_frequency_indices) > 0) {
      occurrences <- length(dominant_frequency_indices)
      (dominant_freq * occurrences) / (fs / N)
    } else {
      NA
    }

    ## Combine into a data.table
    call_properties <- data.table(
      File_Name = basename(call_file),
      Average_Frequency = avg_freq,
      Average_Wavelength = avg_wavelength,
      Min_Amplitude = min_amplitude,
      Max_Amplitude = max_amplitude,
      Rise_Time = rise_time,
      Fall_Time = fall_time,
      Call_Duration = call_duration,
      Delta_Power_dB = delta_power_db,
      Dominant_Frequency = dominant_freq,
      Low_Peak_Frequency = low_peak_frequency,
      High_Peak_Frequency = high_peak_frequency,
      Spectral_Centroid = spectral_centroid,
      BW_Spread = BWspread,
      Zero_Crossing_Rate = zcr_per_sec,
      Rate_of_Dominant_call = rate_of_dominant_call
    )

    return(call_properties)
  }

  ## Main Processing
  call_files <- list.files(path, pattern = "\\.wav$", full.names = TRUE)
  if (length(call_files) == 0) {
    warning("No .wav files found in path: ", path)
    return(NULL)
  }

  ## Parallel setup
  num_cores <- availableCores(logical = FALSE)
  plan(multisession, workers = num_cores)
  on.exit({
    plan(sequential)
    gc()
  }, add = TRUE)

  cat("Total files to process:", length(call_files), "\n")

  ## Progress bar
  pb <- txtProgressBar(min = 0, max = length(call_files), style = 3)

  results_list <- future_lapply(
    call_files,
    function(file) {
      res <- get_properties(file)
      setTxtProgressBar(pb, which(call_files == file))
      return(res)
    },
    future.seed = TRUE
  )

  close(pb)
  results_df <- rbindlist(results_list, fill = TRUE)

  cat("\nProcessing completed.\n")
  return(results_df)
}

