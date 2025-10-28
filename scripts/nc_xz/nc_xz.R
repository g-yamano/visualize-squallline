###################################################
# Title: visualize NC Rscript 
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
NC_palette <- colorRampPalette(c("white", "blue", 
                                   "green", "yellow", 
                                   "orange", "red"))(500)

# Chunk size (number of time steps to process in one batch)
# Smaller values reduce memory footprint; increase for speed.
chunk_size <- 10

# Scale factor for NC values
#nc_scale <- 15.625 * 10^6
nc_scale <- 1.0 * 10^0

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
# initialize to extremes so min/max come from data
NC_min <- Inf
NC_max <- -Inf

nx <- length(x)
nz <- length(z)

for (ti in time_idx_vec) {
  # Read one time-slice at center Y: result is matrix [nx, nz]
  slice <- ncvar_get(
    ncin, "NC",
    start = c(1, center_y_index, 1, ti),
    count = c(nx, 1, nz, 1),
    collapse_degen = TRUE
  )
  # Apply scaling
  slice <- slice * nc_scale
  # Update global min/max (ignore NA/Inf)
  if (!is.null(slice)) {
    smin <- suppressWarnings(min(slice, na.rm = TRUE))
    smax <- suppressWarnings(max(slice, na.rm = TRUE))
    if (is.finite(smin)) NC_min <- min(NC_min, smin)
    if (is.finite(smax)) NC_max <- max(NC_max, smax)
  }
}

# Safety: if data are all NA or constant, fall back to a small default range
if (!is.finite(NC_min) || !is.finite(NC_max) || NC_min == NC_max) {
  NC_min <- 0
  NC_max <- 1
}

# make plot function
plot_NC_slice <- function(time_val, slice_data) {
  
  base_filename <- paste("NC_XZ.", sprintf("%05d", as.numeric(time_val)), ".pdf", sep = "")
  pdf_filename <- file.path(output_dir, base_filename)
  
  pdf(pdf_filename, width = pdf_width, height = pdf_height)
  
  # plot contour
  fields::image.plot(x_km, z_km, slice_data,
        col = NC_palette,
        #ylim = c(0,15.0),
        ylim = range(z_km),
        zlim = c(NC_min, NC_max),
        #zlim = c(0, 256),
        main = paste("Real-droplets number concentration (Time =", time_val, "s)"),
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
        ncin, "NC",
        start = c(1, center_y_index, 1, ti),
        count = c(nx, 1, nz, 1),
        collapse_degen = TRUE
      )
      # Apply scaling
      slice <- slice * nc_scale
      plot_NC_slice(time_val = tval, slice_data = slice)
    }
  }
}

nc_close(ncin)

cat(paste("All plots saved in '", output_dir, "' directory.\n", sep = ""))
