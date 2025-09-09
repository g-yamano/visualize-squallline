#!/bin/bash

# findコマンドの実行結果を `directory_list.txt` に上書き保存する
find . -maxdepth 1 -mindepth 1 -type d -print > directory_list.txt

# 完了メッセージを表示する
echo "ディレクトリのリストを directory_list.txt に出力しました。"
