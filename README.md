## Description
This custom function automates the extraction of 15 commonly used temporal and spectral call properties for analyzing frog calls. 
Cleaned and standardized call samples must be placed in one folder, and the call format should be in .wav. 

## Installation
```
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
