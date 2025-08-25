###################################################
# Title: visualize dom_ave_accum_prec time series Rscript 
# Author: Gaku YAMANO
# Date: 2025/08/23
###################################################
# load packages
library(ncdf4)

#######################################################
#################### Setting items ####################
#######################################################
# 1.Specify the netcdf file path
input_file_path <- file.path("../../data/SDM", "merged-h_history.pe000000.nc")
output_dir <- "../../output/Domain_average_of_accumulated_precipitation/SDM"
# 2. Specify the output pdf file name
output_filename <- "dom_ave_accum_accum_prec_timeseries.pdf"
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
dom_ave_prec_rate_timeseries <- apply(dom_ave_prec, 3, mean, na.rm = TRUE)

# --- ここからが積算降水量の計算 ---
# 時間間隔 (秒) を計算 (最初のステップは0と仮定)
time_interval_sec <- diff(alltimes_sec)
time_interval_sec <- c(0, time_interval_sec)

# 各時間間隔での降水量 (kg/m2 = mm) を計算し、積算する
prec_amount <- dom_ave_prec_rate_timeseries * time_interval_sec
dom_ave_accum_prec_timeseries <- cumsum(prec_amount)

alltimes_hr <- alltimes_sec/3600

dom_ave_prec_min <- 0
dom_ave_prec_max <- max(dom_ave_accum_prec_timeseries, na.rm = TRUE)
y_range <- c(dom_ave_prec_min, dom_ave_prec_max)

############################################################
#################### Plotting Part #########################
############################################################
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

pdf(file.path(output_dir, output_filename), width = pdf_width, height = pdf_height)
dom_ave_prec_color <- rgb(86, 180, 233, maxColorValue=255)
plot(alltimes_hr, dom_ave_accum_prec_timeseries, 
     type = "l",
     col = dom_ave_prec_color,
     lwd = 1,
     ylim = y_range,
     main = "Domain Average of Accumulated Precipitation Time Series [kg/m^2/6hour]",
     xlab = "Time [hour]",
     ylab = "Accumulated Precipitation [mm]", # Y軸ラベルを修正
     yaxt = "n"
)

legend("topleft", 
       legend = "accum_prec",
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