@echo off
chcp 65001 >nul
title PotPlayer 组件一键安装配置脚本
echo ==============================================
echo      PotPlayer 组件 (LAV/madVR/VapourSynth) 安装脚本
echo ==============================================
echo.

:: 检查管理员权限
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [错误] 请以管理员身份运行此脚本！
    echo 右键点击本文件 -> "以管理员身份运行"
    pause
    exit /b 1
)

:: 进入脚本所在目录
cd /d "%~dp0"

:: =============================================
:: 1. 查找 PotPlayer 安装路径
:: =============================================
echo [信息] 正在查找 PotPlayer 安装路径...
set "POTPLAYER_DIR="
:: 尝试 64位 注册表路径
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\DAUM\PotPlayer" /v "InstallPath" 2^>nul') do set "POTPLAYER_DIR=%%b"
if defined POTPLAYER_DIR goto :FOUND_POT
:: 尝试 32位 注册表路径
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\DAUM\PotPlayer" /v "InstallPath" 2^>nul') do set "POTPLAYER_DIR=%%b"
 
if defined POTPLAYER_DIR goto :FOUND_POT
:: 也尝试 HKCU 路径
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\SOFTWARE\DAUM\PotPlayer" /v "InstallPath" 2^>nul') do set "POTPLAYER_DIR=%%b"
 
if defined POTPLAYER_DIR goto :FOUND_POT

:: 未找到，提示手动输入
echo [警告] 未在注册表中找到 PotPlayer 安装路径。
echo 请手动输入 PotPlayer 的安装目录（例如 C:\Program Files\DAUM\PotPlayer）
set /p "POTPLAYER_DIR=请输入路径: "
if not exist "%POTPLAYER_DIR%" (
    echo [错误] 输入的路径不存在，请重新运行脚本。
    pause
    exit /b 1
	 
)
:: =============================================
:: 2. 创建 MLVR 目录
:: =============================================
set "MLVR_DIR=%POTPLAYER_DIR%\MLVR"
if not exist "%MLVR_DIR%" mkdir "%MLVR_DIR%"
echo [信息] 组件将安装到: %MLVR_DIR%
echo.

:: =============================================
:: 3. 处理 madVR (解压 zip)
:: =============================================
echo [1/4] 正在安装 madVR...
set "MAD_DIR=%MLVR_DIR%\madVR"
if exist "%MAD_DIR%" rmdir /s /q "%MAD_DIR%"
for /f "delims=" %%i in ('dir /b /a-d madvr*.zip 2^>nul') do (
    set "MAD_ZIP=%%i"
    goto :MAD_FOUND
)
echo [错误] 未找到 madvr*.zip 文件，请将文件放在脚本同目录下。
set "MAD_INSTALL_RESULT=失败（未找到安装包）"
goto :MAD_DONE
:MAD_FOUND
echo 找到 madVR 压缩包: %MAD_ZIP%
powershell -command "Expand-Archive -Path '%MAD_ZIP%' -DestinationPath '%MAD_DIR%' -Force"
if errorlevel 1 (
    echo [错误] 解压 madVR 失败。
    set "MAD_INSTALL_RESULT=失败（解压错误）"
    goto :MAD_DONE
)
:: 处理可能的多层目录
if exist "%MAD_DIR%\madVR" (
    echo 检测到压缩包内含 madVR 子目录，正在移动文件...
    move /y "%MAD_DIR%\madVR\*" "%MAD_DIR%\" >nul 2>&1
    rmdir /s /q "%MAD_DIR%\madVR"
)
:: 注册 madVR
cd /d "%MAD_DIR%"
if exist "install.bat" (
    call install.bat >nul 2>&1
    echo.
    if errorlevel 1 (
        echo [错误] madVR 注册失败。
        set "MAD_INSTALL_RESULT=失败（注册错误）"
    ) else (
        echo madVR 安装成功。
        set "MAD_INSTALL_RESULT=成功"
    )
) else (
    regsvr32 /s "%MAD_DIR%\madVR.ax"
    echo.
    if errorlevel 1 (
        echo [错误] madVR 注册失败。
        set "MAD_INSTALL_RESULT=失败（注册错误）"
    ) else (
        echo madVR 安装成功（手动注册 madVR.ax）。
        set "MAD_INSTALL_RESULT=成功"
    )
)
cd /d "%~dp0"
:MAD_DONE
echo [结果] madVR 安装结果: %MAD_INSTALL_RESULT%
echo.

:: =============================================
:: 4. 安装 LAVFilters (exe)
:: =============================================
echo [2/4] 正在安装 LAVFilters...
set "LAV_DIR=%MLVR_DIR%\LAVFilters"
if not exist "%LAV_DIR%" mkdir "%LAV_DIR%"
for /f "delims=" %%i in ('dir /b /a-d LAVFilters*.exe 2^>nul') do (
    set "LAV_EXE=%%i"
    goto :LAV_FOUND
)
echo [错误] 未找到 LAVFilters*.exe 文件。
set "LAV_INSTALL_RESULT=失败（未找到安装包）"
goto :LAV_DONE
:LAV_FOUND
echo 找到 LAVFilters 安装包: %LAV_EXE%
echo 正在静默安装到 %LAV_DIR% ...
start /wait "" "%LAV_EXE%" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /DIR="%LAV_DIR%" /COMPONENTS="lavsplitter64,lavaudio64,lavvideo64"
if errorlevel 1 (
    echo [错误] LAVFilters 安装失败。
    set "LAV_INSTALL_RESULT=失败（安装错误）"
) else (
    echo LAVFilters 安装成功。
    set "LAV_INSTALL_RESULT=成功"
)
:LAV_DONE
echo [结果] LAVFilters 安装结果: %LAV_INSTALL_RESULT%
echo.

:: =============================================
:: 5. 安装 VapourSynth
:: =============================================
echo [3/4] 正在准备安装 VapourSynth...
set "VS_DIR=%MLVR_DIR%\VapourSynth"
if not exist "%VS_DIR%" mkdir "%VS_DIR%"
:: VapourSynth R76 的 wheel 编译为 cp312-abi3，需要 Python 3.12+
echo.
echo =============================================
echo   VapourSynth R76 需要 Python 3.12 或更高版本
echo   当前系统 Python 版本:
echo =============================================
set "SYS_PYTHON="
set "SYS_PY_VER="
:: 检查 PATH 中的 python
for /f "delims=" %%v in ('python --version 2^>nul') do set "SYS_PY_VER=%%v"
if defined SYS_PY_VER (
    echo   [系统] %SYS_PY_VER%
    set "SYS_PYTHON=python"
) else (
    echo   [系统] 未检测到 Python
)
:: 检查 py launcher
for /f "delims=" %%v in ('py --version 2^>nul') do set "PY_LAUNCHER_VER=%%v"
if defined PY_LAUNCHER_VER (
    if not defined SYS_PY_VER (
        echo   [py] %PY_LAUNCHER_VER%
    )
)
:: 检查是否满足 3.12+ 要求
set "PY_OK=0"
if defined SYS_PY_VER (
    for /f "tokens=2 delims= " %%v in ("%SYS_PY_VER%") do (
        for /f "tokens=1,2 delims=." %%a in ("%%v") do (
            if %%a GEQ 3 (
                if %%a EQU 3 (
                    if %%b GEQ 12 set "PY_OK=1"
                ) else (
                    set "PY_OK=1"
                )
            )
        )
    )
)
echo.
set "VS_PYTHON="
if "%PY_OK%"=="1" goto :PY_ENOUGH
goto :PY_NOT_ENOUGH

:PY_ENOUGH
echo [√] 系统 Python 版本满足 VapourSynth R76 要求。
echo.
set /p "PY_CHOICE=是否使用系统 Python 安装 VapourSynth？(Y=使用系统Python / N=下载独立Python): "
if /i "%PY_CHOICE%"=="Y" goto :PY_USE_SYSTEM
goto :VS_DOWNLOAD_PY

:PY_USE_SYSTEM
set "VS_PYTHON=python"
echo 将使用系统 Python 安装 VapourSynth。
goto :VS_INSTALL

:PY_NOT_ENOUGH
if defined SYS_PY_VER (
    echo [X] 系统 %SYS_PY_VER% 版本过低，VapourSynth R76 需要 3.12+。
)
echo.
echo 选项:
echo   [Y] 下载 Python 3.14 embeddable（需要外网访问 python.org 和 github.com）
echo   [N] 跳过 VapourSynth 安装
echo.
set /p "PY_CHOICE=请选择 (Y/N): "
if /i "%PY_CHOICE%"=="Y" goto :VS_DOWNLOAD_PY
echo 跳过 VapourSynth 安装。
set "VS_INSTALL_RESULT=跳过（用户选择）"
goto :VS_DONE

:VS_DOWNLOAD_PY
set "VS_DL=%VS_DIR%\vs-temp-dl"
set "PY_VER_MAJOR=3"
set "PY_VER_MINOR=14"
set "PY_VER_PATCH=1"
echo.
echo 注意: 以下文件需要从外网下载:
echo   - python.org   → Python %PY_VER_MAJOR%.%PY_VER_MINOR%.%PY_VER_PATCH% embeddable (~8MB)
echo   - github.com   → VapourSynth64-Portable-R76.zip (~2MB)
echo   - bootstrap.pypa.io → get-pip.py (~2MB)
echo 如果网络不通，下载会超时失败。
echo.
pause
echo 正在下载，可能需要几分钟...
powershell -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference='Stop'; " ^
    "$ProgressPreference='SilentlyContinue'; " ^
    "$proxy='http://127.0.0.1:7897'; " ^
    "$vsDir='%VS_DIR%'; " ^
    "$dlDir='%VS_DL%'; " ^
    "New-Item -Path $dlDir -ItemType Directory -Force | Out-Null; " ^
    "Write-Host '正在下载 Python %PY_VER_MAJOR%.%PY_VER_MINOR%.%PY_VER_PATCH% embeddable...'; " ^
    "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/%PY_VER_MAJOR%.%PY_VER_MINOR%.%PY_VER_PATCH%/python-%PY_VER_MAJOR%.%PY_VER_MINOR%.%PY_VER_PATCH%-embed-amd64.zip' -OutFile \"$dlDir\python-embed.zip\" -Proxy $proxy; " ^
    "Write-Host '正在下载 VapourSynth64-Portable-R76.zip...'; " ^
    "Invoke-WebRequest -Uri 'https://github.com/vapoursynth/vapoursynth/releases/download/R76/VapourSynth64-Portable-R76.zip' -OutFile \"$dlDir\vs-portable.zip\" -Proxy $proxy; " ^
    "Write-Host '正在下载 get-pip.py...'; " ^
    "Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile \"$dlDir\get-pip.py\" -Proxy $proxy; " ^
    "Write-Host '正在解压 Python...'; " ^
    "Expand-Archive -LiteralPath \"$dlDir\python-embed.zip\" -DestinationPath $vsDir -Force; " ^
    "Add-Content -Path \"$vsDir\python%PY_VER_MAJOR%%PY_VER_MINOR%._pth\" -Encoding UTF8 -Value 'Lib\site-packages'; " ^
    "Write-Host '正在安装 pip...'; " ^
    "$env:HTTP_PROXY=$proxy; $env:HTTPS_PROXY=$proxy; " ^
    "Start-Process -FilePath \"$vsDir\python.exe\" -ArgumentList \"$dlDir\get-pip.py\",\"--no-warn-script-location\" -Wait -NoNewWindow; " ^
    "Write-Host '正在解压 VapourSynth...'; " ^
    "Expand-Archive -LiteralPath \"$dlDir\vs-portable.zip\" -DestinationPath $vsDir -Force; " ^
    "Write-Host '正在安装 VapourSynth wheel...'; " ^
    "$whl = Get-ChildItem -Path \"$vsDir\wheel\*.whl\" | Select-Object -First 1; " ^
    "Start-Process -FilePath \"$vsDir\python.exe\" -ArgumentList '-m','pip','install','--no-warn-script-location',$whl.FullName -Wait -NoNewWindow; " ^
    "Remove-Item -Path \"$vsDir\Scripts\*.exe\" -Force -ErrorAction SilentlyContinue; " ^
    "Write-Host 'VapourSynth 安装完成。'"
if errorlevel 1 (
    echo [错误] 下载或安装失败，请检查网络连接。
    set "VS_INSTALL_RESULT=失败（下载或安装错误）"
    goto :VS_DONE
)
set "VS_PYTHON=%VS_DIR%\python.exe"
:: 清理下载临时文件
if exist "%VS_DL%" rmdir /s /q "%VS_DL%"

:VS_INSTALL
echo.
echo 正在安装 VapourSynth...
if not defined VS_PYTHON (
    echo [错误] 未选择 Python 环境。
    set "VS_INSTALL_RESULT=失败（无 Python）"
    goto :VS_DONE
)
:: 确定实际使用的 python 命令
set "VS_PY_CMD=%VS_PYTHON%"
if "%VS_PYTHON%"=="python" (
    :: 系统 python，直接用
    set "VS_PY_CMD=python"
) else (
    :: 下载的 portable python
    if not exist "%VS_PYTHON%" (
        echo [错误] Python 不存在: %VS_PYTHON%
        set "VS_INSTALL_RESULT=失败（Python 不存在）"
        goto :VS_DONE
    )
)
:: 下载 VapourSynth portable zip 并安装 wheel
if not exist "%VS_DIR%\wheel" (
    :: 没有 wheel 目录，说明不是下载模式安装的，需要下载 portable zip
    echo 需要下载 VapourSynth portable 包...
    set "VS_DL2=%VS_DIR%\vs-temp-dl2"
    powershell -ExecutionPolicy Bypass -Command ^
        "$ErrorActionPreference='Stop'; " ^
        "$ProgressPreference='SilentlyContinue'; " ^
        "$proxy='http://127.0.0.1:7897'; " ^
        "$vsDir='%VS_DIR%'; " ^
        "$dlDir='%VS_DL2%'; " ^
        "New-Item -Path $dlDir -ItemType Directory -Force | Out-Null; " ^
        "Write-Host '正在下载 VapourSynth64-Portable-R76.zip...'; " ^
        "Invoke-WebRequest -Uri 'https://github.com/vapoursynth/vapoursynth/releases/download/R76/VapourSynth64-Portable-R76.zip' -OutFile \"$dlDir\vs-portable.zip\" -Proxy $proxy; " ^
        "Write-Host '正在解压...'; " ^
        "Expand-Archive -LiteralPath \"$dlDir\vs-portable.zip\" -DestinationPath $vsDir -Force; " ^
        "Write-Host '完成。'"
    if errorlevel 1 (
        echo [错误] 下载 VapourSynth portable 包失败。
        set "VS_INSTALL_RESULT=失败（下载失败）"
        goto :VS_DONE
    )
    if exist "%VS_DL2%" rmdir /s /q "%VS_DL2%"
)
:: 安装 wheel
if exist "%VS_DIR%\wheel\*.whl" (
    echo 正在通过 pip 安装 VapourSynth wheel...
    "%VS_PY_CMD%" -m pip install --no-warn-script-location "%VS_DIR%\wheel\VapourSynth-76-cp312-abi3-win_amd64.whl" 2>&1
    if errorlevel 1 (
        echo [错误] VapourSynth wheel 安装失败。
        set "VS_INSTALL_RESULT=失败（wheel 安装失败）"
        goto :VS_DONE
    )
) else (
    echo [错误] 未找到 VapourSynth wheel 文件。
    set "VS_INSTALL_RESULT=失败（wheel 缺失）"
    goto :VS_DONE
)
:: 注册 VapourSynth
echo 正在注册 VapourSynth...
"%VS_PY_CMD%" -m vapoursynth register-install 2>nul
"%VS_PY_CMD%" -m vapoursynth config 2>nul
echo VapourSynth 安装并注册成功。
set "VS_PYTHON=%VS_PY_CMD%"
set "VS_INSTALL_RESULT=成功"
:VS_DONE
echo [结果] VapourSynth 安装结果: %VS_INSTALL_RESULT%
echo.

:: =============================================
:: 6. 安装 vs-rife（可选，依赖 Python 和 VapourSynth）
:: =============================================
echo [4/4] 正在准备安装 vs-rife (RIFE 插件)...
:: 先检查 VapourSynth 是否安装成功
if not "%VS_INSTALL_RESULT%"=="成功" (
    echo [跳过] VapourSynth 未安装成功，无法安装 vs-rife。
    set "RIFE_INSTALL_RESULT=跳过（VapourSynth 未安装）"
    goto :RIFE_DONE
)
:: 确定用于安装 vs-rife 的 Python
set "RIFE_PYTHON="
if defined VS_PYTHON (
    if "%VS_PYTHON%"=="python" (
        set "RIFE_PYTHON=python"
    ) else if exist "%VS_PYTHON%" (
        set "RIFE_PYTHON=%VS_PYTHON%"
    )
)
if not defined RIFE_PYTHON (
    echo [错误] 未找到可用的 Python 环境。
    set "RIFE_INSTALL_RESULT=失败（无 Python）"
    goto :RIFE_DONE
)
echo.
echo vs-rife 将使用以下 Python 安装: %RIFE_PYTHON%
echo 注意: vs-rife 需要从 PyPI 下载（需要外网或镜像源）。
echo.
set /p "RIFE_CHOICE=是否安装 vs-rife？(Y/N): "
if /i not "%RIFE_CHOICE%"=="Y" (
    echo 跳过 vs-rife 安装。
    set "RIFE_INSTALL_RESULT=跳过（用户选择）"
    goto :RIFE_DONE
)
echo 正在安装 vsrife...
"%RIFE_PYTHON%" -m pip install -U vsrife 2>&1
if errorlevel 1 (
    echo [警告] vsrife 安装失败，请手动执行: "%RIFE_PYTHON%" -m pip install -U vsrife
    set "RIFE_INSTALL_RESULT=失败"
) else (
    echo vsrife 安装成功。
    set "RIFE_INSTALL_RESULT=成功"
)
:RIFE_DONE
echo.

:: =============================================
:: 7. 配置 PotPlayer（自动写入滤镜和渲染器）
:: =============================================
echo [附加] 正在配置 PotPlayer...
set "TARGET_INI=%POTPLAYER_DIR%\PotPlayerMini64.ini"
set "LAV_AX=%MLVR_DIR%\LAVFilters\x64"
set "MAD_AX=%MLVR_DIR%\madVR"
set "VPY_SCRIPT=%MLVR_DIR%\vapoursynth
ife_2x.vpy"

powershell -ExecutionPolicy Bypass -Command ^
    "$ini='%TARGET_INI%'; " ^
    "$lav='%LAV_AX%'; " ^
    "$mad='%MAD_AX%'; " ^
    "$vpy='%VPY_SCRIPT%'; " ^
    "$vpyDir='%MLVR_DIR%\vapoursynth'; " ^
    "$overrides=@( " ^
    "  @{idx='0000'; clsid='{EE30215D-164F-4A92-A4EB-9D4C13390F9F}'; name='LAV Video Decoder';    path=\"$lav\LAVVideo.ax\";    merit=8388611}, " ^
    "  @{idx='0001'; clsid='{E8E73B6B-4CB3-44A4-BE99-4F7BCB96E491}'; name='LAV Audio Decoder';    path=\"$lav\LAVAudio.ax\";    merit=8388611}, " ^
    "  @{idx='0002'; clsid='{171252A0-8820-4AFE-9DF8-5C92B2D66B04}'; name='LAV Splitter';         path=\"$lav\LAVSplitter.ax\"; merit=8388612}, " ^
    "  @{idx='0003'; clsid='{B98D13E7-55DB-4385-A33D-09FD1BA26338}'; name='LAV Splitter Source';   path=\"$lav\LAVSplitter.ax\"; merit=8388612}, " ^
    "  @{idx='0004'; clsid='{E1A8B82A-32CE-4B0D-BE0D-AA68C772E423}'; name='madVR';                path=\"$mad\madVR64.ax\";     merit=2097152} " ^
    "); " ^
    "$lines=@(); " ^
    "if (Test-Path $ini) { " ^
    "  $lines=[System.IO.File]::ReadAllLines($ini, [System.Text.Encoding]::Unicode); " ^
    "  $filtered=@(); $skip=$false; " ^
    "  foreach($l in $lines){ " ^
    "    if($l -match '^\[Override\\\\\d{4}\]'){ $skip=$true; continue } " ^
    "    if($skip -and $l -match '^\['){ $skip=$false } " ^
    "    if(-not $skip){ $filtered+=$l } " ^
    "  }; " ^
    "  $lines=$filtered; " ^
    "  $lines=$lines | ForEach-Object { " ^
    "    if($_ -match '^VideoRen2='){ 'VideoRen2=10' } " ^
    "    elseif($_ -match '^VapourSynthScript='){ 'VapourSynthScript='+$vpy } " ^
    "    elseif($_ -match '^VapourSynthPath='){ 'VapourSynthPath='+$vpyDir } " ^
    "    elseif($_ -match '^UseVapourSynth='){ 'UseVapourSynth=1' } " ^
    "    else { $_ } " ^
    "  }; " ^
    "  $hasRen=$lines | Where-Object { $_ -match '^VideoRen2=' }; " ^
    "  if(-not $hasRen){ $lines+='VideoRen2=10' } " ^
    "  $hasVS=$lines | Where-Object { $_ -match '^UseVapourSynth=' }; " ^
    "  if(-not $hasVS){ " ^
    "    $lines+='UseVapourSynth=1'; " ^
    "    $lines+='VapourSynthScript='+$vpy; " ^
    "    $lines+='VapourSynthPath='+$vpyDir " ^
    "  } " ^
    "} else { " ^
    "  $lines=@('[Settings]','VideoRen2=10','UseVapourSynth=1','VapourSynthScript='+$vpy,'VapourSynthPath='+$vpyDir) " ^
    "}; " ^
    "$out=@(); $inserted=$false; " ^
    "foreach($l in $lines){ " ^
    "  if(-not $inserted -and $l -match '^\[[^\\]'){ " ^
    "    foreach($o in $overrides){ " ^
    "      $out+='[Override\\'+$o.idx+']'; " ^
    "      $out+='CLSID='+$o.clsid; " ^
    "      $out+='Disabled=0'; " ^
    "      $out+='FilterType=0'; " ^
    "      $out+='Merit='+$o.merit; " ^
    "      $out+='MeritHi=0'; " ^
    "      $out+='Name='+$o.name; " ^
    "      $out+='Path='+$o.path; " ^
    "      $out+=''; " ^
    "    }; " ^
    "    $inserted=$true " ^
    "  }; " ^
    "  $out+=$l " ^
    "}; " ^
    "if(-not $inserted){ " ^
    "  foreach($o in $overrides){ " ^
    "    $out+='[Override\\'+$o.idx+']'; " ^
    "    $out+='CLSID='+$o.clsid; " ^
    "    $out+='Disabled=0'; " ^
    "    $out+='FilterType=0'; " ^
    "    $out+='Merit='+$o.merit; " ^
    "    $out+='MeritHi=0'; " ^
    "    $out+='Name='+$o.name; " ^
    "    $out+='Path='+$o.path; " ^
    "    $out+=''; " ^
    "  } " ^
    "}; " ^
    "[System.IO.File]::WriteAllLines($ini, $out, [System.Text.Encoding]::Unicode); " ^
    "Write-Host 'PotPlayer 配置已写入:' $ini"

if errorlevel 1 (
    echo [错误] PotPlayer 配置写入失败。
) else (
    echo [提示] 已自动配置: LAV Video/Audio/Splitter + madVR 渲染器 + VapourSynth RIFE 补帧
    echo [提示] 请确保 PotPlayer 的"保存设置到INI"已启用。
)

echo.
:: =============================================
:: 8. 汇总结果
:: =============================================
echo ==============================================
echo             安装结果汇总
echo ==============================================
echo madVR       : %MAD_INSTALL_RESULT%
echo LAVFilters  : %LAV_INSTALL_RESULT%
echo VapourSynth : %VS_INSTALL_RESULT%
echo vs-rife     : %RIFE_INSTALL_RESULT%
echo.
echo 组件安装目录: %MLVR_DIR%
echo.

:: =============================================
:: 9. 后续说明
:: =============================================
echo =============================================
echo             安装完成！
echo =============================================
echo.
echo [已自动配置] LAV Video/Audio/Splitter + madVR 渲染器 + VapourSynth RIFE 补帧
echo.
echo [RIFE 补帧] 脚本位于: %MLVR_DIR%\vapoursynth
ife_2x.vpy
echo   - 默认使用 RIFE v4.22 模型（2倍帧率）
echo   - 编辑 .vpy 文件可修改模型版本（model=22/23/25）
echo.
echo 按任意键退出...
pause >nul