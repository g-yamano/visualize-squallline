###################################################
# Title: visualize dom_ave_prec time series Rscript 
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
output_dir <- "../../output/Domain_average_of_accumulated_precipitation/SDM/pdf"
# 2. Specify the output pdf file name
output_filename <- "dom_ave_prec_timeseries.pdf"
# 3. Specify the output pdf file size
pdf_width <- 10
pdf_height <- 6

############################################################
#################### Processing Part #######################
############################################################
ncin <- nc_open(input_file_path)
alltimes_sec <- ncvar_get(ncin, "time")
dom_ave_prec <- ncvar_get(ncin, "PREC")
nc_close(ncin)

# Data processing
# Calculate spatial averages at each time step
# Use the apply() to calculate the mean for the first and second dimensions (space),
# while keeping the third dimension (time).
dom_ave_prec_mean_timeseries <- apply(dom_ave_prec, 3, mean, na.rm = TRUE) * 120     # g/m^2 -> kg/m^2
alltimes_hr <- alltimes_sec/3600

dom_ave_prec_min <- min(dom_ave_prec_mean_timeseries, na.rm = TRUE)
dom_ave_prec_max <- max(dom_ave_prec_mean_timeseries, na.rm = TRUE)
y_range <- c(dom_ave_prec_min, dom_ave_prec_max)

############################################################
#################### Plotting Part #########################
############################################################
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

pdf(file.path(output_dir, output_filename), width = pdf_width, height = pdf_height)
dom_ave_prec_color <- rgb(86, 180, 233, maxColorValue=255)
plot(alltimes_hr, dom_ave_prec_mean_timeseries, 
     type = "l",
     col = dom_ave_prec_color,
     lwd = 1,
     ylim = y_range,
     main = "Domain Averag of Precipitation Time Series [kg/m^2/2min]",
     xlab = "Time [hour]",
     ylab = " ",
     yaxt = "n"
)

legend("topright", 
       legend = "dom_ave_prec",
       col = dom_ave_prec_color,
       lty = 1, 
       lwd = 1,
       bg = "white" 
)

y_ticks <- pretty(y_range, n = 10)
axis(side = 2, at = y_ticks, las = 1)

grid()

dev.off()

cat(paste("Plot saved in '", output_dir, "' directory.\n", sep=""))