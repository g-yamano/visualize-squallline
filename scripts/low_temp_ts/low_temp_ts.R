###################################################
# Title: visualize low_level_dom_ave_temp time series Rscript 
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
output_dir <- "../../output/Low_level_Temp_timeseries/SDM"
# 2. Specify the output pdf file name
output_filename <- "low_level_temp_timeseries.pdf"
# 3. Specify the output pdf file size
pdf_width <- 10
pdf_height <- 6
# 4. Specify the 3D temperature variable name
temp_var_name <- "T" 
# 5. Specify the x range for averaging [km]
x_range_km <- c(325, 350)

############################################################
#################### Processing Part #######################
############################################################
ncin <- nc_open(input_file_path)
alltimes_sec <- ncvar_get(ncin, "time")
x <- ncvar_get(ncin, "x")
temp_data_4D <- ncvar_get(ncin, temp_var_name)
nc_close(ncin)

x_km <- x * 10^(-3)
x_indices <- which(x_km >= x_range_km[1] & x_km <= x_range_km[2])

temp_data_subset <- temp_data_4D[x_indices, , 1, ]

temp_mean_timeseries <- apply(temp_data_subset, 3, mean, na.rm = TRUE) - 273.15

alltimes_hr <- alltimes_sec/3600

y_range <- range(temp_mean_timeseries, na.rm = TRUE)
#y_range <- c(15.0, 22.0)

############################################################
#################### Plotting Part #########################
############################################################
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

pdf(file.path(output_dir, output_filename), width = pdf_width, height = pdf_height)
line_color <- rgb(230, 159, 0, maxColorValue=255)
plot(alltimes_hr, temp_mean_timeseries, 
     type = "l",
     col = line_color,
     lwd = 1,
     ylim = y_range,
     main = paste("Domain Average Temperature (X = ", x_range_km[1], "-", x_range_km[2], " km, z=1)"),
     xlab = "Time [hour]",
     ylab = "Temperature [C]",
     yaxt = "n"
)

legend("topright", 
       legend = "ave_temp",
       col = line_color,
       lty = 1, 
       lwd = 1,
       bg = "white" 
)

y_ticks <- pretty(y_range, n = 10)
axis(side = 2, at = y_ticks, labels = sprintf("%.1f", y_ticks), las = 1)

grid()

dev.off()

cat(paste("Plot saved in '", output_dir, "' directory.\n", sep=""))