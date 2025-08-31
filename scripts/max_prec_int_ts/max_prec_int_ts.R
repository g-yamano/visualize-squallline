###################################################
# Title: visualize dom_max_prec_rate time series Rscript 
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
output_dir <- "../../output/Maximum_precipitation_intensity_in_the_domain_timeseries/SDM"
# 2. Specify the output pdf file name
output_filename <- "dom_max_prec_intensity_timeseries.pdf"
# 3. Specify the output pdf file size
pdf_width <- 10
pdf_height <- 6

############################################################
#################### Processing Part #######################
############################################################
ncin <- nc_open(input_file_path)
alltimes_sec <- ncvar_get(ncin, "time")
prec_data <- ncvar_get(ncin, "PREC")
nc_close(ncin)

# Data processing
dom_max_prec_rate_timeseries <- apply(prec_data, 3, max, na.rm = TRUE) * 120

alltimes_hr <- alltimes_sec/3600

y_range <- c(0, max(dom_max_prec_rate_timeseries, na.rm = TRUE))

############################################################
#################### Plotting Part #########################
############################################################
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

pdf(file.path(output_dir, output_filename), width = pdf_width, height = pdf_height)
line_color <- rgb(213, 94, 0, maxColorValue=255) # Changed color for distinction
plot(alltimes_hr, dom_max_prec_rate_timeseries, 
     type = "l",
     col = line_color,
     lwd = 1,
     ylim = y_range,
     main = "Domain Maximum Precipitation Intensity Time Series",
     xlab = "Time [hour]",
     ylab = "Maximum Precipitation [kg/m^2/2min]",
     yaxt = "n"
)

legend("topright", 
       legend = "max_prec_intensity",
       col = line_color,
       lty = 1, 
       lwd = 1,
       bg = "white" 
)

y_ticks <- pretty(y_range, n = 10)
axis(side = 2, at = y_ticks, las = 1)

grid()

dev.off()

cat(paste("Plot saved in '", output_dir, "' directory.\n", sep=""))