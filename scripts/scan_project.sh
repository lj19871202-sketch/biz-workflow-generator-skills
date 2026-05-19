#!/bin/bash
# 业务文档扫描脚本
# 用法: ./scan_project.sh <目标文件夹路径> [输出文件]

TARGET_DIR="${1:-.}"
OUTPUT_FILE="${2:-business-scan-result.txt}"

if [ ! -d "$TARGET_DIR" ]; then
    echo "错误: 目录不存在: $TARGET_DIR"
    exit 1
fi

echo "========================================" > "$OUTPUT_FILE"
echo "业务文档扫描报告" >> "$OUTPUT_FILE"
echo "目标目录: $(cd "$TARGET_DIR" && pwd)" >> "$OUTPUT_FILE"
echo "扫描时间: $(date)" >> "$OUTPUT_FILE"
echo "========================================" >> "$OUTPUT_FILE"

echo -e "\n--- 文档结构 ---" >> "$OUTPUT_FILE"
find "$TARGET_DIR" -type f \
  -not -path '*/.DS_Store' \
  -not -path '*/Thumbs.db' \
  -not -path '*/~$*' \
  -not -path '*/.git/*' \
  -not -path '*/node_modules/*' \
  -not -path '*/__pycache__/*' \
  -not -path '*.swp' \
  | sort >> "$OUTPUT_FILE"

echo -e "\n--- 文档统计 ---" >> "$OUTPUT_FILE"
echo "总文档数: $(find "$TARGET_DIR" -type f \
  -not -path '*/.DS_Store' \
  -not -path '*/Thumbs.db' \
  -not -path '*/~$*' \
  -not -path '*/.git/*' \
  -not -path '*/node_modules/*' \
  -not -path '*/__pycache__/*' \
  -not -path '*.swp' \
  | wc -l)" >> "$OUTPUT_FILE"
echo "Word 文档数: $(find "$TARGET_DIR" -type f -iname '*.doc*' -not -path '*/~$*' | wc -l)" >> "$OUTPUT_FILE"
echo "Excel 表格数: $(find "$TARGET_DIR" -type f -iname '*.xls*' | wc -l)" >> "$OUTPUT_FILE"
echo "PPT 演示数: $(find "$TARGET_DIR" -type f -iname '*.ppt*' | wc -l)" >> "$OUTPUT_FILE"
echo "PDF 文档数: $(find "$TARGET_DIR" -type f -iname '*.pdf' | wc -l)" >> "$OUTPUT_FILE"
echo "Markdown 文档数: $(find "$TARGET_DIR" -type f -iname '*.md' | wc -l)" >> "$OUTPUT_FILE"
echo "文本文件数: $(find "$TARGET_DIR" -type f -iname '*.txt' | wc -l)" >> "$OUTPUT_FILE"

echo -e "\n--- 目录结构 ---" >> "$OUTPUT_FILE"
if command -v tree &>/dev/null; then
    tree -L 3 "$TARGET_DIR" >> "$OUTPUT_FILE"
else
    find "$TARGET_DIR" -maxdepth 3 -type d | sort | awk -F/ '{for(i=1;i<NF;i++) printf "  "; print "- " $NF}' >> "$OUTPUT_FILE"
fi

echo "扫描完成，结果已保存到: $OUTPUT_FILE"
