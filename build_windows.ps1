# Windows 构建脚本 (PowerShell)
# 用于构建和打包 Flutter Windows 应用

param(
    [switch]$Clean,
    [switch]$Build,
    [switch]$Package,
    [switch]$All,
    [switch]$Help
)

# 项目信息
$AppName = "记账应用"
$Version = "1.0.0"
$BuildDir = "build\windows"
$OutputDir = "dist"
$ExeName = "accounts_flow.exe"
$ZipName = "accounts_flow_windows.zip"

# 日志函数
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Info {
    param([string]$Message)
    Write-Log "[INFO] $Message" -Color "Blue"
}

function Write-Success {
    param([string]$Message)
    Write-Log "[SUCCESS] $Message" -Color "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-Log "[WARNING] $Message" -Color "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-Log "[ERROR] $Message" -Color "Red"
}

# 显示帮助信息
function Show-Help {
    Write-Info "Windows 构建脚本 (PowerShell)"
    Write-Host ""
    Write-Host "用法: .\build_windows.ps1 [选项]"
    Write-Host ""
    Write-Host "选项:"
    Write-Host "  -Clean        清理构建目录"
    Write-Host "  -Build        构建 Windows 应用"
    Write-Host "  -Package      构建并打包 ZIP"
    Write-Host "  -All          执行完整构建流程 (清理 -> 构建 -> 打包)"
    Write-Host "  -Help         显示此帮助信息"
    Write-Host ""
    Write-Host "示例:"
    Write-Host "  .\build_windows.ps1 -Build         仅构建应用"
    Write-Host "  .\build_windows.ps1 -Package       构建并打包 ZIP"
    Write-Host "  .\build_windows.ps1 -All           完整构建流程"
}

# 检查依赖
function Check-Dependencies {
    Write-Info "检查依赖..."

    # 检查 Flutter
    try {
        $flutterVersion = flutter --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter 未安装或不在 PATH 中"
        }
    } catch {
        Write-Error "Flutter 未安装或不在 PATH 中"
        exit 1
    }

    # 检查 Visual Studio 构建工具
    try {
        $msbuild = Get-Command "msbuild" -ErrorAction SilentlyContinue
        if (-not $msbuild) {
            Write-Warning "未找到 Visual Studio 构建工具，请确保已安装 Visual Studio 或 Build Tools"
        }
    } catch {
        Write-Warning "未找到 Visual Studio 构建工具，请确保已安装 Visual Studio 或 Build Tools"
    }

    Write-Success "依赖检查完成"
}

# 清理构建目录
function Clean-Build {
    Write-Info "清理构建目录..."

    if (Test-Path $BuildDir) {
        Remove-Item -Recurse -Force $BuildDir
        Write-Success "已清理构建目录"
    } else {
        Write-Info "构建目录不存在，无需清理"
    }

    if (Test-Path $OutputDir) {
        Remove-Item -Recurse -Force $OutputDir
        Write-Success "已清理输出目录"
    }

    # 清理 Flutter 构建缓存
    flutter clean
    if ($LASTEXITCODE -eq 0) {
        Write-Success "已清理 Flutter 缓存"
    } else {
        Write-Error "清理 Flutter 缓存失败"
        exit 1
    }
}

# 安装依赖
function Install-Dependencies {
    Write-Info "安装 Flutter 依赖..."
    flutter pub get
    if ($LASTEXITCODE -eq 0) {
        Write-Success "依赖安装完成"
    } else {
        Write-Error "依赖安装失败"
        exit 1
    }
}

# 构建 Windows 应用
function Build-Windows {
    Write-Info "构建 Windows 应用..."

    # 检查是否在 Windows 上运行
    if (-not $IsWindows) {
        Write-Error "此脚本只能在 Windows 上运行"
        exit 1
    }

    flutter build windows --release
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Windows 应用构建完成"
    } else {
        Write-Error "Windows 应用构建失败"
        exit 1
    }
}

# 打包 ZIP
function Package-Zip {
    Write-Info "打包 ZIP 安装包..."

    # 创建输出目录
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    }

    # 检查构建输出是否存在
    $exePath = Join-Path $BuildDir "runner\Release\$ExeName"
    if (-not (Test-Path $exePath)) {
        Write-Error "构建输出不存在，请先运行构建"
        exit 1
    }

    # 创建临时目录
    $tempDir = "zip_temp"
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir
    }
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

    # 复制应用文件
    $sourceDir = Join-Path $BuildDir "runner\Release"
    Copy-Item -Path "$sourceDir\*" -Destination $tempDir -Recurse -Force

    # 创建 ZIP 文件
    $zipPath = Join-Path $OutputDir $ZipName
    Compress-Archive -Path "$tempDir\*" -DestinationPath $zipPath -Force

    if (Test-Path $zipPath) {
        $zipSize = (Get-Item $zipPath).Length / 1MB
        Write-Success "ZIP 打包完成: $zipPath"
        Write-Info "ZIP 文件大小: $([math]::Round($zipSize, 2)) MB"
    } else {
        Write-Error "ZIP 打包失败"
        exit 1
    }

    # 清理临时目录
    Remove-Item -Recurse -Force $tempDir
}

# 显示构建信息
function Show-BuildInfo {
    Write-Info "=== 构建信息 ==="
    Write-Info "应用名称: $AppName"
    Write-Info "版本: $Version"
    Write-Info "构建目录: $BuildDir"
    Write-Info "输出目录: $OutputDir"
    Write-Info "EXE 文件: $BuildDir\runner\Release\$ExeName"
    Write-Info "ZIP 文件: $OutputDir\$ZipName"
    Write-Info "================"
}

# 主函数
function Main {
    # 显示帮助
    if ($Help) {
        Show-Help
        return
    }

    # 如果没有指定任何选项，显示帮助
    if (-not $Clean -and -not $Build -and -not $Package -and -not $All) {
        Show-Help
        return
    }

    # 执行完整构建流程
    if ($All) {
        Write-Info "开始完整构建流程..."
        Check-Dependencies
        Clean-Build
        Install-Dependencies
        Build-Windows
        Package-Zip
        Show-BuildInfo
        Write-Success "完整构建流程完成!"
        return
    }

    # 执行单个步骤
    if ($Clean) {
        Clean-Build
    }

    if ($Build) {
        Check-Dependencies
        Install-Dependencies
        Build-Windows
    }

    if ($Package) {
        Check-Dependencies
        Install-Dependencies
        Build-Windows
        Package-Zip
        Show-BuildInfo
    }

    Write-Success "构建任务完成!"
}

# 运行主函数
Main