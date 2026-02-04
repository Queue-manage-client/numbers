#!/bin/bash
# .envファイルを読み込んでEnv.xcconfigを生成するスクリプト
# このスクリプトはXcodeのBuild Phasesで実行されます

ENV_FILE="${SRCROOT}/../.env"
OUTPUT_FILE="${SRCROOT}/Flutter/Env.xcconfig"

echo "Loading environment variables from .env file..."

if [ -f "$ENV_FILE" ]; then
    echo "// Auto-generated from .env - DO NOT EDIT" > "$OUTPUT_FILE"
    echo "// Generated at $(date)" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    while IFS='=' read -r key value || [ -n "$key" ]; do
        # 空行とコメント行をスキップ
        if [ -n "$key" ] && [[ ! "$key" =~ ^[[:space:]]*# ]] && [[ ! "$key" =~ ^[[:space:]]*$ ]]; then
            # 先頭と末尾の空白を削除
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)

            if [ -n "$key" ] && [ -n "$value" ]; then
                echo "$key=$value" >> "$OUTPUT_FILE"
            fi
        fi
    done < "$ENV_FILE"

    echo "Environment variables loaded successfully to $OUTPUT_FILE"
else
    echo "Warning: .env file not found at $ENV_FILE"
    echo "// .env file not found - using empty config" > "$OUTPUT_FILE"
fi
