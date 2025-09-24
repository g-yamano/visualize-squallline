###################################################
# Title: visualize multiple low_level_dom_ave_RH time series Rscript 
# Author: Gaku YAMANO
# Date: 2025/08/26
###################################################
# load packages
library(ncdf4)
source("../../config.R")

#######################################################
#################### Setting items ####################
#######################################################

#  Specify the 3D relative humidity variable name
rh_var_name <- "RH" 
#  Specify the x range for averaging [km]
x_range_km <- c(325, 350)

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
  x <- ncvar_get(ncin, "x")
  rh_data_4D <- ncvar_get(ncin, rh_var_name)
  nc_close(ncin)
  
  x_km <- x * 10^(-3)
  x_indices <- which(x_km >= x_range_km[1] & x_km <= x_range_km[2])
  
  # Extract only the lowest vertical level (z=1) and the specified x range
  rh_data_subset <- rh_data_4D[x_indices, , 1, ]
  
  # Calculate spatial averages at each time step
  rh_mean_timeseries <- apply(rh_data_subset, 3, mean, na.rm = TRUE)
  
  alltimes_hr <- alltimes_sec / 3600
  
  # Store the processed data in the list
  results_list[[experiment_name]] <- data.frame(
    time_hr = alltimes_hr,
    rh_mean = rh_mean_timeseries
  )
}

############################################################
#################### Plotting Part #########################
############################################################
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
pdf(file.path(output_dir, output_filename), width = pdf_width, height = pdf_height)

# Determine the overall range for x and y axes from all results
max_x <- max(sapply(results_list, function(df) max(df$time_hr, na.rm = TRUE)))
min_y <- min(sapply(results_list, function(df) min(df$rh_mean, na.rm = TRUE)))
x_range <- c(0, max_x)
y_range <- c(min_y, 100) # Set max y-axis to 100% for RH

# Create an empty plot with the determined axis ranges
plot(NA, NA,
     type = "n",
     xlim = x_range,
     ylim = y_range,
     main = paste("Domain Average Relative Humidity (X = ", x_range_km[1], "-", x_range_km[2], " km, z=1)"),
     xlab = "Time [hour]",
     ylab = "Relative Humidity [%]",
     xaxt = "n",
     yaxt = "n"
)

# Loop through the results and add each time series as a line to the plot
for (i in 1:length(results_list)) {
  experiment_name <- names(results_list)[i]
  data_to_plot <- results_list[[experiment_name]]
  lines(data_to_plot$time_hr, data_to_plot$rh_mean,
        col = plot_colors[i],
        lwd = 2
  )
}

# Add legend, axis, and grid
legend("bottomright", 
       legend = names(results_list),
       col = plot_colors,
       lty = 1, 
       lwd = 2,
       bg = "white"
)

x_ticks <- pretty(x_range, n = 10)
axis(side = 1, at = x_ticks, labels = sprintf("%.1f", x_ticks), las = 1)
y_ticks <- pretty(y_range, n = 10)
axis(side = 2, at = y_ticks, labels = sprintf("%.1f", y_ticks), las = 1)

minor_x_ticks <- (x_ticks[-length(x_ticks)] + x_ticks[-1]) / 2
axis(side = 1, at = minor_x_ticks, labels = FALSE, tcl = -0.25)
minor_y_ticks <- (y_ticks[-length(y_ticks)] + y_ticks[-1]) / 2
axis(side = 2, at = minor_y_ticks, labels = FALSE, tcl = -0.25)

grid()
dev.off()
cat(paste("Plot saved in '", output_dir, "' directory.\n", sep=""))
