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
#' write.csv(prop.df, "frog_call_prop.csv", row.names = FALSE)
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
#' @importFrom future plan multisession
#' @importFrom tuneR readWave
#' @importFrom future.apply future_lapply
#' @importFrom utils write.csv
#' @return A data frame containing the extracted call properties.
#' @export

get_vocal_props <- function(path = "examples/") {
  ## Function to extract call properties from a single WAV file
  get_properties <- function(call_file) {
    call <- readWave(call_file)
    call_data <- call@left

    max_amplitude <- max(call_data)
    min_amplitude <- min(call_data)
    max_index <- which.max(call_data)
    end_index <- length(call_data)

    rise_time_index <- which(call_data[1:max_index] > 0.1 * max_amplitude)[1]
    if (is.na(rise_time_index)) rise_time_index <- 1
    rise_time <- (max_index - rise_time_index) / call@samp.rate

    fall_time_index <- which(call_data[max_index:end_index] < 0.1 * max_amplitude)[1]
    if (!is.na(fall_time_index)) {
      fall_time_index <- fall_time_index + max_index - 1
    } else {
      fall_time_index <- end_index
    }
    fall_time <- (fall_time_index - max_index) / call@samp.rate
    call_duration <- (end_index - rise_time_index) / call@samp.rate

    power <- mean(call_data^2)
    delta_power_db <- 10 * log10(power)

    fft_result <- fft(call_data)
    fft_magnitude <- Mod(fft_result)
    freq <- seq(0, length(fft_result) - 1) * (call@samp.rate / length(fft_result))

    half_length <- length(fft_magnitude) / 2
    peak_indices <- order(fft_magnitude[1:half_length], decreasing = TRUE)
    dominant_freq <- freq[peak_indices[1]]
    low_peak_frequency <- freq[peak_indices[2]]
    avg_freq <- mean(freq[1:half_length][which(fft_magnitude[1:half_length] > 0)])
    avg_wavelength <- 343 / avg_freq

    non_zero_indices <- which(fft_magnitude > 0)
    signal_bandwidth <- max(freq[non_zero_indices]) - min(freq[non_zero_indices])

    spectral_centroid <- sum(freq[1:half_length] * fft_magnitude[1:half_length]) / sum(fft_magnitude[1:half_length])

    high_peak_frequency <- freq[which.max(fft_magnitude[(half_length + 1):length(fft_magnitude)]) + half_length]

    zcr <- length(which(diff(sign(call_data)) != 0)) / length(call_data)

    dominant_frequency_indices <- which(freq[1:half_length] == dominant_freq)
    if (length(dominant_frequency_indices) > 0) {
      occurrences <- length(dominant_frequency_indices)
      rate_of_dominant_call <- occurrences / (call@samp.rate / length(call_data))
    } else {
      rate_of_dominant_call <- NA
    }

    call_properties <- data.frame(
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
      Signal_Bandwidth = signal_bandwidth,
      Spectral_Centroid = spectral_centroid,
      Zero_Crossing_Rate = zcr,
      Rate_of_Dominant_call = rate_of_dominant_call
    )

    call_properties[] <- lapply(call_properties, function(x) {
      if (is.numeric(x)) format(x, scientific = FALSE) else x
    })

    return(call_properties)
  }

  start_time <- Sys.time()

  call_files <- list.files(path, pattern = "\\.wav$", full.names = TRUE)
  if (length(call_files) == 0) {
    warning("No .wav files found in path: ", path)
    return(NULL)
  }

  ## Parallel setup
  plan("multisession")
  on.exit(plan("sequential"), add = TRUE)

  cat("Total files to process:", length(call_files), "\n")

  progress_function <- function(file_name) {
    cat("Completed:", basename(file_name), "\n")
  }

  results_list <- future_lapply(call_files, function(file) {
    progress_function(file)
    get_properties(file)
  })

  results_df <- do.call(rbind, results_list)

  end_time <- Sys.time()
  processing_time <- end_time - start_time
  cat("Processing completed in:", round(as.numeric(processing_time, units = "secs"), 2), "seconds.\n")

  return(results_df)
}
