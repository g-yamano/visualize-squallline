###################################################
# Title: visualize Temperature Rscript 
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
output_dir <- "./figs/pdf"
# 2. Specify the color palette
temp_palette <- colorRampPalette(c("purple", "blue", "darkgreen", 
                                   "green", "white", "yellow", 
                                   "orange", "red"))(500)
# 3. Specify the output pdf file size
pdf_width <- 10
pdf_height <- 5
# 4 TRUE -> output all time fig, FALSE -> output only last time fig
output_alltime <- TRUE

############################################################
#################### Processing Part #######################
############################################################
ncin <- nc_open(input_file_path)
alltimes <- ncvar_get(ncin, "time")
x <- ncvar_get(ncin, "x")
y <- ncvar_get(ncin, "y")
z <- ncvar_get(ncin, "z")
center_y_index <- as.integer(length(y) / 2)
Tem_K <- ncvar_get(ncin, "T", collapse_degen = FALSE)
nc_close(ncin)

# Data processing
Tem_C <- Tem_K - 273.15
temp_min <- floor(min(Tem_C))
temp_max <- ceiling(max(Tem_C))
dimnames(Tem_C)[[4]] <- alltimes

x_km <- x * 10^(-5)
z_km <- z * 10^(-3) 

# make plot function
plot_temperature_slice <- function(time_val, slice_data) {
  
  base_filename <- paste("Temperature_XZ.", sprintf("%05d", as.numeric(time_val)), ".pdf", sep = "")
  pdf_filename <- file.path(output_dir, base_filename)
  
  pdf(pdf_filename, width = pdf_width, height = pdf_height)
  
  # plot contour
  fields::image.plot(x_km, z_km, slice_data,
        col = temp_palette,
        zlim = c(temp_min, temp_max),
        main = paste("Temperature [degree ] (Time =", time_val, "s)"),
        xlab = "X [km]",
        ylab = "Z [km]", 
        xaxt = "n",
        yaxt = "n"
  )
  
  # plot axis
  x_ticks <- pretty(range(x_km), n = 10) 
  axis(side = 1, at = x_ticks, labels = sprintf("%.1f", x_ticks))
  
  y_ticks <- pretty(range(z_km), n = 8) # 修正: prettyの正しい使い方
  axis(side = 2, at = y_ticks, labels = sprintf("%.1f", y_ticks), las = 1)
  
  # close PDF device
  dev.off()
}

# plot processing
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

if (output_alltime) {
  for (time in alltimes) {
    cat(sprintf("processing time = %s [s]\n", time))
    temp_slice <- Tem_C[, center_y_index, , as.character(time)]
    plot_temperature_slice(time_val = time, slice_data = temp_slice)
  }
} else {
  last_time <- tail(alltimes, 1)
  cat(sprintf("processing last time = %s [s]\n", last_time))
  temp_slice <- Tem_C[, center_y_index, , as.character(last_time)]
  plot_temperature_slice(time_val = last_time, slice_data = temp_slice)
}

cat(paste("All plots saved in '", output_dir, "' directory.\n", sep=""))