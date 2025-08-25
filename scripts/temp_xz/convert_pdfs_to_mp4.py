# 必要なライブラリをインポート
import glob
import imageio
from pdf2image import convert_from_path
from natsort import natsorted
import time            
from tqdm import tqdm 
import os            

# --- 処理開始 ---
start_time = time.time() 

# --- 設定 ---
PDF_DIR = './figs/pdf'
FRAMERATE = 5
OUTPUT_FILE = './figs/mp4/output.mp4'

# --- 処理 ---
# ★ 出力先フォルダがなければ作成
output_dir = os.path.dirname(OUTPUT_FILE)
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

print("Searching for PDF files...")
pdf_files = natsorted(glob.glob(f'{PDF_DIR}/*.pdf'))

# PDFファイルが見つかった場合のみ処理を実行
if pdf_files:
    images = []
    print("Converting PDFs to images in memory...")
    
    # ★ tqdmでループを囲み、プログレスバーを表示
    for pdf_path in tqdm(pdf_files, desc="Converting PDFs"):
        images.append(convert_from_path(pdf_path, dpi=150)[0])

    print(f"Creating video: {OUTPUT_FILE}")
    imageio.mimsave(OUTPUT_FILE, images, fps=FRAMERATE)
    
    print("Done!")
else:
    print(f"No PDF files found in '{PDF_DIR}' directory.")

# --- 処理終了 ---
end_time = time.time() 
elapsed_time = end_time - start_time

# ★ 実行時間を表示（小数点以下2桁）
print(f"\nTotal execution time: {elapsed_time:.2f} seconds")
