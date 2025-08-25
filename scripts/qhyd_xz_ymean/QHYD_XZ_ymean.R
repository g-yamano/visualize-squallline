###################################################
# Title: visualize Y-averaged QHYD Rscript 
# Author: Gaku YAMANO
# Date: 2025/08/23
###################################################

# load packages
library(ncdf4)
library(fields)

#######################################################
#################### Setting items ####################
#######################################################
# 1.Specify the netcdf file path
input_file_path <- file.path("../../data/", "merged-h_history.pe000000.nc")
output_dir <- "../../output/QHYD_XZ_ymean/SDM"
# 2. Specify the color palette
QHYD_palette <- colorRampPalette(c("white", "blue", 
                                   "green", "yellow", 
                                   "orange", "red"))(500)
# 3. Specify the output pdf file size
pdf_width <- 10
pdf_height <- 5
# 4 TRUE -> output all time fig, FALSE -> output only last time fig
output_alltime <- FALSE

############################################################
#################### Processing Part #######################
############################################################
ncin <- nc_open(input_file_path)
alltimes <- ncvar_get(ncin, "time")
x <- ncvar_get(ncin, "x")
y <- ncvar_get(ncin, "y")
z <- ncvar_get(ncin, "z")
QHYD_4D <- ncvar_get(ncin, "QHYD", collapse_degen = FALSE)
nc_close(ncin)

# Data processing
# --- Calculate Y-averaged QHYD ---
# The second dimension (margin=2) is the Y-axis. Calculate the mean along this axis.
QHYD <- apply(QHYD_4D, c(1, 3, 4), mean, na.rm = TRUE)

QHYD_min <- min(QHYD, na.rm = TRUE)
QHYD_max <- max(QHYD, na.rm = TRUE)
dimnames(QHYD)[[3]] <- alltimes # The 3rd dimension is now time

x_km <- x * 10^(-3)
z_km <- z * 10^(-3) 

# make plot function
plot_QHYD_slice <- function(time_val, slice_data) {
  
  base_filename <- paste("QHYD_XZ_ymean.", sprintf("%05d", as.numeric(time_val)), ".pdf", sep = "")
  pdf_filename <- file.path(output_dir, base_filename)
  
  pdf(pdf_filename, width = pdf_width, height = pdf_height)
  
  # plot contour
  fields::image.plot(x_km, z_km, slice_data,
                     col = QHYD_palette,
                     zlim = c(QHYD_min, QHYD_max),
                     main = paste("Y-averaged Total Hydrometeors (Time =", time_val, "s)"),
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

if (output_alltime) {
  for (time in alltimes) {
    cat(sprintf("processing time = %s [s]\n", time))
    QHYD_slice <- QHYD[, , as.character(time)] # The 2nd dimension is now Z
    plot_QHYD_slice(time_val = time, slice_data = QHYD_slice)
  }
} else {
  last_time <- tail(alltimes, 1)
  cat(sprintf("processing last time = %s [s]\n", last_time))
  QHYD_slice <- QHYD[, , as.character(last_time)] # The 2nd dimension is now Z
  plot_QHYD_slice(time_val = last_time, slice_data = QHYD_slice)
}

cat(paste("All plots saved in '", output_dir, "' directory.\n", sep=""))

