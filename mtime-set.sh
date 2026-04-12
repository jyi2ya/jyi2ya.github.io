#!/bin/bash

if [ $# -ne 2 ]; then
    echo "用法: $0 'YYYY-MM-DD HH:MM' 文件名"
    exit 1
fi

datetime="$1"
filename="$2"

if [ ! -f "$filename" ]; then
    echo "错误: 文件 '$filename' 不存在"
    exit 1
fi

# 将输入时间转换为touch命令可接受的格式
# 2022-01-25 22:56 -> 012522562022
touch_time=$(date -d "$datetime" +"%Y%m%d%H%M")

# 修改文件的三个时间戳
touch -t "$touch_time" "$filename"

echo "已成功修改文件时间: $filename -> $datetime"

