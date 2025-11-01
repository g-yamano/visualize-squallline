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
# Specify the color palette (smooth gradient)
SNC_palette <- colorRampPalette(c("white", "blue", "green", "yellow", "orange", "red"))(500)

# Chunk size (number of time steps to process in one batch)
# Smaller values reduce memory footprint; increase for speed.
chunk_size <- 10

# Scale factor for SNC values
snc_scale <- 15.625 * 10^6

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
# initialize from data
SNC_min <- Inf
SNC_max <- -Inf
# track smallest positive value for log scaling
SNC_min_pos <- Inf

nx <- length(x)
nz <- length(z)

for (ti in time_idx_vec) {
  # Read one time-slice at center Y: result is matrix [nx, nz]
  slice <- ncvar_get(
    ncin, "SNC",
    # read full y dimension then average over y using apply
    start = c(1, 1, 1, ti),
    count = c(nx, length(y), nz, 1),
    collapse_degen = FALSE
  )
  # slice currently has dims [nx, ny, nz]; average over y (2nd dim) -> [nx, nz]
  slice <- apply(slice, c(1,3), mean, na.rm = TRUE)
  # Apply scaling
  slice <- slice * snc_scale
  # Update global min/max (ignore NA/Inf)
  if (!is.null(slice)) {
    smin <- suppressWarnings(min(slice, na.rm = TRUE))
    smax <- suppressWarnings(max(slice, na.rm = TRUE))
    if (is.finite(smin)) SNC_min <- min(SNC_min, smin)
    if (is.finite(smax)) SNC_max <- max(SNC_max, smax)
    # smallest positive (for log scale)
    pos_vals <- slice[slice > 0]
    if (length(pos_vals) > 0) {
      pmin <- suppressWarnings(min(pos_vals, na.rm = TRUE))
      if (is.finite(pmin)) SNC_min_pos <- min(SNC_min_pos, pmin)
    }
  }
}

# Safety: if data are all NA, fall back to [0,1]
if (!is.finite(SNC_min) || !is.finite(SNC_max) || SNC_min == SNC_max) {
  SNC_min <- 0
  SNC_max <- 1
}
## Use fixed log colorbar range from 0 to 256 (map values <=0 to small epsilon)
# epsilon for values <= 0 (log-safe)
eps <- 1e-6
log2_min <- log2(eps)
log2_max <- log2(32)


# make plot function
plot_SNC_slice <- function(time_val, slice_data) {
  
  base_filename <- paste("SNC_XZ.", sprintf("%05d", as.numeric(time_val)), ".pdf", sep = "")
  pdf_filename <- file.path(output_dir, base_filename)
  
  pdf(pdf_filename, width = pdf_width, height = pdf_height)
  
  # prepare data on log2 scale for color mapping, clamp values <=0 to eps
  plot_data <- log2(pmax(slice_data, eps))

  # legend ticks to match requested scale: 0,1,5,16,32,64,128,256
  #tick_values <- c(0,1,5,16,32,64,128,256)
  tick_values <- c(0,1,5,16,32)
  tick_at <- log2(pmax(tick_values, eps))
  tick_labels <- as.character(tick_values)

  # plot contour in log2 space; legend axis shows original values
  fields::image.plot(x_km, z_km, plot_data,
    col = SNC_palette,
    ylim = c(0,15.0),
    zlim = c(log2_min, log2_max),
    axis.args = list(at = tick_at, labels = tick_labels),
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
        # read full y dimension then average over y using apply
        start = c(1, 1, 1, ti),
        count = c(nx, length(y), nz, 1),
        collapse_degen = FALSE
      )
      # average over y and apply scaling
      slice <- apply(slice, c(1,3), mean, na.rm = TRUE)
      slice <- slice * snc_scale
      plot_SNC_slice(time_val = tval, slice_data = slice)
    }
  }
}

nc_close(ncin)

cat(paste("All plots saved in '", output_dir, "' directory.\n", sep = ""))
