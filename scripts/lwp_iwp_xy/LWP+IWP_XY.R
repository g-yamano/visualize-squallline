###################################################
# Title: visualize LWP+IWP (TWP) Rscript 
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
input_file_path <- file.path("../../data/SDM", "merged-h_history.pe000000.nc")
output_dir <- "../../output/LWP+IWP_XY/SDM"
# 2. Specify the output pdf file size
pdf_width <- 10
pdf_height <- 10
# 3. TRUE -> output all time fig, FALSE -> output only last time fig
output_alltime <- FALSE

# --- ここからが修正部分 ---
# 4. Specify the custom color palette and breaks
custom_colors <- c("#FFFFFF", "#E0E0FF", "#C0C0FF", "#8080FF", "#0000FF", 
                   "#0080FF", "#00C0FF", "#00E0E0", "#80FFA0", "#C0FF80", "#E0FF80")
#custom_breaks <- c(0, 0.5, 1, 2, 4, 6, 8, 10, 12, 14, 16, 18)


############################################################
#################### Processing Part #######################
############################################################
ncin <- nc_open(input_file_path)
alltimes <- ncvar_get(ncin, "time")
x <- ncvar_get(ncin, "x")
y <- ncvar_get(ncin, "y")
LWP <- ncvar_get(ncin, "LWP", collapse_degen = FALSE)
IWP <- ncvar_get(ncin, "IWP", collapse_degen = FALSE)
nc_close(ncin)

# LWPとIWPを合計してTWP (Total Water Path) を計算
TWP <- (LWP + IWP) * 10 ^ (-3)

# Data processing
dimnames(TWP)[[3]] <- alltimes

x_km <- x * 10^(-3)
y_km <- y * 10^(-3) 

# make plot function
plot_twp_slice <- function(time_val, twp_slice) {
  
  base_filename <- paste("TWP_XY.", sprintf("%05d", as.numeric(time_val)), ".pdf", sep = "")
  pdf_filename <- file.path(output_dir, base_filename)
  
  pdf(pdf_filename, width = pdf_width, height = pdf_height)
  
  # --- プロット部分を修正 ---
  fields::image.plot(x_km, y_km, twp_slice,
                     col = custom_colors,
                     #breaks = custom_breaks,
                     main = paste("Total Water Path (LWP+IWP) (Time =", time_val, "s)"),
                     xlab = "X [km]", ylab = "Y [km]", xaxt = "n", yaxt = "n", asp=1)
  x_ticks <- pretty(range(x_km), n = 10); axis(side = 1, at = x_ticks, labels = sprintf("%.1f", x_ticks))
  y_ticks <- pretty(range(y_km), n = 8); axis(side = 2, at = y_ticks, labels = sprintf("%.1f", y_ticks), las = 1)
  
  dev.off()
}

# plot processing
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

if (output_alltime) {
  for (time in alltimes) {
    cat(sprintf("processing time = %s [s]\n", time))
    TWP_slice <- TWP[, , as.character(time)]
    plot_twp_slice(time_val = time, twp_slice = TWP_slice)
  }
} else {
  last_time <- tail(alltimes, 1)
  cat(sprintf("processing last time = %s [s]\n", last_time))
  TWP_slice <- TWP[, , as.character(last_time)]
  plot_twp_slice(time_val = last_time, twp_slice = TWP_slice)
}

cat(paste("All plots saved in '", output_dir, "' directory.\n", sep=""))