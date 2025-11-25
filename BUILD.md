# 构建说明

本文档说明如何构建和打包记账应用的多平台版本。

## 平台支持

- **macOS**: 使用 `build_macos.sh` 脚本构建 DMG 安装包
- **Windows**: 使用 `build_windows.ps1` 脚本构建 ZIP 发布包

## 快速开始

### macOS 构建

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

### Windows 构建

```powershell
# 显示帮助信息
.\build_windows.ps1 -Help

# 仅构建应用
.\build_windows.ps1 -Build

# 构建并打包 ZIP
.\build_windows.ps1 -Package

# 完整构建流程 (清理 -> 构建 -> 打包)
.\build_windows.ps1 -All

# 仅清理构建目录
.\build_windows.ps1 -Clean
```

## 环境要求

### macOS
- macOS 系统
- Flutter SDK
- CocoaPods (脚本会自动检查并尝试安装)

### Windows
- Windows 10 或更高版本
- Flutter SDK 3.10.1 或更高版本
- Visual Studio 2019 或更高版本（包含 C++ 构建工具）
- PowerShell 5.1 或更高版本

## 输出文件

### macOS
构建完成后，DMG 文件将生成在 `dist/` 目录下：

- `dist/accounts_flow.dmg` - macOS 安装包

### Windows
构建完成后，ZIP 文件将生成在 `dist/` 目录下：

- `dist/accounts_flow_windows.zip` - Windows 发布包
- `build/windows/runner/Release/accounts_flow.exe` - 可执行文件

## 手动构建步骤

### macOS
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

### Windows
如果你希望手动执行构建流程：

```cmd
:: 1. 清理
flutter clean

:: 2. 安装依赖
flutter pub get

:: 3. 构建 Windows 应用
flutter build windows --release

:: 4. 手动打包（可选）
cd build\windows\runner\Release
powershell -Command "Compress-Archive -Path '*' -DestinationPath '..\..\..\..\dist\accounts_flow_windows.zip' -Force"
```

## 注意事项

### macOS
1. **系统要求**: 必须在 macOS 系统上运行构建脚本
2. **权限**: 确保脚本有执行权限 (`chmod +x build*.sh`)
3. **依赖**: 脚本会自动检查并安装必要的依赖
4. **输出目录**: 构建产物会保存在 `dist/` 目录中

### Windows
1. **系统要求**: 必须在 Windows 系统上运行构建脚本
2. **执行策略**: PowerShell 脚本可能需要设置执行策略
3. **依赖**: 需要 Visual Studio 构建工具
4. **网络连接**: 首次构建需要网络连接以下载依赖
5. **磁盘空间**: 确保有足够的磁盘空间（约 1-2GB）
6. **防病毒软件**: 某些防病毒软件可能会误报，请添加排除项

## 故障排除

### macOS

#### CocoaPods 安装失败
如果 CocoaPods 安装失败，可以手动安装：

```bash
brew install cocoapods
```

#### Flutter 命令未找到
确保 Flutter SDK 已正确安装并添加到 PATH 环境变量中。

#### 构建失败
- 检查 Flutter 版本兼容性
- 确保所有依赖包都能正常获取
- 查看详细的错误信息进行调试

### Windows

#### Flutter 命令未找到
- 确保 Flutter SDK 已正确安装并添加到 PATH
- 运行 `flutter doctor` 检查环境

#### 构建失败
- 检查 Visual Studio 构建工具是否安装
- 运行 `flutter doctor` 检查缺少的依赖
- 确保 Visual Studio 包含 C++ 构建工具

#### PowerShell 执行策略限制
- 运行 `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- 或使用管理员权限运行 PowerShell