# 构建说明

本文档说明如何构建和打包记账应用的 macOS 版本。

## 快速开始

### 使用完整构建脚本

```bash
# 显示帮助信息
./build_macos.sh --help

# 仅构建应用
./build_macos.sh --build

# 构建并打包 DMG
./build_macos.sh --package

# 完整构建流程 (清理 -> 构建 -> 打包)
./build_macos.sh --all

# 仅清理构建目录
./build_macos.sh --clean
```

## 环境要求

- macOS 系统
- Flutter SDK
- CocoaPods (脚本会自动检查并尝试安装)

## 输出文件

构建完成后，DMG 文件将生成在 `dist/` 目录下：

- `dist/accounts_flow.dmg` - macOS 安装包

## 手动构建步骤

如果你希望手动执行构建流程：

```bash
# 1. 安装依赖
flutter pub get

# 2. 构建 macOS 应用
flutter build macos --release

# 3. 打包 DMG
mkdir -p dmg_temp
cp -r build/macos/Build/Products/Release/accounts_flow.app dmg_temp/
hdiutil create -volname "记账应用" -srcfolder dmg_temp -ov -format UDZO accounts_flow.dmg
rm -rf dmg_temp
```

## 注意事项

1. **系统要求**: 必须在 macOS 系统上运行构建脚本
2. **权限**: 确保脚本有执行权限 (`chmod +x build*.sh`)
3. **依赖**: 脚本会自动检查并安装必要的依赖
4. **输出目录**: 构建产物会保存在 `dist/` 目录中

## 故障排除

### CocoaPods 安装失败
如果 CocoaPods 安装失败，可以手动安装：

```bash
brew install cocoapods
```

### Flutter 命令未找到
确保 Flutter SDK 已正确安装并添加到 PATH 环境变量中。

### 构建失败
- 检查 Flutter 版本兼容性
- 确保所有依赖包都能正常获取
- 查看详细的错误信息进行调试