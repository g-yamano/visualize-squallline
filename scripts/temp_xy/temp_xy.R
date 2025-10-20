###################################################
# Title: visualize Temperature XY-slice Rscript 
# Author: Gaku YAMANO
# Date: 2025/09/02
###################################################

# load packages
library(ncdf4)
library(fields)
source("../../config.R")

#######################################################
#################### Setting items ####################
#######################################################
# Specify the color palette
temp_palette <- colorRampPalette(c("purple", "blue", "darkgreen", 
                                   "green", "white", "yellow", 
                                   "orange", "red"))(500)
# --- 追加: 可視化したい高度を指定 [km] ---
#target_z_km <- 1.0 

############################################################
#################### Processing Part #######################
############################################################
ncin <- nc_open(input_file)
alltimes <- ncvar_get(ncin, "time")
x <- ncvar_get(ncin, "x")
y <- ncvar_get(ncin, "y")
z <- ncvar_get(ncin, "z")
Tem_K <- ncvar_get(ncin, "T", collapse_degen = FALSE)
nc_close(ncin)

# Data processing
Tem_C <- Tem_K - 273.15
temp_min <- floor(min(Tem_C, na.rm=TRUE))
temp_max <- ceiling(max(Tem_C, na.rm=TRUE))
dimnames(Tem_C)[[4]] <- alltimes

x_km <- x * 10^(-3)
y_km <- y * 10^(-3) # Y座標をkmに変換
z_km <- z * 10^(-3) 

# --- 追加: 指定した高度に最も近いZのインデックスを見つける ---
#center_z_index <- which.min(abs(z_km - target_z_km))
center_z_index <- 1

# make plot function
plot_temperature_slice <- function(time_val, slice_data) {
  
  base_filename <- paste("Temperature_XY.", sprintf("%05d", as.numeric(time_val)), ".pdf", sep = "")
  pdf_filename <- file.path(output_dir, base_filename)
  
  pdf(pdf_filename, width = pdf_width, height = pdf_height)
  
  # --- 変更点: X-Y平面を描画 ---
  fields::image.plot(x_km, y_km, slice_data,
        col = temp_palette,
        zlim = c(16, 20.5),
        main = paste("Temperature at Z =", z_km[center_z_index], "km (Time =", time_val, "s)"),
        xlab = "X [km]",
        ylab = "Y [km]", # Y軸ラベルを変更
        xaxt = "n",
        yaxt = "n",
        asp = 1 # アスペクト比を1:1に
  )
  
  # plot axis
  x_ticks <- pretty(range(x_km), n = 10) 
  axis(side = 1, at = x_ticks, labels = sprintf("%.1f", x_ticks))
  
  y_ticks <- pretty(range(y_km), n = 8) 
  axis(side = 2, at = y_ticks, labels = sprintf("%.1f", y_ticks), las = 1)
  
  dev.off()
}

# plot processing
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

if (output_alltime) {
  for (time in alltimes) {
    cat(sprintf("processing time = %s [s]\n", time))
    # --- 変更点: Z次元を固定してX-Y断面を切り出す ---
    temp_slice <- Tem_C[, , center_z_index, as.character(time)]
    plot_temperature_slice(time_val = time, slice_data = temp_slice)
  }
} else {
  last_time <- tail(alltimes, 1)
  cat(sprintf("processing last time = %s [s]\n", last_time))
  # --- 変更点: Z次元を固定してX-Y断面を切り出す ---
  temp_slice <- Tem_C[, , center_z_index, as.character(last_time)]
  plot_temperature_slice(time_val = last_time, slice_data = temp_slice)
}

cat(paste("All plots saved in '", output_dir, "' directory.\n", sep=""))
