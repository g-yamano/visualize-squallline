###################################################
# Title: visualize IWP time series Rscript 
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
output_dir <- "../../output/IWP/pdf"
# 2. Specify the output pdf file name
output_filename <- "IWP_timeseries.pdf"
# 3. Specify the output pdf file size
pdf_width <- 10
pdf_height <- 6

############################################################
#################### Processing Part #######################
############################################################
ncin <- nc_open(input_file_path)
alltimes_sec <- ncvar_get(ncin, "time")
IWP <- ncvar_get(ncin, "IWP")
nc_close(ncin)

# Data processing
# Calculate spatial averages at each time step
# Use the apply() to calculate the mean for the first and second dimensions (space),
# while keeping the third dimension (time).
iwp_mean_timeseries <- apply(IWP, 3, mean, na.rm = TRUE) / 1000     # g/m^2 -> kg/m^2
alltimes_hr <- alltimes_sec/3600

iwp_min <- min(iwp_mean_timeseries, na.rm = TRUE)
iwp_max <- max(iwp_mean_timeseries, na.rm = TRUE)
y_range <- c(iwp_min, iwp_max)

############################################################
#################### Plotting Part #########################
############################################################
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

pdf(file.path(output_dir, output_filename), width = pdf_width, height = pdf_height)
iwp_color <- rgb(86, 180, 233, maxColorValue=255)
plot(alltimes_hr, iwp_mean_timeseries, 
     type = "l",
     col = iwp_color,
     lwd = 1,
     ylim = y_range,
     main = "Domain-Averaged Ice Water Path (IWP) Time Series",
     xlab = "Time [hour]",
     ylab = "Mean IWP [kg/m^2]",
     yaxt = "n"
)

legend("topright", 
       legend = "IWP",
       col = iwp_color,
       lty = 1, 
       lwd = 1,
       bg = "white" 
)

y_ticks <- pretty(y_range, n = 10)
axis(side = 2, at = y_ticks, las = 1)

grid()

dev.off()

cat(paste("Plot saved in '", output_dir, "' directory.\n", sep=""))