###################################################
# Title: visualize LWP time series Rscript 
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
output_dir <- "../../output/LWP/pdf"
# 2. Specify the output pdf file name
output_filename <- "LWP_timeseries.pdf"
# 3. Specify the output pdf file size
pdf_width <- 10
pdf_height <- 6

############################################################
#################### Processing Part #######################
############################################################
ncin <- nc_open(input_file_path)
alltimes_sec <- ncvar_get(ncin, "time")
LWP <- ncvar_get(ncin, "LWP")
nc_close(ncin)

# Data processing
# Calculate spatial averages at each time step
# Use the apply() to calculate the mean for the first and second dimensions (space),
# while keeping the third dimension (time).
lwp_mean_timeseries <- apply(LWP, 3, mean, na.rm = TRUE) / 1000     # g/m^2 -> kg/m^2
alltimes_hr <- alltimes_sec/3600

lwp_min <- min(lwp_mean_timeseries, na.rm = TRUE)
lwp_max <- max(lwp_mean_timeseries, na.rm = TRUE)
y_range <- c(lwp_min, lwp_max)

############################################################
#################### Plotting Part #########################
############################################################
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

pdf(file.path(output_dir, output_filename), width = pdf_width, height = pdf_height)

lwp_color <- rgb(0, 114, 178, maxColorValue=255)

plot(alltimes_hr, lwp_mean_timeseries, 
     type = "l",
     col = lwp_color,
     lwd = 1,
     ylim = y_range,
     main = "Domain-Averaged Liquid Water Path (LWP) Time Series",
     xlab = "Time [hour]",
     ylab = "Mean LWP [kg/m^2]",
     yaxt = "n"
)

legend("topleft", 
       legend = "LWP",
       col = lwp_color,
       lty = 1, 
       lwd = 1,
       bg = "white" 
)

y_ticks <- pretty(y_range, n = 10)
axis(side = 2, at = y_ticks, las = 1)

grid()

dev.off()

cat(paste("Plot saved in '", output_dir, "' directory.\n", sep=""))