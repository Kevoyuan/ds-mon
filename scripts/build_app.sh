#!/bin/bash

# 设置错误即停止
set -e

APP_NAME="DeepSeek Monitor"
BINARY_NAME="ds-mon"
BUNDLE_ID="com.yuan.ds-mon"
BUILD_DIR=".build/release"
APP_DIR="dist/${APP_NAME}.app"

echo "🚀 开始构建 ${APP_NAME}..."

# 1. 编译
swift build -c release --arch arm64 --arch x86_64

# 2. 创建目录结构
echo "📂 创建 .app 目录结构..."
rm -rf dist
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# 3. 拷贝二进制文件
echo "Copying binary..."
cp "${BUILD_DIR}/${BINARY_NAME}" "${APP_DIR}/Contents/MacOS/"

# 4. 拷贝 Info.plist
echo "📄 拷贝 Info.plist..."
cp "Sources/ds-mon/Resources/Info.plist" "${APP_DIR}/Contents/Info.plist"

# 5. 处理资源文件
# Swift Package Manager 会将资源放在 .resources 目录下
# 我们需要把它们拷贝到 App Bundle 的 Resources 目录
RESOURCE_BUNDLE=$(find "${BUILD_DIR}" -name "*.bundle" -type d | head -n 1)
if [ -n "$RESOURCE_BUNDLE" ]; then
    echo "📦 拷贝资源 Bundle: $(basename "$RESOURCE_BUNDLE")"
    cp -R "$RESOURCE_BUNDLE/" "${APP_DIR}/Contents/Resources/"
fi

# 6. (可选) 签名 - 这里的签名只是 ad-hoc 签名，为了能在本地运行
# 如果没有开发者证书，外发的包可能需要用户手动允许
echo "✍️ 进行 Ad-hoc 签名..."
codesign --force --deep --sign - "${APP_DIR}"

# 7. 打包成 ZIP
echo "📦 打包成 ZIP..."
cd dist
zip -r "${BINARY_NAME}.zip" "${APP_NAME}.app"
cd ..

echo "✅ 构建完成！你可以在 dist 目录下找到 ${APP_NAME}.app"
echo "💡 如果要在其他电脑上运行，请在下载后运行：xattr -d com.apple.quarantine ${APP_NAME}.app"
