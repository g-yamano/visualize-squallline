#!/bin/bash

find . -maxdepth 1 -mindepth 1 -type d -printf '%f\n' > directory_list.txt

echo "ディレクトリのリストを directory_list.txt に出力しました。"
