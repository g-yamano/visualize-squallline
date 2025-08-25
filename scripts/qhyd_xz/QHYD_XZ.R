###################################################
# Title: visualize QHYD Rscript 
# Author: Gaku YAMANO
# Date: 2025/08/18
###################################################

# load packages
library(ncdf4)
library(fields)

#######################################################
#################### Setting items ####################
#######################################################
# 1.Specify the netcdf file path
input_file_path <- file.path("../../data/", "merged-h_history.pe000000.nc")
output_dir <- "../../output/QHYD_XZ/pdf"
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
center_y_index <- as.integer(length(y) / 2)
QHYD <- ncvar_get(ncin, "QHYD", collapse_degen = FALSE)
nc_close(ncin)

# Data processing
QHYD_min <- min(QHYD)
QHYD_max <- max(QHYD)
dimnames(QHYD)[[4]] <- alltimes

x_km <- x * 10^(-3)
z_km <- z * 10^(-3) 

# make plot function
plot_QHYD_slice <- function(time_val, slice_data) {
  
  base_filename <- paste("QHYD_XZ.", sprintf("%05d", as.numeric(time_val)), ".pdf", sep = "")
  pdf_filename <- file.path(output_dir, base_filename)
  
  pdf(pdf_filename, width = pdf_width, height = pdf_height)
  
  # plot contour
  fields::image.plot(x_km, z_km, slice_data,
        col = QHYD_palette,
        zlim = c(QHYD_min, QHYD_max),
        main = paste("Total Hydrometeors (Time =", time_val, "s)"),
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
    QHYD_slice <- QHYD[, center_y_index, , as.character(time)]
    plot_QHYD_slice(time_val = time, slice_data = QHYD_slice)
  }
} else {
  last_time <- tail(alltimes, 1)
  cat(sprintf("processing last time = %s [s]\n", last_time))
  QHYD_slice <- QHYD[, center_y_index, , as.character(last_time)]
  plot_QHYD_slice(time_val = last_time, slice_data = QHYD_slice)
}

cat(paste("All plots saved in '", output_dir, "' directory.\n", sep=""))