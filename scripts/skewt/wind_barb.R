###################################################
# Title: Visualize Wind Barbs using plotWind
# Author: Gaku YAMANO
# Date: 2025/08/25
# Reference: RadioSonde.pdf
###################################################
## 1. パッケージの読み込み
library(RadioSonde)

## 2. ファイルの指定
# このファイルパスはご自身の環境に合わせて設定してください
filepath <- "../../data/Sounding_Data/input_sounding_may20_2011_unmod_v5_1200_100lvls"

####################################################
## データの準備
####################################################
# (このセクションは、元のスクリプトから物理量を計算する部分を流用しています)
gas_d <- 287.06; grav <- 9.81; press_0 <- 1000.0; cp <- 1.004e3; T0 <- 273.15
tmp <- read.table(filepath, header=FALSE, fill=TRUE, col.names=1:5)
sonde_raw <- data.frame(
  alt=tmp$X1, pot=tmp$X2, qv=tmp$X3, uwind=tmp$X4, vwind=tmp$X5
)
num_row <- length(sonde_raw$alt)
sonde_raw$press <- numeric(num_row); sonde_raw$temp <- numeric(num_row)
sonde_raw$alt[1]<-0; sonde_raw$press[1]<-press_0
sonde_raw$temp[1]<-sonde_raw$pot[1]*(sonde_raw$press[1]/press_0)**(gas_d/cp)
for(i in 2:num_row){
  temp_prev_K<-sonde_raw$temp[i-1]
  sonde_raw$press[i]<-sonde_raw$press[i-1]*exp(-grav/gas_d/temp_prev_K*(sonde_raw$alt[i]-sonde_raw$alt[i-1]))
  sonde_raw$temp[i]<-sonde_raw$pot[i]*(sonde_raw$press[i]/press_0)**(gas_d/cp)
}
sonde_raw$uwind[1]<-NA; sonde_raw$vwind[1]<-NA

####################################################
## wspdとdirの計算
####################################################
# PDFの指示通り、plotWind関数にはwspdとdirの列が必要です [cite: 101, 112]。
# uwindとvwindから風速(wspd)を計算します。
sonde_raw$wspd <- sqrt(sonde_raw$uwind^2 + sonde_raw$vwind^2)

# uwindとvwindから風向(dir)を計算します。
# (気象学的な「風が吹いてくる方向」に変換)
sonde_raw$dir <- (atan2(sonde_raw$uwind, sonde_raw$vwind) * 180 / pi) + 180

## 描画用データフレームの作成
# PDFで要求されている press, wspd, dir の列を持つデータフレームを作成 。
plot_data <- data.frame(
  press = sonde_raw$press,
  wspd = sonde_raw$wspd,
  dir = sonde_raw$dir
)

####################################################
## プロット
####################################################
# PDF p.3 の Usage に従って plotWind 関数を呼び出します 。
plotWind(
  sondeData = plot_data,
  sizeBarb = 3.0,
  col = "black",
  ylim = c(1050, 100),
  legend = TRUE # 凡例を表示 [cite: 108]
)

# グラフにタイトルを追加します。
title(main = paste("Wind Profile for", basename(filepath)))