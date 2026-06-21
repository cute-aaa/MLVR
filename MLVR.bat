1|@echo off
2|chcp 65001 >nul
3|title PotPlayer 组件一键安装配置脚本
4|echo ==============================================
5|echo      PotPlayer 组件 (LAV/madVR/VapourSynth) 安装脚本
6|echo ==============================================
7|echo.
8|
9|:: 检查管理员权限
10|NET SESSION >nul 2>&1
11|IF %ERRORLEVEL% NEQ 0 (
12|    echo [错误] 请以管理员身份运行此脚本！
13|    echo 右键点击本文件 -> "以管理员身份运行"
14|    pause
15|    exit /b 1
16|)
17|
18|:: 进入脚本所在目录
19|cd /d "%~dp0"
20|
21|:: =============================================
22|:: 1. 查找 PotPlayer 安装路径
23|:: =============================================
24|echo [信息] 正在查找 PotPlayer 安装路径...
25|set "POTPLAYER_DIR="
26|:: 尝试 64位 注册表路径
27|for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\DAUM\PotPlayer" /v "InstallPath" 2^>nul') do set "POTPLAYER_DIR=%%b"
28|if defined POTPLAYER_DIR goto :FOUND_POT
29|:: 尝试 32位 注册表路径
30|for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\DAUM\PotPlayer" /v "InstallPath" 2^>nul') do set "POTPLAYER_DIR=%%b"
31| 
32|if defined POTPLAYER_DIR goto :FOUND_POT
33|:: 也尝试 HKCU 路径
34|for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\SOFTWARE\DAUM\PotPlayer" /v "InstallPath" 2^>nul') do set "POTPLAYER_DIR=%%b"
35| 
36|if defined POTPLAYER_DIR goto :FOUND_POT
37|
38|:: 未找到，提示手动输入
39|echo [警告] 未在注册表中找到 PotPlayer 安装路径。
40|echo 请手动输入 PotPlayer 的安装目录（例如 C:\Program Files\DAUM\PotPlayer）
41|set /p "POTPLAYER_DIR=请输入路径: "
42|if not exist "%POTPLAYER_DIR%" (
43|    echo [错误] 输入的路径不存在，请重新运行脚本。
44|    pause
45|    exit /b 1
46|	 
47|)
48|:: =============================================
49|:: 2. 创建 MLVR 目录
50|:: =============================================
51|set "MLVR_DIR=%POTPLAYER_DIR%\MLVR"
52|if not exist "%MLVR_DIR%" mkdir "%MLVR_DIR%"
53|echo [信息] 组件将安装到: %MLVR_DIR%
54|echo.
55|
56|:: =============================================
57|:: 3. 处理 madVR (检查/下载 + 解压)
58|:: =============================================
59|echo [1/4] 正在安装 madVR...
60|set "MAD_DIR=%MLVR_DIR%\madVR"
61|if exist "%MAD_DIR%" rmdir /s /q "%MAD_DIR%"
62|for /f "delims=" %%i in ('dir /b /a-d madvr*.zip 2^>nul') do (
63|    set "MAD_ZIP=%%i"
64|    goto :MAD_FOUND
65|)
66|echo [提示] 未找到本地 madvr*.zip。
67|echo   需要从外网下载: www.madshi.net/madVR.zip
68|echo.
69|set /p "MAD_DL=是否下载 madVR？(Y/N): "
70|if /i not "%MAD_DL%"=="Y" (
71|    set "MAD_INSTALL_RESULT=跳过（用户选择）"
72|    goto :MAD_DONE
73|)
74|echo 正在下载 madVR...
75|powershell -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://www.madshi.net/madVR.zip' -OutFile '%~dp0madvr.zip'"
76|if errorlevel 1 (
77|    echo [错误] madVR 下载失败，请检查网络。
78|    set "MAD_INSTALL_RESULT=失败（下载失败）"
79|    goto :MAD_DONE
80|)
81|set "MAD_ZIP=madvr.zip"
82|:MAD_FOUND
83|echo 找到 madVR 压缩包: %MAD_ZIP%
84|powershell -command "Expand-Archive -Path '%MAD_ZIP%' -DestinationPath '%MAD_DIR%' -Force"
85|if errorlevel 1 (
86|    echo [错误] 解压 madVR 失败。
87|    set "MAD_INSTALL_RESULT=失败（解压错误）"
88|    goto :MAD_DONE
89|)
90|:: 处理可能的多层目录
91|if exist "%MAD_DIR%\madVR" (
92|    echo 检测到压缩包内含 madVR 子目录，正在移动文件...
93|    move /y "%MAD_DIR%\madVR\*" "%MAD_DIR%\" >nul 2>&1
94|    rmdir /s /q "%MAD_DIR%\madVR"
95|)
96|:: 注册 madVR
97|cd /d "%MAD_DIR%"
98|if exist "install.bat" (
99|    call install.bat >nul 2>&1
100|    echo.
101|    if errorlevel 1 (
102|        echo [错误] madVR 注册失败。
103|        set "MAD_INSTALL_RESULT=失败（注册错误）"
104|    ) else (
105|        echo madVR 安装成功。
106|        set "MAD_INSTALL_RESULT=成功"
107|    )
108|) else (
109|    regsvr32 /s "%MAD_DIR%\madVR.ax"
110|    echo.
111|    if errorlevel 1 (
112|        echo [错误] madVR 注册失败。
113|        set "MAD_INSTALL_RESULT=失败（注册错误）"
114|    ) else (
115|        echo madVR 安装成功（手动注册 madVR.ax）。
116|        set "MAD_INSTALL_RESULT=成功"
117|    )
118|)
119|cd /d "%~dp0"
120|:MAD_DONE
121|echo [结果] madVR 安装结果: %MAD_INSTALL_RESULT%
122|echo.
123|
124|:: =============================================
125|:: 4. 安装 LAVFilters (检查/下载 + 静默安装)
126|:: =============================================
127|echo [2/4] 正在安装 LAVFilters...
128|set "LAV_DIR=%MLVR_DIR%\LAVFilters"
129|if not exist "%LAV_DIR%" mkdir "%LAV_DIR%"
130|for /f "delims=" %%i in ('dir /b /a-d LAVFilters*.exe 2^>nul') do (
131|    set "LAV_EXE=%%i"
132|    goto :LAV_FOUND
133|)
134|echo [提示] 未找到本地 LAVFilters*.exe。
135|echo   需要从外网下载: github.com/Nevcairiel/LAVFilters/releases
136|echo.
137|set /p "LAV_DL=是否下载 LAVFilters？(Y/N): "
138|if /i not "%LAV_DL%"=="Y" (
139|    set "LAV_INSTALL_RESULT=跳过（用户选择）"
140|    goto :LAV_DONE
141|)
142|echo 正在下载 LAVFilters 0.82...
143|powershell -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://github.com/Nevcairiel/LAVFilters/releases/download/0.82/LAVFilters-0.82-Installer.exe' -OutFile '%~dp0LAVFilters-0.82-Installer.exe'"
144|if errorlevel 1 (
145|    echo [错误] LAVFilters 下载失败，请检查网络。
146|    set "LAV_INSTALL_RESULT=失败（下载失败）"
147|    goto :LAV_DONE
148|)
149|set "LAV_EXE=LAVFilters-0.82-Installer.exe"
150|:LAV_FOUND
151|echo 找到 LAVFilters 安装包: %LAV_EXE%
152|echo 正在静默安装到 %LAV_DIR% ...
153|start /wait "" "%LAV_EXE%" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /DIR="%LAV_DIR%" /COMPONENTS="lavsplitter64,lavaudio64,lavvideo64"
154|if errorlevel 1 (
155|    echo [错误] LAVFilters 安装失败。
156|    set "LAV_INSTALL_RESULT=失败（安装错误）"
157|) else (
158|    echo LAVFilters 安装成功。
159|    set "LAV_INSTALL_RESULT=成功"
160|)
161|:LAV_DONE
162|echo [结果] LAVFilters 安装结果: %LAV_INSTALL_RESULT%
163|echo.
164|
165|:: =============================================
166|:: 5. 安装 VapourSynth
167|:: =============================================
168|echo [3/4] 正在准备安装 VapourSynth...
169|set "VS_DIR=%MLVR_DIR%\VapourSynth"
170|if not exist "%VS_DIR%" mkdir "%VS_DIR%"
171|:: VapourSynth R76 的 wheel 编译为 cp312-abi3，需要 Python 3.12+
172|echo.
173|echo =============================================
174|echo   VapourSynth R76 需要 Python 3.12 或更高版本
175|echo   当前系统 Python 版本:
176|echo =============================================
177|set "SYS_PYTHON="
178|set "SYS_PY_VER="
179|:: 检查 PATH 中的 python
180|for /f "delims=" %%v in ('python --version 2^>nul') do set "SYS_PY_VER=%%v"
181|if defined SYS_PY_VER (
182|    echo   [系统] %SYS_PY_VER%
183|    set "SYS_PYTHON=python"
184|) else (
185|    echo   [系统] 未检测到 Python
186|)
187|:: 检查 py launcher
188|for /f "delims=" %%v in ('py --version 2^>nul') do set "PY_LAUNCHER_VER=%%v"
189|if defined PY_LAUNCHER_VER (
190|    if not defined SYS_PY_VER (
191|        echo   [py] %PY_LAUNCHER_VER%
192|    )
193|)
194|:: 检查是否满足 3.12+ 要求
195|set "PY_OK=0"
196|if defined SYS_PY_VER (
197|    for /f "tokens=2 delims= " %%v in ("%SYS_PY_VER%") do (
198|        for /f "tokens=1,2 delims=." %%a in ("%%v") do (
199|            if %%a GEQ 3 (
200|                if %%a EQU 3 (
201|                    if %%b GEQ 12 set "PY_OK=1"
202|                ) else (
203|                    set "PY_OK=1"
204|                )
205|            )
206|        )
207|    )
208|)
209|echo.
210|set "VS_PYTHON="
211|if "%PY_OK%"=="1" goto :PY_ENOUGH
212|goto :PY_NOT_ENOUGH
213|
214|:PY_ENOUGH
215|echo [√] 系统 Python 版本满足 VapourSynth R76 要求。
216|echo.
217|set /p "PY_CHOICE=是否使用系统 Python 安装 VapourSynth？(Y=使用系统Python / N=下载独立Python): "
218|if /i "%PY_CHOICE%"=="Y" goto :PY_USE_SYSTEM
219|goto :VS_DOWNLOAD_PY
220|
221|:PY_USE_SYSTEM
222|set "VS_PYTHON=python"
223|echo 将使用系统 Python 安装 VapourSynth。
224|goto :VS_INSTALL
225|
226|:PY_NOT_ENOUGH
227|if defined SYS_PY_VER (
228|    echo [X] 系统 %SYS_PY_VER% 版本过低，VapourSynth R76 需要 3.12+。
229|)
230|echo.
231|echo 选项:
232|echo   [Y] 下载 Python 3.14 embeddable（需要外网访问 python.org 和 github.com）
233|echo   [N] 跳过 VapourSynth 安装
234|echo.
235|set /p "PY_CHOICE=请选择 (Y/N): "
236|if /i "%PY_CHOICE%"=="Y" goto :VS_DOWNLOAD_PY
237|echo 跳过 VapourSynth 安装。
238|set "VS_INSTALL_RESULT=跳过（用户选择）"
239|goto :VS_DONE
240|
241|:VS_DOWNLOAD_PY
242|set "VS_DL=%VS_DIR%\vs-temp-dl"
243|set "PY_VER_MAJOR=3"
244|set "PY_VER_MINOR=14"
245|set "PY_VER_PATCH=1"
246|echo.
247|echo 注意: 以下文件需要从外网下载:
248|echo   - python.org   → Python %PY_VER_MAJOR%.%PY_VER_MINOR%.%PY_VER_PATCH% embeddable (~8MB)
249|echo   - github.com   → VapourSynth64-Portable-R76.zip (~2MB)
250|echo   - bootstrap.pypa.io → get-pip.py (~2MB)
251|echo 如果网络不通，下载会超时失败。
252|echo.
253|pause
254|echo 正在下载，可能需要几分钟...
255|powershell -ExecutionPolicy Bypass -Command ^
256|    "$ErrorActionPreference='Stop'; " ^
257|    "$ProgressPreference='SilentlyContinue'; " ^
259|    "$vsDir='%VS_DIR%'; " ^
260|    "$dlDir='%VS_DL%'; " ^
261|    "New-Item -Path $dlDir -ItemType Directory -Force | Out-Null; " ^
262|    "Write-Host '正在下载 Python %PY_VER_MAJOR%.%PY_VER_MINOR%.%PY_VER_PATCH% embeddable...'; " ^
263|    "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/%PY_VER_MAJOR%.%PY_VER_MINOR%.%PY_VER_PATCH%/python-%PY_VER_MAJOR%.%PY_VER_MINOR%.%PY_VER_PATCH%-embed-amd64.zip' -OutFile \"$dlDir\python-embed.zip\"; " ^
264|    "Write-Host '正在下载 VapourSynth64-Portable-R76.zip...'; " ^
265|    "Invoke-WebRequest -Uri 'https://github.com/vapoursynth/vapoursynth/releases/download/R76/VapourSynth64-Portable-R76.zip' -OutFile \"$dlDir\vs-portable.zip\"; " ^
266|    "Write-Host '正在下载 get-pip.py...'; " ^
267|    "Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile \"$dlDir\get-pip.py\"; " ^
268|    "Write-Host '正在解压 Python...'; " ^
269|    "Expand-Archive -LiteralPath \"$dlDir\python-embed.zip\" -DestinationPath $vsDir -Force; " ^
270|    "Add-Content -Path \"$vsDir\python%PY_VER_MAJOR%%PY_VER_MINOR%._pth\" -Encoding UTF8 -Value 'Lib\site-packages'; " ^
271|    "Write-Host '正在安装 pip...'; " ^
273|    "Start-Process -FilePath \"$vsDir\python.exe\" -ArgumentList \"$dlDir\get-pip.py\",\"--no-warn-script-location\" -Wait -NoNewWindow; " ^
274|    "Write-Host '正在解压 VapourSynth...'; " ^
275|    "Expand-Archive -LiteralPath \"$dlDir\vs-portable.zip\" -DestinationPath $vsDir -Force; " ^
276|    "Write-Host '正在安装 VapourSynth wheel...'; " ^
277|    "$whl = Get-ChildItem -Path \"$vsDir\wheel\*.whl\" | Select-Object -First 1; " ^
278|    "Start-Process -FilePath \"$vsDir\python.exe\" -ArgumentList '-m','pip','install','--no-warn-script-location',$whl.FullName -Wait -NoNewWindow; " ^
279|    "Remove-Item -Path \"$vsDir\Scripts\*.exe\" -Force -ErrorAction SilentlyContinue; " ^
280|    "Write-Host 'VapourSynth 安装完成。'"
281|if errorlevel 1 (
282|    echo [错误] 下载或安装失败，请检查网络连接。
283|    set "VS_INSTALL_RESULT=失败（下载或安装错误）"
284|    goto :VS_DONE
285|)
286|set "VS_PYTHON=%VS_DIR%\python.exe"
287|:: 清理下载临时文件
288|if exist "%VS_DL%" rmdir /s /q "%VS_DL%"
289|
290|:VS_INSTALL
291|echo.
292|echo 正在安装 VapourSynth...
293|if not defined VS_PYTHON (
294|    echo [错误] 未选择 Python 环境。
295|    set "VS_INSTALL_RESULT=失败（无 Python）"
296|    goto :VS_DONE
297|)
298|:: 确定实际使用的 python 命令
299|set "VS_PY_CMD=%VS_PYTHON%"
300|if "%VS_PYTHON%"=="python" (
301|    :: 系统 python，直接用
302|    set "VS_PY_CMD=python"
303|) else (
304|    :: 下载的 portable python
305|    if not exist "%VS_PYTHON%" (
306|        echo [错误] Python 不存在: %VS_PYTHON%
307|        set "VS_INSTALL_RESULT=失败（Python 不存在）"
308|        goto :VS_DONE
309|    )
310|)
311|:: 下载 VapourSynth portable zip 并安装 wheel
312|if not exist "%VS_DIR%\wheel" (
313|    :: 没有 wheel 目录，说明不是下载模式安装的，需要下载 portable zip
314|    echo 需要下载 VapourSynth portable 包...
315|    set "VS_DL2=%VS_DIR%\vs-temp-dl2"
316|    powershell -ExecutionPolicy Bypass -Command ^
317|        "$ErrorActionPreference='Stop'; " ^
318|        "$ProgressPreference='SilentlyContinue'; " ^
320|        "$vsDir='%VS_DIR%'; " ^
321|        "$dlDir='%VS_DL2%'; " ^
322|        "New-Item -Path $dlDir -ItemType Directory -Force | Out-Null; " ^
323|        "Write-Host '正在下载 VapourSynth64-Portable-R76.zip...'; " ^
324|        "Invoke-WebRequest -Uri 'https://github.com/vapoursynth/vapoursynth/releases/download/R76/VapourSynth64-Portable-R76.zip' -OutFile \"$dlDir\vs-portable.zip\"; " ^
325|        "Write-Host '正在解压...'; " ^
326|        "Expand-Archive -LiteralPath \"$dlDir\vs-portable.zip\" -DestinationPath $vsDir -Force; " ^
327|        "Write-Host '完成。'"
328|    if errorlevel 1 (
329|        echo [错误] 下载 VapourSynth portable 包失败。
330|        set "VS_INSTALL_RESULT=失败（下载失败）"
331|        goto :VS_DONE
332|    )
333|    if exist "%VS_DL2%" rmdir /s /q "%VS_DL2%"
334|)
335|:: 安装 wheel
336|if exist "%VS_DIR%\wheel\*.whl" (
337|    echo 正在通过 pip 安装 VapourSynth wheel...
338|    "%VS_PY_CMD%" -m pip install --no-warn-script-location "%VS_DIR%\wheel\VapourSynth-76-cp312-abi3-win_amd64.whl" 2>&1
339|    if errorlevel 1 (
340|        echo [错误] VapourSynth wheel 安装失败。
341|        set "VS_INSTALL_RESULT=失败（wheel 安装失败）"
342|        goto :VS_DONE
343|    )
344|) else (
345|    echo [错误] 未找到 VapourSynth wheel 文件。
346|    set "VS_INSTALL_RESULT=失败（wheel 缺失）"
347|    goto :VS_DONE
348|)
349|:: 注册 VapourSynth
350|echo 正在注册 VapourSynth...
351|"%VS_PY_CMD%" -m vapoursynth register-install 2>nul
352|"%VS_PY_CMD%" -m vapoursynth config 2>nul
353|echo VapourSynth 安装并注册成功。
354|set "VS_PYTHON=%VS_PY_CMD%"
355|set "VS_INSTALL_RESULT=成功"
356|:VS_DONE
357|echo [结果] VapourSynth 安装结果: %VS_INSTALL_RESULT%
358|echo.
359|
360|:: =============================================
361|:: 6. 安装 vs-rife（可选，依赖 Python 和 VapourSynth）
362|:: =============================================
363|echo [4/4] 正在准备安装 vs-rife (RIFE 插件)...
364|:: 先检查 VapourSynth 是否安装成功
365|if not "%VS_INSTALL_RESULT%"=="成功" (
366|    echo [跳过] VapourSynth 未安装成功，无法安装 vs-rife。
367|    set "RIFE_INSTALL_RESULT=跳过（VapourSynth 未安装）"
368|    goto :RIFE_DONE
369|)
370|:: 确定用于安装 vs-rife 的 Python
371|set "RIFE_PYTHON="
372|if defined VS_PYTHON (
373|    if "%VS_PYTHON%"=="python" (
374|        set "RIFE_PYTHON=python"
375|    ) else if exist "%VS_PYTHON%" (
376|        set "RIFE_PYTHON=%VS_PYTHON%"
377|    )
378|)
379|if not defined RIFE_PYTHON (
380|    echo [错误] 未找到可用的 Python 环境。
381|    set "RIFE_INSTALL_RESULT=失败（无 Python）"
382|    goto :RIFE_DONE
383|)
384|echo.
385|echo vs-rife 将使用以下 Python 安装: %RIFE_PYTHON%
386|echo 注意: vs-rife 需要从 PyPI 下载（需要外网或镜像源）。
387|echo.
388|set /p "RIFE_CHOICE=是否安装 vs-rife？(Y/N): "
389|if /i not "%RIFE_CHOICE%"=="Y" (
390|    echo 跳过 vs-rife 安装。
391|    set "RIFE_INSTALL_RESULT=跳过（用户选择）"
392|    goto :RIFE_DONE
393|)
394|echo 正在安装 vsrife...
395|"%RIFE_PYTHON%" -m pip install -U vsrife 2>&1
396|if errorlevel 1 (
397|    echo [警告] vsrife 安装失败，请手动执行: "%RIFE_PYTHON%" -m pip install -U vsrife
398|    set "RIFE_INSTALL_RESULT=失败"
399|) else (
400|    echo vsrife 安装成功。
401|    set "RIFE_INSTALL_RESULT=成功"
402|)
403|:RIFE_DONE
404|echo.
405|
406|:: =============================================
407|:: 7. 配置 PotPlayer（自动写入滤镜和渲染器）
408|:: =============================================
409|echo [附加] 正在配置 PotPlayer...
410|set "TARGET_INI=%POTPLAYER_DIR%\PotPlayerMini64.ini"
411|set "LAV_AX=%MLVR_DIR%\LAVFilters\x64"
412|set "MAD_AX=%MLVR_DIR%\madVR"
413|set "VPY_SCRIPT=%MLVR_DIR%\vapoursynth
414|ife_2x.vpy"
415|
416|powershell -ExecutionPolicy Bypass -Command ^
417|    "$ini='%TARGET_INI%'; " ^
418|    "$lav='%LAV_AX%'; " ^
419|    "$mad='%MAD_AX%'; " ^
420|    "$vpy='%VPY_SCRIPT%'; " ^
421|    "$vpyDir='%MLVR_DIR%\vapoursynth'; " ^
422|    "$overrides=@( " ^
423|    "  @{idx='0000'; clsid='{EE30215D-164F-4A92-A4EB-9D4C13390F9F}'; name='LAV Video Decoder';    path=\"$lav\LAVVideo.ax\";    merit=8388611}, " ^
424|    "  @{idx='0001'; clsid='{E8E73B6B-4CB3-44A4-BE99-4F7BCB96E491}'; name='LAV Audio Decoder';    path=\"$lav\LAVAudio.ax\";    merit=8388611}, " ^
425|    "  @{idx='0002'; clsid='{171252A0-8820-4AFE-9DF8-5C92B2D66B04}'; name='LAV Splitter';         path=\"$lav\LAVSplitter.ax\"; merit=8388612}, " ^
426|    "  @{idx='0003'; clsid='{B98D13E7-55DB-4385-A33D-09FD1BA26338}'; name='LAV Splitter Source';   path=\"$lav\LAVSplitter.ax\"; merit=8388612}, " ^
427|    "  @{idx='0004'; clsid='{E1A8B82A-32CE-4B0D-BE0D-AA68C772E423}'; name='madVR';                path=\"$mad\madVR64.ax\";     merit=2097152} " ^
428|    "); " ^
429|    "$lines=@(); " ^
430|    "if (Test-Path $ini) { " ^
431|    "  $lines=[System.IO.File]::ReadAllLines($ini, [System.Text.Encoding]::Unicode); " ^
432|    "  $filtered=@(); $skip=$false; " ^
433|    "  foreach($l in $lines){ " ^
434|    "    if($l -match '^\[Override\\\\\d{4}\]'){ $skip=$true; continue } " ^
435|    "    if($skip -and $l -match '^\['){ $skip=$false } " ^
436|    "    if(-not $skip){ $filtered+=$l } " ^
437|    "  }; " ^
438|    "  $lines=$filtered; " ^
439|    "  $lines=$lines | ForEach-Object { " ^
440|    "    if($_ -match '^VideoRen2='){ 'VideoRen2=10' } " ^
441|    "    elseif($_ -match '^VapourSynthScript='){ 'VapourSynthScript='+$vpy } " ^
442|    "    elseif($_ -match '^VapourSynthPath='){ 'VapourSynthPath='+$vpyDir } " ^
443|    "    elseif($_ -match '^UseVapourSynth='){ 'UseVapourSynth=1' } " ^
444|    "    else { $_ } " ^
445|    "  }; " ^
446|    "  $hasRen=$lines | Where-Object { $_ -match '^VideoRen2=' }; " ^
447|    "  if(-not $hasRen){ $lines+='VideoRen2=10' } " ^
448|    "  $hasVS=$lines | Where-Object { $_ -match '^UseVapourSynth=' }; " ^
449|    "  if(-not $hasVS){ " ^
450|    "    $lines+='UseVapourSynth=1'; " ^
451|    "    $lines+='VapourSynthScript='+$vpy; " ^
452|    "    $lines+='VapourSynthPath='+$vpyDir " ^
453|    "  } " ^
454|    "} else { " ^
455|    "  $lines=@('[Settings]','VideoRen2=10','UseVapourSynth=1','VapourSynthScript='+$vpy,'VapourSynthPath='+$vpyDir) " ^
456|    "}; " ^
457|    "$out=@(); $inserted=$false; " ^
458|    "foreach($l in $lines){ " ^
459|    "  if(-not $inserted -and $l -match '^\[[^\\]'){ " ^
460|    "    foreach($o in $overrides){ " ^
461|    "      $out+='[Override\\'+$o.idx+']'; " ^
462|    "      $out+='CLSID='+$o.clsid; " ^
463|    "      $out+='Disabled=0'; " ^
464|    "      $out+='FilterType=0'; " ^
465|    "      $out+='Merit='+$o.merit; " ^
466|    "      $out+='MeritHi=0'; " ^
467|    "      $out+='Name='+$o.name; " ^
468|    "      $out+='Path='+$o.path; " ^
469|    "      $out+=''; " ^
470|    "    }; " ^
471|    "    $inserted=$true " ^
472|    "  }; " ^
473|    "  $out+=$l " ^
474|    "}; " ^
475|    "if(-not $inserted){ " ^
476|    "  foreach($o in $overrides){ " ^
477|    "    $out+='[Override\\'+$o.idx+']'; " ^
478|    "    $out+='CLSID='+$o.clsid; " ^
479|    "    $out+='Disabled=0'; " ^
480|    "    $out+='FilterType=0'; " ^
481|    "    $out+='Merit='+$o.merit; " ^
482|    "    $out+='MeritHi=0'; " ^
483|    "    $out+='Name='+$o.name; " ^
484|    "    $out+='Path='+$o.path; " ^
485|    "    $out+=''; " ^
486|    "  } " ^
487|    "}; " ^
488|    "[System.IO.File]::WriteAllLines($ini, $out, [System.Text.Encoding]::Unicode); " ^
489|    "Write-Host 'PotPlayer 配置已写入:' $ini"
490|
491|if errorlevel 1 (
492|    echo [错误] PotPlayer 配置写入失败。
493|) else (
494|    echo [提示] 已自动配置: LAV Video/Audio/Splitter + madVR 渲染器 + VapourSynth RIFE 补帧
495|    echo [提示] 请确保 PotPlayer 的"保存设置到INI"已启用。
496|)
497|
498|echo.
499|:: =============================================
500|:: 8. 汇总结果
501|