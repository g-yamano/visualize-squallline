###################################################
# Title: visualize multiple IWP time series Rscript 
# Author: Gaku YAMANO
# Date: 2025/08/26
###################################################
# load packages
library(ncdf4)
source("../../config.R")

############################################################
#################### Processing Part #######################
############################################################
# Create an empty list to store the results from each file
results_list <- list()

# Loop through each input file to process the data
for (experiment_name in names(input_files)) {
  
  cat(paste("Processing:", experiment_name, "\n"))
  input_file_path <- input_files[experiment_name]
  
  ncin <- nc_open(input_file_path)
  alltimes_sec <- ncvar_get(ncin, "time")
  IWP <- ncvar_get(ncin, "IWP")
  nc_close(ncin)
  
  # Calculate spatial averages at each time step and convert units
  iwp_mean_timeseries <- apply(IWP, 3, mean, na.rm = TRUE) / 1000 # g/m^2 -> kg/m^2
  alltimes_hr <- alltimes_sec / 3600
  
  # Store the processed data in the list
  results_list[[experiment_name]] <- data.frame(
    time_hr = alltimes_hr,
    iwp_mean = iwp_mean_timeseries
  )
}

############################################################
#################### Plotting Part #########################
############################################################
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
pdf(file.path(output_dir, output_filename), width = pdf_width, height = pdf_height)

# Determine the overall range for x and y axes from all results
max_x <- max(sapply(results_list, function(df) max(df$time_hr, na.rm = TRUE)))
max_y <- max(sapply(results_list, function(df) max(df$iwp_mean, na.rm = TRUE)))
x_range <- c(0, max_x)
y_range <- c(0, max_y) # Start y-axis from 0 for better comparison

# Create an empty plot with the determined axis ranges
plot(NA, NA,
     type = "n",
     xlim = x_range,
     ylim = y_range,
     main = "Domain-Averaged Ice Water Path (IWP) Time Series",
     xlab = "Time [hour]",
     ylab = "Mean IWP [kg/m^2]",
     yaxt = "n"
)

# Loop through the results and add each time series as a line to the plot
for (i in 1:length(results_list)) {
  experiment_name <- names(results_list)[i]
  data_to_plot <- results_list[[experiment_name]]
  lines(data_to_plot$time_hr, data_to_plot$iwp_mean,
        col = plot_colors[i],
        lwd = 2
  )
}

# Add legend, axis, and grid
legend("topleft", 
       legend = names(results_list),
       col = plot_colors,
       lty = 1, 
       lwd = 2,
       bg = "white"
)

y_ticks <- pretty(y_range, n = 10)
axis(side = 2, at = y_ticks, las = 1)
grid()

dev.off()
cat(paste("Plot saved in '", output_dir, "' directory.\n", sep=""))
