###################################################
# Title: visualize SNC Rscript 
# Author: Gaku YAMANO
# Date: 2025/08/22
###################################################

# load packages
library(ncdf4)
library(fields)
source("../../config.R")

#######################################################
#################### Setting items ####################
#######################################################
# Specify the color palette
SNC_palette <- colorRampPalette(c("white", "blue", 
                                   "green", "yellow", 
                                   "orange", "red"))(500)

# Chunk size (number of time steps to process in one batch)
# Smaller values reduce memory footprint; increase for speed.
chunk_size <- 10

############################################################
#################### Processing Part #######################
############################################################
ncin <- nc_open(input_file)
alltimes <- ncvar_get(ncin, "time")
x <- ncvar_get(ncin, "x")
y <- ncvar_get(ncin, "y")
z <- ncvar_get(ncin, "z")

# pick center y-index (1-based)
center_y_index <- max(1L, as.integer(length(y) / 2))

# axes for plotting (km)
x_km <- x * 1e-3
z_km <- z * 1e-3

# Which time indices to process
time_idx_vec <- if (isTRUE(output_alltime)) seq_along(alltimes) else length(alltimes)

# Pass 1: determine global color scale across requested times by streaming slices
SNC_min <- Inf
SNC_max <- -Inf

nx <- length(x)
nz <- length(z)

for (ti in time_idx_vec) {
  # Read one time-slice at center Y: result is matrix [nx, nz]
  slice <- ncvar_get(
    ncin, "SNC",
    start = c(1, center_y_index, 1, ti),
    count = c(nx, 1, nz, 1),
    collapse_degen = TRUE
  )
  # Update global min/max (ignore NA/Inf)
  if (!is.null(slice)) {
    smin <- suppressWarnings(min(slice, na.rm = TRUE))
    smax <- suppressWarnings(max(slice, na.rm = TRUE))
    if (is.finite(smin)) SNC_min <- min(SNC_min, smin)
    if (is.finite(smax)) SNC_max <- max(SNC_max, smax)
  }
}

# Safety: if data are all NA, fall back to [0,1]
if (!is.finite(SNC_min) || !is.finite(SNC_max) || SNC_min == SNC_max) {
  SNC_min <- 0
  SNC_max <- 1
}

# make plot function
plot_SNC_slice <- function(time_val, slice_data) {
  
  base_filename <- paste("SNC_XZ.", sprintf("%05d", as.numeric(time_val)), ".pdf", sep = "")
  pdf_filename <- file.path(output_dir, base_filename)
  
  pdf(pdf_filename, width = pdf_width, height = pdf_height)
  
  # plot contour
  fields::image.plot(x_km, z_km, slice_data,
        col = SNC_palette,
        zlim = c(SNC_min, SNC_max),
        main = paste("Super-droplets number concentration (Time =", time_val, "s)"),
        xlab = "X [km]",
        ylab = "Z [km]", 
        xaxt = "n",
        yaxt = "n"
  )
  
  # plot axis
  x_ticks <- pretty(range(x_km), n = 10) 
  axis(side = 1, at = x_ticks, labels = sprintf("%.1f", x_ticks))
  y_ticks <- pretty(range(z_km), n = 8) 
  axis(side = 2, at = y_ticks, labels = sprintf("%.1f", y_ticks), las = 1)
  
  # close PDF device
  dev.off()
}

# plot processing
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Pass 2: read-and-plot in chunks
total <- length(time_idx_vec)
if (total > 0) {
  for (i in seq(1, total, by = chunk_size)) {
    idx_range <- i:min(i + chunk_size - 1, total)
    for (k in idx_range) {
      ti <- time_idx_vec[k]
      tval <- alltimes[ti]
      cat(sprintf("processing time = %s [s]\n", tval))
      slice <- ncvar_get(
        ncin, "SNC",
        start = c(1, center_y_index, 1, ti),
        count = c(nx, 1, nz, 1),
        collapse_degen = TRUE
      )
      plot_SNC_slice(time_val = tval, slice_data = slice)
    }
  }
}

nc_close(ncin)

cat(paste("All plots saved in '", output_dir, "' directory.\n", sep = ""))