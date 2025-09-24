#!/bin/bash

# ==============================================================================
# 概要:
# 指定されたディレクトリ内のPDFファイルを自然順にソートし、
# 各PDFの最初のページを画像に変換後、それらを結合してMP4動画を生成します。
# (ImageMagick 6系 / convertコマンド対応版)
#
# 依存関係:
# このスクリプトを実行するには、以下のコマンドラインツールが必要です。
# - poppler-utils (pdftoppmコマンドを提供)
# - imagemagick (v6系)
#
# インストール例 (Debian/Ubuntu):
# sudo apt-get update && sudo apt-get install poppler-utils imagemagick
#
# インストール例 (macOS with Homebrew):
# brew install poppler imagemagick
# ==============================================================================

# --- 設定 ---
# PDFファイルが保存されているディレクトリ
PDF_DIR='../../output/snc_xz/sdm_pb'
# 動画のフレームレート
FRAMERATE=5
# 出力するMP4ファイルの名前
OUTPUT_FILE='../../output/snc_xz/sdm_pb/snc_xz.mp4'

# --- 処理開始 ---
start_time=$(date +%s)
echo "--- Process Started ---"

# --- 処理 ---
# ★ 出力先フォルダがなければ作成
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR"

# 一時的に画像を保存するフォルダを作成
# スクリプト終了時にこのフォルダは自動的に削除されます
IMG_DIR=$(mktemp -d)
trap 'echo "Cleaning up temporary files..."; rm -rf "$IMG_DIR"' EXIT

echo "Searching for PDF files..."
# PDFファイルを自然順ソートで検索
pdf_files=$(find "$PDF_DIR" -maxdepth 1 -type f -name "*.pdf" | sort -V)

# PDFファイルが見つかった場合のみ処理を実行
if [ -n "$pdf_files" ]; then
    echo "Converting PDFs to images..."

    count=1
    # while readループでファイル名を1つずつ安全に処理
    echo "$pdf_files" | while IFS= read -r pdf_path; do
        # pdftoppmでPDFの最初の1ページを150dpiのPNG画像に変換
        pdftoppm -f 1 -l 1 -png -r 150 "$pdf_path" "$IMG_DIR/temp_image" > /dev/null 2>&1
        mv "$IMG_DIR/temp_image-1.png" "$IMG_DIR/frame_$(printf "%05d" $count).png"

        # 進行状況を表示
        echo "  - Converted: $(basename "$pdf_path")"
        count=$((count + 1))
    done

    echo "Creating video with ImageMagick (convert): $OUTPUT_FILE"
    # ImageMagickを使用して連番画像から動画を作成します
    # -delayオプションは1/100秒単位でフレーム間の遅延を設定します
    # 例: フレームレートが5の場合、1フレームあたり0.2秒なので、delayは 100 / 5 = 20 となります
    delay=$((100 / FRAMERATE))

    # ImageMagick 6系のため `convert` コマンドを使用
    # -quality 95 はビデオの品質を指定します (値が大きいほど高品質)
    convert -delay "$delay" "$IMG_DIR/frame_*.png" -quality 95 "$OUTPUT_FILE" > /dev/null 2>&1

    echo "Done!"
else
    echo "No PDF files found in '$PDF_DIR' directory."
fi

# --- 処理終了 ---
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

# ★ 実行時間を表示
echo -e "\n--- Process Finished ---"
echo "Total execution time: ${elapsed_time} seconds"
