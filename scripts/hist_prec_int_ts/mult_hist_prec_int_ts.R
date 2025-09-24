###################################################
# Title: visualize multiple frequency polygons of precipitation intensity Rscript 
# Author: Gaku YAMANO
# Date: 2025/08/26
###################################################
# load packages
library(ncdf4)
source("../../config.R")

#######################################################
#################### Setting items ####################
#######################################################
#  Set the maximum value for the x-axis [kg/m2/10min]
max_intensity <- 50 
#  Set the bin width for frequency counting [kg/m2/10min]
bin_width <- 1

############################################################
#################### Processing Part #######################
############################################################
# Create an empty list to store the results from each file
results_list <- list()
all_prec_values_max <- 0 # To determine the overall break points for the histogram

# First loop: Read data and find the overall maximum precipitation value
for (experiment_name in names(input_files)) {
  cat(paste("Processing (pass 1):", experiment_name, "\n"))
  input_file_path <- input_files[experiment_name]
  
  ncin <- nc_open(input_file_path)
  prec_data <- ncvar_get(ncin, "PREC")
  nc_close(ncin)
  
  prec_data_mm10min <- prec_data * 600
  prec_values <- prec_data_mm10min[prec_data_mm10min > 0.1 & is.finite(prec_data_mm10min)]
  
  # Store the raw values and update the overall maximum
  results_list[[experiment_name]]$raw_values <- prec_values
  all_prec_values_max <- max(all_prec_values_max, max(prec_values, na.rm = TRUE))
}

# Define common breaks for all histograms to ensure they are comparable
hist_breaks <- seq(0, all_prec_values_max + bin_width, by = bin_width)

# Second loop: Calculate histogram for each dataset using the common breaks
for (experiment_name in names(results_list)) {
  cat(paste("Processing (pass 2):", experiment_name, "\n"))
  
  hist_data <- hist(results_list[[experiment_name]]$raw_values,
                    breaks = hist_breaks,
                    plot = FALSE)
  
  # Store the calculated histogram data (midpoints and counts)
  results_list[[experiment_name]]$hist_df <- data.frame(
    mids = hist_data$mids,
    counts = hist_data$counts
  )
}

############################################################
#################### Plotting Part #########################
############################################################
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
pdf(file.path(output_dir, output_filename), width = pdf_width, height = pdf_height)

# Determine the overall range for the y-axis from all results
max_y <- max(sapply(results_list, function(res) max(res$hist_df$counts, na.rm = TRUE)))
y_range <- c(0, max_y)

# Create an empty plot with the determined axis ranges
plot(NA, NA,
     type = "n",
     xlim = c(0, max_intensity),
     ylim = y_range,
     main = "Frequency Polygon of Precipitation Intensity",
     xlab = "Precipitation Intensity [kg/m2/10min]",
     ylab = "Frequency",
     yaxt = "n"
)

# Loop through the results and add each frequency polygon as a line
for (i in 1:length(results_list)) {
  experiment_name <- names(results_list)[i]
  data_to_plot <- results_list[[experiment_name]]$hist_df
  lines(data_to_plot$mids, data_to_plot$counts,
        col = plot_colors[i],
        lwd = 1.5
  )
}

# Add legend, axis, and grid
legend("topright", 
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
