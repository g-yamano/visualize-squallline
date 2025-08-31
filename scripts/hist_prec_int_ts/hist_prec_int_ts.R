###################################################
# Title: visualize frequency polygon of precipitation intensity Rscript 
# Author: Gaku YAMANO
# Date: 2025/08/24
###################################################
# load packages
library(ncdf4)

#######################################################
#################### Setting items ####################
#######################################################
# 1.Specify the netcdf file path
input_file_path <- file.path("../../data/SDM/", "merged-h_history.pe000000.nc")
output_dir <- "../../output/Precipitation_intensity_histogram/SDM"
# 2. Specify the output pdf file name
output_filename <- "prec_intensity_freqpoly.pdf"
# 3. Specify the output pdf file size
pdf_width <- 8
pdf_height <- 6
# 4. Set the maximum value for the x-axis [kg/m2/10min]
max_intensity <- 50 
# 5. Set the bin width for frequency counting [kg/m2/10min]
bin_width <- 1

############################################################
#################### Processing Part #######################
############################################################
ncin <- nc_open(input_file_path)
# Read all precipitation data from all time steps
prec_data <- ncvar_get(ncin, "PREC")
nc_close(ncin)

# Data processing
# Convert units from kg/m2/s to  kg/m2/s
prec_data_mmhr <- prec_data * 600

# Extract only the finite values where precipitation is occurring ( > 0.1 kg/m2/10min)
prec_values <- prec_data_mmhr[prec_data_mmhr > 0.1 & is.finite(prec_data_mmhr)]

# --- ここからが頻度計算部分 ---
# Calculate histogram data without plotting
hist_data <- hist(prec_values,
                  breaks = seq(0, max(prec_values, na.rm=TRUE) + bin_width, by = bin_width),
                  plot = FALSE)

# Extract bin midpoints for x-axis and counts for y-axis
x_vals <- hist_data$mids
y_vals <- hist_data$counts

y_range <- range(y_vals, na.rm = TRUE)

############################################################
#################### Plotting Part #########################
############################################################
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

pdf(file.path(output_dir, output_filename), width = pdf_width, height = pdf_height)
line_color <- rgb(0, 114, 178, maxColorValue=255) # Blue color

plot(x_vals, y_vals, 
     type = "l", # "l" for line plot
     col = line_color,
     lwd = 1.5,
     xlim = c(0, max_intensity),
     ylim = y_range,
     main = "Frequency Polygon of Precipitation Intensity",
     xlab = "Precipitation Intensity [kg/m2/10min]",
     ylab = "Frequency",
     yaxt = "n"
)

y_ticks <- pretty(y_range, n = 10)
axis(side = 2, at = y_ticks, las = 1)

grid()

dev.off()

cat(paste("Plot saved in '", output_dir, "' directory.\n", sep=""))