###################################################
# Title: Visualize environment Rscript 
# Author: Gaku YAMANO
# Date: 2025/08/18
###################################################
## 1. load packages
library(RadioSonde)

## 2. specify the file
filepath <- "../../data/Sounding_Data/input_sounding_may20_2011_unmod_v5_1200_100lvls"
output_dir <- "../../output/Skewtlogp_diagram"

####################################################
## prepare data
####################################################
## 3. Defining constants and functions for physics calculations
gas_d <- 287.06   # specific gas constant for dry air [J/kg/K] 
grav <- 9.81      # gravitational acceleration [m/s^2]
press_0 <- 1000.0 # reference pressure [hPa]
cp <- 1.004e3     # specific heat capacity of dry air at constant pressure [J/kg/K]
T0 <- 273.15      # 0 deg C in K [K]

qv_press.to.vp <- function(qv, press) {
  (qv / 1000.0) * press / (0.622 + (qv / 1000.0))
}
vp.to.dewtempc <- function(vp) {
  tmp_A <- log(vp / 6.11)
  (tmp_A * 237.3) / (17.27 - tmp_A)
}

## 4. Read the file and calculate the physical quantities
tmp <- read.table(filepath, header = FALSE, fill = TRUE, col.names = 1:5)

# 読み込んだデータでデータフレームを初期化
sonde_raw <- data.frame(
  alt = tmp$X1,
  pot = tmp$X2,
  qv = tmp$X3,
  uwind = tmp$X4,
  vwind = tmp$X5
)
num_row <- length(sonde_raw$alt)

# 計算結果を格納するための列を準備
sonde_raw$press <- numeric(num_row)
sonde_raw$temp <- numeric(num_row)

# 【修正点】計算の初期値を設定
sonde_raw$alt[1] <- 0
sonde_raw$press[1] <- press_0 # 最初の気圧を基準気圧(1000hPa)と仮定
sonde_raw$temp[1] <- sonde_raw$pot[1] * (sonde_raw$press[1] / press_0)**(gas_d / cp)

# forループで2番目以降の値を計算
for (i in 2:num_row) {
  # 気温は絶対温度(K)で計算する必要があるため、一時的に前のステップの気温をKで保持
  temp_prev_K <- sonde_raw$temp[i - 1] 
  sonde_raw$press[i] <- sonde_raw$press[i - 1] * exp(-grav / gas_d / temp_prev_K * (sonde_raw$alt[i] - sonde_raw$alt[i - 1]))
  sonde_raw$temp[i]  <- sonde_raw$pot[i] * (sonde_raw$press[i] / press_0)**(gas_d / cp)
}

# ループ完了後、気温を摂氏(℃)に変換
sonde_raw$temp <- sonde_raw$temp - T0
# 露点温度を計算
sonde_raw$dewpt <- vp.to.dewtempc(qv_press.to.vp(sonde_raw$qv, sonde_raw$press))

sonde_raw$uwind[1] <- NA
sonde_raw$vwind[1] <- NA

####################################################
## plot data
####################################################

## 5. make dataframe
plot_data <- data.frame(
  press = sonde_raw$press,
  alt = sonde_raw$alt,
  temp = sonde_raw$temp,
  dewpt = sonde_raw$dewpt,
  uwind = sonde_raw$uwind,
  vwind = sonde_raw$vwind
)

## 6. plot
skewtPlot(
  dataframe = plot_data, 
  winds = TRUE,
  main = paste("Skew-T log-P Diagram for", basename(filepath))
)

