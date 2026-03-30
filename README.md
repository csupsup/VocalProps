## VocalProps
This custom function automates the extraction of 15 commonly used temporal and spectral call properties for analyzing frog calls. Below are the definitions for each call property:

* **Average frequency (kHz)** – the mean frequency of the call signal, calculated as the average of all frequencies present. Provides an overall measure of frequency content.

* **Average wavelength (m)** – the average wavelength of the call, calculated using the speed of sound in air divided by the average frequency. Represents the distance over which the wave pattern repeats.

* **Minimum amplitude** – the lowest amplitude value of the call signal, indicating the quietest point.

* **Maximum amplitude** – the highest amplitude value of the call signal, indicating the loudest point.

* **Rise time (ms)** – the time for the call signal to rise from a specified lower threshold (e.g., 10% of maximum amplitude) to its peak amplitude. Indicates how quickly the call reaches its loudest point.

* **Fall time (ms)** – the time for the call signal to drop from its peak amplitude to a specified lower threshold (e.g., 10% of maximum amplitude). Indicates how quickly the call diminishes.

* **Call duration (ms)** – the total duration of the call, measured from the start of the first pulse to the end of the last pulse. Represents the length of the call event.

* **Delta power (dB)** – the maximum instantaneous power of the call expressed in decibels (dB), calculated from the squared amplitude of the waveform. Provides a measure of overall loudness.

* **Dominant frequency (kHz)** – the frequency with the highest spectral amplitude, representing the most prominent frequency in the call.

* **Low peak frequency (kHz)** – the frequency corresponding to the second-largest peak in the call spectrum.

* **High peak frequency (kHz)** – the frequency corresponding to the largest spectral peak in the upper half of the spectrum, representing the most intense overtone or feature of the call.

* **Spectral centroid (kHz)** – the weighted mean frequency of the spectrum, with weights given by spectral magnitudes. Often correlates with perceived brightness of the call.

* **Signal Bandwith(kHz)** – spectral spread around the centroid, representing how dispersed the energy is. Wider bandwidth indicates more complex calls.

* **Zero crossing rate (per s)** – the rate at which the signal changes sign, calculated as the number of zero crossings per second. Provides insight into frequency content and noisiness.

* **Rate of dominant call (kHz/s)** – the occurrence rate of the dominant frequency within the call. Reflects how frequently the most prominent sound appears during the call.

**References**
1. Gingras B, Fitch WT (2013). A three-parameter model for classifying anurans into four genera based on advertisement calls. The Journal of the Acoustical Society of America, 133:547-559.
2. Köhler J, Jansen M, Rodríguez A, Kok PJR, Toledo LF, Emmrich M, Glaw F, Haddad CFB, Rödel M-O, Vences M (2017). The use of bioacoustics in anuran taxonomy: theory, terminology, methods and recommendations for best practice. Zootaxa 4251: 1–124.
3. Xie J, Towsey M, Zhang J, Roe P (2018) Frog call classification: a survey. Artificial Intelligence Review, 49: 375–391.
4. Xie J, Towsey M, Zhang J, Roe P (2020) Investigation of Acoustic and Visual Features for Frog Call Classification. Journal of Signal Processing Systems, 92: 23–36.
5. Prasad VK, Chuang M-F, Das A, Ramesh K, Yi Y, Dinesh KP, Borzée A (2022) Coexisting good neighbours: acoustic and calling microhabitat niche partitioning in two elusive syntopic species of balloon frogs, Uperodon systoma and U. globulosus (Anura: Microhylidae) and potential of individual vocal signatures. BMC Zoology, 7: 27. 

## Citation
The implementation of this package is documented in our recent work on a new Philippine miniaturized frog. Cite this paper when using the package:

Meneses, C.G., Pitogo, K.M.P, Decena, S.C.P, Supsup, C.E., and Brown, R.M. (in press). A new miniaturised *Platymantis* (Amphibia: Anura: Ceratobatrachidae) from Sibuyan and Tablas islands, Romblon Island Group, Philippines. Raffles Bulletin of Zoology. 

## Installation
Cleaned and standardized call samples must be placed in one folder, and the call format should be in .wav. 
```r
## Check and install required packages
req.pkgs <- c("devtools", "tuneR", "seewave", "future.apply", "furrr")

for (pkg in req.pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
  library(pkg, character.only = TRUE)
}

## Install "VocalProps"
install_github("csupsup/VocalProps")
```

## Using the package
```r
## Access sample calls
call.dir <- system.file("extdata", "calls", package = "VocalProps")

prop.df <- get_vocal_props(path = call.dir)

head(prop.df)
 
## Write results to a csv file
write.csv(prop.df, "frog_call_prop.csv", row.names = FALSE)
```