#!/bin/zsh

DIRECTORIES="initial_condition
             QHYD_XY
             QHYD_XZ
             Temperature
             LWP+IWP
             Precipitation
             Precipitable_water
             Ice_water_path
             Liquid_water_path
             QHYD_U&W
             Domain_average_of_accumulated_precipitation
             Domain_average_of_precipitation
             Maximum_precipitation_intensity_in_the_domain
             Histogram_of_precipitation_intensity
             Superdroplet_number_concentration
            "

for dir in $DIRECTORIES; do
  mkdir "$dir"
  echo "ディレクトリ '$dir' を作成しました。"
done

echo "すべてのディレクトリの作成が完了しました。"