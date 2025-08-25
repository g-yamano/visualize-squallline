###################################################
# Title: visualize dom_ave_accum_prec barchart Rscript 
# Author: Gaku YAMANO
# Date: 2025/08/23
###################################################
# load packages
library(ncdf4)

#######################################################
#################### Setting items ####################
#######################################################
# 1.Specify the netcdf file path
input_file_path <- file.path("../../data/", "merged-h_history.pe000000.nc")
output_dir <- "../../output/Domain_average_of_accumulated_precipitation_timeseries/SDM"
# 2. Specify the output pdf file name
output_filename <- "dom_ave_accum_prec_barchart_6hr.pdf"
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

# Calculate accumulated precipitation
time_interval_sec <- diff(alltimes_sec)
time_interval_sec <- c(0, time_interval_sec)
prec_amount <- dom_ave_prec_rate_timeseries * time_interval_sec
dom_ave_accum_prec_timeseries <- cumsum(prec_amount)

alltimes_hr <- alltimes_sec/3600

# --- ここからが棒グラフ用のデータ処理 ---
# 6時間ごとの区切りを作成
time_bins <- cut(alltimes_hr, breaks = seq(0, ceiling(max(alltimes_hr)/6)*6, by = 6), right = FALSE, labels = FALSE)

# 6時間ごとの平均値（棒の高さ）と標準偏差（エラーバーの長さ）を計算
bar_heights <- tapply(dom_ave_accum_prec_timeseries, time_bins, mean, na.rm = TRUE)
error_bar_values <- tapply(dom_ave_accum_prec_timeseries, time_bins, sd, na.rm = TRUE)
# データが1つしかない区間のNAを0に置換
error_bar_values[is.na(error_bar_values)] <- 0

# X軸のラベルを作成
bar_labels <- paste(seq(0, length(bar_heights)-1)*6, "-", seq(1, length(bar_heights))*6, "h")


############################################################
#################### Plotting Part #########################
############################################################
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

pdf(file.path(output_dir, output_filename), width = pdf_width, height = pdf_height)

# 棒グラフを描画し、棒の中心のX座標を取得
bar_centers <- barplot(bar_heights,
                       ylim = c(0, max(bar_heights + error_bar_values, na.rm=TRUE) * 1.1),
                       main = "6-Hourly Domain Average of Accumulated Precipitation [kg/m^2/6hr]",
                       xlab = "Time [hour]",
                       ylab = "Accumulated Precipitation [mm]",
                       names.arg = bar_labels,
                       las = 1 # X軸ラベルを縦書きに
)

# エラーバーを追加
arrows(x0 = bar_centers, 
       y0 = bar_heights - error_bar_values,
       x1 = bar_centers, 
       y1 = bar_heights + error_bar_values,
       angle = 90, # バーの先端を平らにする
       code = 3,   # 上下にバーを付ける
       length = 0.05 # バーの長さ
)

grid(nx=NA, ny=NULL) # 水平のグリッド線のみ表示

dev.off()

cat(paste("Plot saved in '", output_dir, "' directory.\n", sep=""))