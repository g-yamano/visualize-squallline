###################################################
# Title: visualize PREC Rscript 
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
PREC_palette <- colorRampPalette(c("white", "blue", 
                                   "green", "yellow", 
                                   "red"))(500)

############################################################
#################### Processing Part #######################
############################################################
ncin <- nc_open(input_file)
alltimes <- ncvar_get(ncin, "time")
x <- ncvar_get(ncin, "x")
y <- ncvar_get(ncin, "y")
z <- ncvar_get(ncin, "z")
PREC <- ncvar_get(ncin, "PREC", collapse_degen = FALSE)
nc_close(ncin)

# Data processing
PREC_min <- min(PREC)
PREC_max <- max(PREC)
dimnames(PREC)[[3]] <- alltimes

x_km <- x * 10^(-3)
y_km <- y * 10^(-3) 

# make plot function
plot_PREC_slice <- function(time_val, slice_data) {
  
  base_filename <- paste("PREC_XY.", sprintf("%05d", as.numeric(time_val)), ".pdf", sep = "")
  pdf_filename <- file.path(output_dir, base_filename)
  
  pdf(pdf_filename, width = pdf_width, height = pdf_height)
  
  # plot contour
  fields::image.plot(x_km, y_km, slice_data,
        col = PREC_palette,
        zlim = c(PREC_min, PREC_max),
        main = paste("Precipitation (Time =", time_val, "s)"),
        xlab = "X [km]",
        ylab = "Y [km]", 
        xaxt = "n",
        yaxt = "n"
  )
  
  # plot axis
  x_ticks <- pretty(range(x_km), n = 10) 
  axis(side = 1, at = x_ticks, labels = sprintf("%.1f", x_ticks))
  y_ticks <- pretty(range(y_km), n = 8) 
  axis(side = 2, at = y_ticks, labels = sprintf("%.1f", y_ticks), las = 1)
  
  # close PDF device
  dev.off()
}

# plot processing
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

if (output_alltime) {
  for (time in alltimes) {
    cat(sprintf("processing time = %s [s]\n", time))
    PREC_slice <- PREC[, , as.character(time)]
    plot_PREC_slice(time_val = time, slice_data = PREC_slice)
  }
} else {
  last_time <- tail(alltimes, 1)
  cat(sprintf("processing last time = %s [s]\n", last_time))
  PREC_slice <- PREC[, , as.character(last_time)]
  plot_PREC_slice(time_val = last_time, slice_data = PREC_slice)
}

cat(paste("All plots saved in '", output_dir, "' directory.\n", sep=""))
