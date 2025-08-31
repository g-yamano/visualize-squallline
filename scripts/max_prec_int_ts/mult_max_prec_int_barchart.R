###################################################
# Title: visualize multiple dom_max_prec_rate barcharts Rscript 
# Author: Gaku YAMANO
# Date: 2025/08/29
###################################################
# load packages
library(ncdf4)
source("../../config.R")

#######################################################
#################### Setting items ####################
#######################################################
# Specify the time interval for binning (in hours)
bin_interval_hr <- 6

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
  prec_data <- ncvar_get(ncin, "PREC")
  nc_close(ncin)
  
  # Calculate the maximum precipitation rate in the domain at each time step
  dom_max_prec_rate_timeseries <- apply(prec_data, 3, max, na.rm = TRUE) * 120
  alltimes_hr <- alltimes_sec / 3600
  
  # Process data for barchart
  breaks <- seq(0, ceiling(max(alltimes_hr) / bin_interval_hr) * bin_interval_hr, by = bin_interval_hr)
  time_bins <- cut(alltimes_hr, breaks = breaks, right = FALSE, labels = FALSE)
  
  bar_heights <- tapply(dom_max_prec_rate_timeseries, time_bins, mean, na.rm = TRUE)
  error_bar_values <- tapply(dom_max_prec_rate_timeseries, time_bins, sd, na.rm = TRUE)
  error_bar_values[is.na(error_bar_values)] <- 0
  
  # Store the processed data in the list
  results_list[[experiment_name]] <- list(
    heights = bar_heights,
    errors = error_bar_values
  )
}

# --- Prepare data matrix for grouped barchart ---
height_matrix <- do.call(rbind, lapply(results_list, `[[`, "heights"))
error_matrix <- do.call(rbind, lapply(results_list, `[[`, "errors"))

# Create x-axis labels
num_bins <- ncol(height_matrix)
bar_labels <- paste(seq(0, num_bins - 1) * bin_interval_hr, "-", seq(1, num_bins) * bin_interval_hr, "h")

############################################################
#################### Plotting Part #########################
############################################################
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
pdf(file.path(output_dir, output_filename), width = pdf_width, height = pdf_height)

# Plot the grouped barchart
bar_centers <- barplot(height_matrix,
                       beside = TRUE, # This creates a grouped (not stacked) barchart
                       space = c(1.5, 2.5),
                       width = 0.3,
                       col = plot_colors,
                       ylim = c(0, max(height_matrix + error_matrix, na.rm=TRUE) * 1.1),
                       main = paste0(bin_interval_hr, "-Hourly Mean of Domain Maximum Precipitation Rate"),
                       xlab = "Time [hour]",
                       ylab = "Maximum Precipitation Rate [kg/m^2/2min]",
                       names.arg = bar_labels,
                       las = 1
)

# Add error bars to each bar
arrows(x0 = bar_centers, 
       y0 = height_matrix - error_matrix,
       x1 = bar_centers, 
       y1 = height_matrix + error_matrix,
       angle = 90,
       code = 3,
       length = 0.03
)

# Add legend
legend("topleft",
       legend = names(results_list),
       fill = plot_colors,
       bg = "white"
)

grid(nx = NA, ny = NULL)

dev.off()
cat(paste("Plot saved in '", output_dir, "' directory.\n", sep=""))
