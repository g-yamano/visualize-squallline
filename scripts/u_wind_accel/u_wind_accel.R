###################################################
# Title: visualize CNVG_dU Rscript 
# Author: Gaku YAMANO
# Date: 2025/08/18
###################################################

# load packages
library(ncdf4)
library(fields)
source("../../config.R")

#######################################################
#################### Setting items ####################
#######################################################
# Specify the color palette
CNVG_dU_palette <- colorRampPalette(c("white", "red", 
                                   "yellow"))(500)

############################################################
#################### Processing Part #######################
############################################################
ncin <- nc_open(input_file)
alltimes <- ncvar_get(ncin, "time")
x <- ncvar_get(ncin, "x")
y <- ncvar_get(ncin, "y")
z <- ncvar_get(ncin, "z")
center_y_index <- as.integer(length(y) / 2)
CNVG_dU <- ncvar_get(ncin, "CNVG_dU", collapse_degen = FALSE)
nc_close(ncin)

# Data processing
CNVG_dU_min <- min(CNVG_dU)
CNVG_dU_max <- max(CNVG_dU)
dimnames(CNVG_dU)[[4]] <- alltimes

x_km <- x * 10^(-3)
z_km <- z * 10^(-3) 

# make plot function
plot_CNVG_dU_slice <- function(time_val, slice_data) {
  
  base_filename <- paste("CNVG_dU_XZ.", sprintf("%05d", as.numeric(time_val)), ".pdf", sep = "")
  pdf_filename <- file.path(output_dir, base_filename)
  
  pdf(pdf_filename, width = pdf_width, height = pdf_height)
  
  # plot contour
  fields::image.plot(x_km, z_km, slice_data,
        col = CNVG_dU_palette,
        zlim = c(CNVG_dU_min, CNVG_dU_max),
        main = paste("U wind accelaration (Time =", time_val, "s)"),
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
    CNVG_dU_slice <- CNVG_dU[, center_y_index, , as.character(time)]
    plot_CNVG_dU_slice(time_val = time, slice_data = CNVG_dU_slice)
  }
} else {
  first_time <- head(alltimes, 1)
  cat(sprintf("processing first time = %s [s]\n", first_time))
  CNVG_dU_slice <- CNVG_dU[, center_y_index, , as.character(first_time)]
  plot_CNVG_dU_slice(time_val = first_time, slice_data = CNVG_dU_slice)
}

cat(paste("All plots saved in '", output_dir, "' directory.\n", sep=""))