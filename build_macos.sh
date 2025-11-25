#!/bin/bash

# macOS 构建脚本
# 用于构建和打包 Flutter macOS 应用

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
APP_NAME="记账应用"
VERSION="1.0.0"
BUILD_DIR="build/macos"
OUTPUT_DIR="dist"
DMG_NAME="accounts_flow.dmg"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo "macOS 构建脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -c, --clean        清理构建目录"
    echo "  -b, --build        构建 macOS 应用"
    echo "  -p, --package      构建并打包 DMG"
    echo "  -a, --all          执行完整构建流程 (清理 -> 构建 -> 打包)"
    echo "  -h, --help         显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 --build         仅构建应用"
    echo "  $0 --package       构建并打包 DMG"
    echo "  $0 --all           完整构建流程"
}

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."

    # 检查 Flutter
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter 未安装或不在 PATH 中"
        exit 1
    fi

    # 检查 CocoaPods
    if ! command -v pod &> /dev/null; then
        log_warning "CocoaPods 未安装，尝试安装..."
        if command -v brew &> /dev/null; then
            brew install cocoapods
        else
            log_error "请先安装 CocoaPods: https://guides.cocoapods.org/using/getting-started.html"
            exit 1
        fi
    fi

    log_success "依赖检查完成"
}

# 清理构建目录
clean_build() {
    log_info "清理构建目录..."

    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        log_success "已清理构建目录"
    else
        log_info "构建目录不存在，无需清理"
    fi

    if [ -d "$OUTPUT_DIR" ]; then
        rm -rf "$OUTPUT_DIR"
        log_success "已清理输出目录"
    fi

    # 清理 Flutter 构建缓存
    flutter clean
    log_success "已清理 Flutter 缓存"
}

# 安装依赖
install_dependencies() {
    log_info "安装 Flutter 依赖..."
    flutter pub get
    log_success "依赖安装完成"
}

# 构建 macOS 应用
build_macos() {
    log_info "构建 macOS 应用..."

    # 检查是否在 macOS 上运行
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "此脚本只能在 macOS 上运行"
        exit 1
    fi

    flutter build macos --release

    if [ $? -eq 0 ]; then
        log_success "macOS 应用构建完成"
    else
        log_error "macOS 应用构建失败"
        exit 1
    fi
}

# 打包 DMG
package_dmg() {
    log_info "打包 DMG 安装包..."

    # 创建输出目录
    mkdir -p "$OUTPUT_DIR"

    # 创建临时目录
    TEMP_DIR="dmg_temp"
    mkdir -p "$TEMP_DIR"

    # 复制应用文件
    cp -r "$BUILD_DIR/Build/Products/Release/accounts_flow.app" "$TEMP_DIR/"

    # 创建 DMG
    hdiutil create -volname "$APP_NAME" -srcfolder "$TEMP_DIR" -ov -format UDZO "$OUTPUT_DIR/$DMG_NAME"

    if [ $? -eq 0 ]; then
        log_success "DMG 打包完成: $OUTPUT_DIR/$DMG_NAME"

        # 显示文件信息
        DMG_SIZE=$(du -h "$OUTPUT_DIR/$DMG_NAME" | cut -f1)
        log_info "DMG 文件大小: $DMG_SIZE"
    else
        log_error "DMG 打包失败"
        exit 1
    fi

    # 清理临时目录
    rm -rf "$TEMP_DIR"
}

# 显示构建信息
show_build_info() {
    log_info "=== 构建信息 ==="
    log_info "应用名称: $APP_NAME"
    log_info "版本: $VERSION"
    log_info "构建目录: $BUILD_DIR"
    log_info "输出目录: $OUTPUT_DIR"
    log_info "DMG 文件: $OUTPUT_DIR/$DMG_NAME"
    log_info "================"
}

# 主函数
main() {
    local clean=false
    local build=false
    local package=false
    local all=false

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--clean)
                clean=true
                shift
                ;;
            -b|--build)
                build=true
                shift
                ;;
            -p|--package)
                package=true
                shift
                ;;
            -a|--all)
                all=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 如果没有指定任何选项，显示帮助
    if [ "$clean" = false ] && [ "$build" = false ] && [ "$package" = false ] && [ "$all" = false ]; then
        show_help
        exit 0
    fi

    # 执行完整构建流程
    if [ "$all" = true ]; then
        log_info "开始完整构建流程..."
        check_dependencies
        clean_build
        install_dependencies
        build_macos
        package_dmg
        show_build_info
        log_success "完整构建流程完成!"
        exit 0
    fi

    # 执行单个步骤
    if [ "$clean" = true ]; then
        clean_build
    fi

    if [ "$build" = true ]; then
        check_dependencies
        install_dependencies
        build_macos
    fi

    if [ "$package" = true ]; then
        check_dependencies
        install_dependencies
        build_macos
        package_dmg
        show_build_info
    fi

    log_success "构建任务完成!"
}

# 运行主函数
main "$@"