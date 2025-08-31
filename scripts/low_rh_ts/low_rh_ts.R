###################################################
# Title: visualize low_level_dom_ave_RH time series Rscript 
# Author: Gaku YAMANO
# Date: 2025/08/23
###################################################
# load packages
library(ncdf4)

#######################################################
#################### Setting items ####################
#######################################################
# 1.Specify the netcdf file path
input_file_path <- file.path("../../data/SDM/", "merged-h_history.pe000000.nc")
output_dir <- "../../output/Low_level_RH_timeseries/SDM"
# 2. Specify the output pdf file name
output_filename <- "low_level_rh_timeseries.pdf"
# 3. Specify the output pdf file size
pdf_width <- 10
pdf_height <- 6
# 4. Specify the 3D relative humidity variable name
rh_var_name <- "RH" 
# 5. Specify the x range for averaging [km]
x_range_km <- c(325, 350)

############################################################
#################### Processing Part #######################
############################################################
ncin <- nc_open(input_file_path)
alltimes_sec <- ncvar_get(ncin, "time")
x <- ncvar_get(ncin, "x")
rh_data_4D <- ncvar_get(ncin, rh_var_name)
nc_close(ncin)

x_km <- x * 10^(-3)
x_indices <- which(x_km >= x_range_km[1] & x_km <= x_range_km[2])

# Extract only the lowest vertical level (z=1) and the specified x range
rh_data_subset <- rh_data_4D[x_indices, , 1, ]

# Calculate spatial averages at each time step
rh_mean_timeseries <- apply(rh_data_subset, 3, mean, na.rm = TRUE)

alltimes_hr <- alltimes_sec/3600

x_range <- range(alltimes_hr, na.rm = TRUE)
#y_range <- range(rh_mean_timeseries, na.rm = TRUE)
#y_range <- c(80, 100)
y_range <- c(min(rh_mean_timeseries), 100)

############################################################
#################### Plotting Part #########################
############################################################
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

pdf(file.path(output_dir, output_filename), width = pdf_width, height = pdf_height)
line_color <- rgb(0, 158, 115, maxColorValue=255) # Green color
plot(alltimes_hr, rh_mean_timeseries, 
     type = "l",
     col = line_color,
     lwd = 1,
     ylim = y_range,
     main = paste("Domain Average Relative Humidity (X = ", x_range_km[1], "-", x_range_km[2], " km, z=1)"),
     xlab = "Time [hour]",
     ylab = "Relative Humidity [%]",
     xaxt = "n",
     yaxt = "n"
)

legend("bottomright", 
       legend = "ave_rh",
       col = line_color,
       lty = 1, 
       lwd = 1,
       bg = "white" 
)

#main scale
x_ticks <- pretty(x_range, n = 10)
axis(side = 1, at = x_ticks, labels = sprintf("%.1f", x_ticks), las = 1) # 小数点なしに修正
y_ticks <- pretty(y_range, n = 10)
axis(side = 2, at = y_ticks, labels = sprintf("%.1f", y_ticks), las = 1) # 小数点なしに修正

#minor scale
minor_x_ticks <- (x_ticks[-length(x_ticks)] + x_ticks[-1]) / 2
axis(side = 1, at = minor_x_ticks, labels = FALSE, tcl = -0.25)
minor_y_ticks <- (y_ticks[-length(y_ticks)] + y_ticks[-1]) / 2
axis(side = 2, at = minor_y_ticks, labels = FALSE, tcl = -0.25)

grid()

dev.off()

cat(paste("Plot saved in '", output_dir, "' directory.\n", sep=""))