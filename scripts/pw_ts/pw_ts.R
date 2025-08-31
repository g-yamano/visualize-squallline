###################################################
# Title: visualize PW time series Rscript 
# Author: Gaku YAMANO
# Date: 2025/08/22
###################################################
# load packages
library(ncdf4)

#######################################################
#################### Setting items ####################
#######################################################
# 1.Specify the netcdf file path
input_file_path <- file.path("../../data/", "merged-h_history.pe000000.nc")
output_dir <- "../../output/PW/pdf"
# 2. Specify the output pdf file name
output_filename <- "PW_timeseries.pdf"
# 3. Specify the output pdf file size
pdf_width <- 10
pdf_height <- 6

############################################################
#################### Processing Part #######################
############################################################
ncin <- nc_open(input_file_path)
alltimes_sec <- ncvar_get(ncin, "time")
PW <- ncvar_get(ncin, "PW")
nc_close(ncin)

# Data processing
# Calculate spatial averages at each time step
# Use the apply() to calculate the mean for the first and second dimensions (space),
# while keeping the third dimension (time).
pw_mean_timeseries <- apply(PW, 3, mean, na.rm = TRUE) / 1000     # g/m^2 -> kg/m^2
alltimes_hr <- alltimes_sec/3600

pw_min <- min(pw_mean_timeseries, na.rm = TRUE)
pw_max <- max(pw_mean_timeseries, na.rm = TRUE)
y_range <- c(pw_min, pw_max)

############################################################
#################### Plotting Part #########################
############################################################
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

pdf(file.path(output_dir, output_filename), width = pdf_width, height = pdf_height)

wp_color <- rgb(213, 94, 0, maxColorValue=255)

plot(alltimes_hr, pw_mean_timeseries, 
     type = "l",
     col = wp_color,
     lwd = 1,
     ylim = y_range,
     main = "Domain-Averaged Precipitable water (PW) Time Series",
     xlab = "Time [hour]",
     ylab = "Mean PW [kg/m^2]",
     yaxt = "n"
)

legend("topright", 
       legend = "PW",
       col = wp_color,
       lty = 1, 
       lwd = 1,
       bg = "white" 
)

y_ticks <- pretty(y_range, n = 10)
axis(side = 2, at = y_ticks, las = 1)

grid()

dev.off()

cat(paste("Plot saved in '", output_dir, "' directory.\n", sep=""))