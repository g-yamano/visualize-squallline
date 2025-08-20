## 1. ライブラリの読み込み
library(RadioSonde)

## 2. ファイル名の指定
# !!! 注意: このRスクリプトとデータファイルを必ず同じフォルダに置いてください !!!
filename <- "../../data/input_sounding_may20_2011_unmod_v5_1200_100lvls"

#################################################################
## [前半] データ準備パート
#################################################################
## 3. 物理計算のための定数と関数の定義
gas_d <- 287.06; grav <- 9.81; press_0 <- 1000.0; cp <- 1.004e3; T0 <- 273.15
qv_press.to.vp <- function(qv, press) {
  (qv / 1000.0) * press / (0.622 + (qv / 1000.0))
}
vp.to.dewtempc <- function(vp) {
  tmp_A <- log(vp / 6.11)
  (tmp_A * 237.3) / (17.27 - tmp_A)
}

## 4. ファイルを読み込み、物理量を計算
tmp <- read.table(filename, header = FALSE, fill = TRUE, col.names = 1:5)
sonde_raw <- data.frame(
  press = tmp$X1, alt = tmp$X1, temp = tmp$X2,
  pot = tmp$X2, qv = tmp$X3, dewpt = tmp$X2,
  uwind = tmp$X4, vwind = tmp$X5
)
num_row <- length(sonde_raw$press)
sonde_raw$alt[1] <- 0
sonde_raw$temp[1] <- sonde_raw$pot[1] * (sonde_raw$press[1] / press_0)**(gas_d / cp)
for (i in 2:num_row) {
  sonde_raw$press[i] <- sonde_raw$press[i - 1] * exp(-grav / gas_d / sonde_raw$temp[i - 1] * (sonde_raw$alt[i] - sonde_raw$alt[i - 1]))
  sonde_raw$temp[i]  <- sonde_raw$pot[i] * (sonde_raw$press[i] / press_0)**(gas_d / cp)
}
sonde_raw$temp <- sonde_raw$temp - T0
sonde_raw$dewpt <- vp.to.dewtempc(qv_press.to.vp(sonde_raw$qv, sonde_raw$press))
sonde_raw$uwind[1] <- NA
sonde_raw$vwind[1] <- NA

#################################################################
## [後半] 描画パート
#################################################################

## 5. ★★★ 描画専用のクリーンなデータフレームを作成 ★★★
plot_data <- data.frame(
  press = sonde_raw$press,
  alt = sonde_raw$alt,
  temp = sonde_raw$temp,
  dewpt = sonde_raw$dewpt,
  uwind = sonde_raw$uwind,
  vwind = sonde_raw$vwind
)

## 6. skewtPlot関数で描画
skewtPlot(
  dataframe = plot_data, # クリーンなデータを渡す
  winds = TRUE,
  main = paste("Skew-T log-P Diagram for", basename(filename))
)