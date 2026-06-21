1|@echo off
2|chcp 65001 >nul
3|title PotPlayer Components One-Click Installer
4|echo ==============================================
5|echo      PotPlayer Components (LAV/madVR/VapourSynth) Installer
6|echo ==============================================
7|echo.
8|
9|:: 检查管理员权限
10|NET SESSION >nul 2>&1
11|IF %ERRORLEVEL% NEQ 0 (
12|    echo [错误] Please run this script as Administrator！
13|    echo Right-click this file -> "Run as administrator"
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
24|echo [信息] Searching for PotPlayer installation path...
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
39|echo [警告] PotPlayer installation path not found in registry。
40|echo Please enter PotPlayer installation directory manually（例如 C:\Program Files\DAUM\PotPlayer）
41|set /p "POTPLAYER_DIR=Enter path: "
42|if not exist "%POTPLAYER_DIR%" (
43|    echo [错误] Path does not exist, please re-run the script。
44|    pause
45|    exit /b 1
46|	 
47|)
48|:: =============================================
49|:: 2. 创建 MLVR 目录
50|:: =============================================
51|set "MLVR_DIR=%POTPLAYER_DIR%\MLVR"
52|if not exist "%MLVR_DIR%" mkdir "%MLVR_DIR%"
53|echo [信息] Components will be installed to: %MLVR_DIR%
54|echo.
55|
56|:: =============================================
57|:: 3. 处理 madVR (解压 zip)
58|:: =============================================
59|echo [1/4] Installing madVR...
60|set "MAD_DIR=%MLVR_DIR%\madVR"
61|if exist "%MAD_DIR%" rmdir /s /q "%MAD_DIR%"
62|for /f "delims=" %%i in ('dir /b /a-d madvr*.zip 2^>nul') do (
63|    set "MAD_ZIP=%%i"
64|    goto :MAD_FOUND
65|)
66|echo [错误] madvr*.zip not found, place it in the script directory。
67|set "MAD_INSTALL_RESULT=失败（未找到安装包）"
68|goto :MAD_DONE
69|:MAD_FOUND
70|echo Found madVR archive: %MAD_ZIP%
71|powershell -command "Expand-Archive -Path '%MAD_ZIP%' -DestinationPath '%MAD_DIR%' -Force"
72|if errorlevel 1 (
73|    echo [错误] Failed to extract madVR。
74|    set "MAD_INSTALL_RESULT=失败（解压错误）"
75|    goto :MAD_DONE
76|)
77|:: 处理可能的多层目录
78|if exist "%MAD_DIR%\madVR" (
79|    echo madVR subdirectory detected, moving files...
80|    move /y "%MAD_DIR%\madVR\*" "%MAD_DIR%\" >nul 2>&1
81|    rmdir /s /q "%MAD_DIR%\madVR"
82|)
83|:: 注册 madVR
84|cd /d "%MAD_DIR%"
85|if exist "install.bat" (
86|    call install.bat >nul 2>&1
87|    echo.
88|    if errorlevel 1 (
89|        echo [错误] madVR registration failed。
90|        set "MAD_INSTALL_RESULT=失败（注册错误）"
91|    ) else (
92|        echo madVR installed successfully。
93|        set "MAD_INSTALL_RESULT=成功"
94|    )
95|) else (
96|    regsvr32 /s "%MAD_DIR%\madVR.ax"
97|    echo.
98|    if errorlevel 1 (
99|        echo [错误] madVR registration failed。
100|        set "MAD_INSTALL_RESULT=失败（注册错误）"
101|    ) else (
102|        echo madVR installed successfully（manually registered madVR.ax）。
103|        set "MAD_INSTALL_RESULT=成功"
104|    )
105|)
106|cd /d "%~dp0"
107|:MAD_DONE
108|echo [结果] madVR result: %MAD_INSTALL_RESULT%
109|echo.
110|
111|:: =============================================
112|:: 4. 安装 LAVFilters (exe)
113|:: =============================================
114|echo [2/4] Installing LAVFilters...
115|set "LAV_DIR=%MLVR_DIR%\LAVFilters"
116|if not exist "%LAV_DIR%" mkdir "%LAV_DIR%"
117|for /f "delims=" %%i in ('dir /b /a-d LAVFilters*.exe 2^>nul') do (
118|    set "LAV_EXE=%%i"
119|    goto :LAV_FOUND
120|)
121|echo [错误] LAVFilters*.exe not found。
122|set "LAV_INSTALL_RESULT=失败（未找到安装包）"
123|goto :LAV_DONE
124|:LAV_FOUND
125|echo Found LAVFilters installer: %LAV_EXE%
126|echo Silently installing to %LAV_DIR% ...
127|start /wait "" "%LAV_EXE%" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /DIR="%LAV_DIR%" /COMPONENTS="lavsplitter64,lavaudio64,lavvideo64"
128|if errorlevel 1 (
129|    echo [错误] LAVFilters installation failed。
130|    set "LAV_INSTALL_RESULT=失败（安装错误）"
131|) else (
132|    echo LAVFilters installed successfully。
133|    set "LAV_INSTALL_RESULT=成功"
134|)
135|:LAV_DONE
136|echo [结果] LAVFilters result: %LAV_INSTALL_RESULT%
137|echo.
138|
139|:: =============================================
140|:: 5. 安装 VapourSynth
141|:: =============================================
142|echo [3/4] Preparing to install VapourSynth...
143|set "VS_DIR=%MLVR_DIR%\VapourSynth"
144|if not exist "%VS_DIR%" mkdir "%VS_DIR%"
145|:: VapourSynth R76 的 wheel 编译为 cp312-abi3，需要 Python 3.12+
146|echo.
147|echo =============================================
148|echo   VapourSynth R76 requires Python 3.12 or higher
149|echo   Current system Python version:
150|echo =============================================
151|set "SYS_PYTHON="
152|set "SYS_PY_VER="
153|:: 检查 PATH 中的 python
154|for /f "delims=" %%v in ('python --version 2^>nul') do set "SYS_PY_VER=%%v"
155|if defined SYS_PY_VER (
156|    echo   [系统] %SYS_PY_VER%
157|    set "SYS_PYTHON=python"
158|) else (
159|    echo   [系统] Python not detected
160|)
161|:: 检查 py launcher
162|for /f "delims=" %%v in ('py --version 2^>nul') do set "PY_LAUNCHER_VER=%%v"
163|if defined PY_LAUNCHER_VER (
164|    if not defined SYS_PY_VER (
165|        echo   [py] %PY_LAUNCHER_VER%
166|    )
167|)
168|:: 检查是否满足 3.12+ 要求
169|set "PY_OK=0"
170|if defined SYS_PY_VER (
171|    for /f "tokens=2 delims= " %%v in ("%SYS_PY_VER%") do (
172|        for /f "tokens=1,2 delims=." %%a in ("%%v") do (
173|            if %%a GEQ 3 (
174|                if %%a EQU 3 (
175|                    if %%b GEQ 12 set "PY_OK=1"
176|                ) else (
177|                    set "PY_OK=1"
178|                )
179|            )
180|        )
181|    )
182|)
183|echo.
184|set "VS_PYTHON="
185|if "%PY_OK%"=="1" goto :PY_ENOUGH
186|goto :PY_NOT_ENOUGH
187|
188|:PY_ENOUGH
189|echo [√] System Python meets VapourSynth R76 requirements。
190|echo.
191|set /p "PY_CHOICE=Use system Python for VapourSynth?？(Y=Use system Python / N=Download standalone Python): "
192|if /i "%PY_CHOICE%"=="Y" goto :PY_USE_SYSTEM
193|goto :VS_DOWNLOAD_PY
194|
195|:PY_USE_SYSTEM
196|set "VS_PYTHON=python"
197|echo Will use system Python for VapourSynth。
198|goto :VS_INSTALL
199|
200|:PY_NOT_ENOUGH
201|if defined SYS_PY_VER (
202|    echo [X] 系统 %SYS_PY_VER% version too old, VapourSynth R76 needs 3.12+。
203|)
204|echo.
205|echo 选项:
206|echo   [Y] Download Python 3.14 embeddable (requires internet: python.org & github.com)
207|echo   [N] Skip VapourSynth installation
208|echo.
209|set /p "PY_CHOICE=请选择 (Y/N): "
210|if /i "%PY_CHOICE%"=="Y" goto :VS_DOWNLOAD_PY
211|echo Skip VapourSynth installation。
212|set "VS_INSTALL_RESULT=跳过（user choice）"
213|goto :VS_DONE
214|
215|:VS_DOWNLOAD_PY
216|set "VS_DL=%VS_DIR%\vs-temp-dl"
217|set "PY_VER_MAJOR=3"
218|set "PY_VER_MINOR=14"
219|set "PY_VER_PATCH=1"
220|echo.
221|echo 注意: The following files need to be downloaded from the internet:
222|echo   - python.org   → Python %PY_VER_MAJOR%.%PY_VER_MINOR%.%PY_VER_PATCH% embeddable (~8MB)
223|echo   - github.com   → VapourSynth64-Portable-R76.zip (~2MB)
224|echo   - bootstrap.pypa.io → get-pip.py (~2MB)
225|echo Download will timeout if network is unavailable。
226|echo.
227|pause
228|echo Downloading, this may take a few minutes...
229|powershell -ExecutionPolicy Bypass -Command ^
230|    "$ErrorActionPreference='Stop'; " ^
231|    "$ProgressPreference='SilentlyContinue'; " ^
232|    "$proxy='http://127.0.0.1:7897'; " ^
233|    "$vsDir='%VS_DIR%'; " ^
234|    "$dlDir='%VS_DL%'; " ^
235|    "New-Item -Path $dlDir -ItemType Directory -Force | Out-Null; " ^
236|    "Write-Host '正在下载 Python %PY_VER_MAJOR%.%PY_VER_MINOR%.%PY_VER_PATCH% embeddable...'; " ^
237|    "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/%PY_VER_MAJOR%.%PY_VER_MINOR%.%PY_VER_PATCH%/python-%PY_VER_MAJOR%.%PY_VER_MINOR%.%PY_VER_PATCH%-embed-amd64.zip' -OutFile \"$dlDir\python-embed.zip\" -Proxy $proxy; " ^
238|    "Write-Host '正在下载 VapourSynth64-Portable-R76.zip...'; " ^
239|    "Invoke-WebRequest -Uri 'https://github.com/vapoursynth/vapoursynth/releases/download/R76/VapourSynth64-Portable-R76.zip' -OutFile \"$dlDir\vs-portable.zip\" -Proxy $proxy; " ^
240|    "Write-Host '正在下载 get-pip.py...'; " ^
241|    "Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile \"$dlDir\get-pip.py\" -Proxy $proxy; " ^
242|    "Write-Host '正在解压 Python...'; " ^
243|    "Expand-Archive -LiteralPath \"$dlDir\python-embed.zip\" -DestinationPath $vsDir -Force; " ^
244|    "Add-Content -Path \"$vsDir\python%PY_VER_MAJOR%%PY_VER_MINOR%._pth\" -Encoding UTF8 -Value 'Lib\site-packages'; " ^
245|    "Write-Host '正在安装 pip...'; " ^
246|    "$env:HTTP_PROXY=$proxy; $env:HTTPS_PROXY=$proxy; " ^
247|    "Start-Process -FilePath \"$vsDir\python.exe\" -ArgumentList \"$dlDir\get-pip.py\",\"--no-warn-script-location\" -Wait -NoNewWindow; " ^
248|    "Write-Host '正在解压 VapourSynth...'; " ^
249|    "Expand-Archive -LiteralPath \"$dlDir\vs-portable.zip\" -DestinationPath $vsDir -Force; " ^
250|    "Write-Host 'Installing VapourSynth wheel...'; " ^
251|    "$whl = Get-ChildItem -Path \"$vsDir\wheel\*.whl\" | Select-Object -First 1; " ^
252|    "Start-Process -FilePath \"$vsDir\python.exe\" -ArgumentList '-m','pip','install','--no-warn-script-location',$whl.FullName -Wait -NoNewWindow; " ^
253|    "Remove-Item -Path \"$vsDir\Scripts\*.exe\" -Force -ErrorAction SilentlyContinue; " ^
254|    "Write-Host 'VapourSynth Installation complete。'"
255|if errorlevel 1 (
256|    echo [错误] Download/install failed, check network connection。
257|    set "VS_INSTALL_RESULT=失败（下载或安装错误）"
258|    goto :VS_DONE
259|)
260|set "VS_PYTHON=%VS_DIR%\python.exe"
261|:: 清理下载临时文件
262|if exist "%VS_DL%" rmdir /s /q "%VS_DL%"
263|
264|:VS_INSTALL
265|echo.
266|echo Installing VapourSynth...
267|if not defined VS_PYTHON (
268|    echo [错误] No Python environment selected。
269|    set "VS_INSTALL_RESULT=失败（无 Python）"
270|    goto :VS_DONE
271|)
272|:: 确定实际使用的 python 命令
273|set "VS_PY_CMD=%VS_PYTHON%"
274|if "%VS_PYTHON%"=="python" (
275|    :: 系统 python，直接用
276|    set "VS_PY_CMD=python"
277|) else (
278|    :: 下载的 portable python
279|    if not exist "%VS_PYTHON%" (
280|        echo [错误] Python not found: %VS_PYTHON%
281|        set "VS_INSTALL_RESULT=失败（Python not found）"
282|        goto :VS_DONE
283|    )
284|)
285|:: 下载 VapourSynth portable zip 并安装 wheel
286|if not exist "%VS_DIR%\wheel" (
287|    :: 没有 wheel 目录，说明不是下载模式安装的，需要下载 portable zip
288|    echo Need to download VapourSynth portable package...
289|    set "VS_DL2=%VS_DIR%\vs-temp-dl2"
290|    powershell -ExecutionPolicy Bypass -Command ^
291|        "$ErrorActionPreference='Stop'; " ^
292|        "$ProgressPreference='SilentlyContinue'; " ^
293|        "$proxy='http://127.0.0.1:7897'; " ^
294|        "$vsDir='%VS_DIR%'; " ^
295|        "$dlDir='%VS_DL2%'; " ^
296|        "New-Item -Path $dlDir -ItemType Directory -Force | Out-Null; " ^
297|        "Write-Host '正在下载 VapourSynth64-Portable-R76.zip...'; " ^
298|        "Invoke-WebRequest -Uri 'https://github.com/vapoursynth/vapoursynth/releases/download/R76/VapourSynth64-Portable-R76.zip' -OutFile \"$dlDir\vs-portable.zip\" -Proxy $proxy; " ^
299|        "Write-Host '正在解压...'; " ^
300|        "Expand-Archive -LiteralPath \"$dlDir\vs-portable.zip\" -DestinationPath $vsDir -Force; " ^
301|        "Write-Host '完成。'"
302|    if errorlevel 1 (
303|        echo [错误] Failed to download VapourSynth portable package。
304|        set "VS_INSTALL_RESULT=失败（下载失败）"
305|        goto :VS_DONE
306|    )
307|    if exist "%VS_DL2%" rmdir /s /q "%VS_DL2%"
308|)
309|:: 安装 wheel
310|if exist "%VS_DIR%\wheel\*.whl" (
311|    echo Installing VapourSynth wheel via pip...
312|    "%VS_PY_CMD%" -m pip install --no-warn-script-location "%VS_DIR%\wheel\VapourSynth-76-cp312-abi3-win_amd64.whl" 2>&1
313|    if errorlevel 1 (
314|        echo [错误] VapourSynth wheel installation failed。
315|        set "VS_INSTALL_RESULT=失败（wheel 安装失败）"
316|        goto :VS_DONE
317|    )
318|) else (
319|    echo [错误] VapourSynth wheel file not found。
320|    set "VS_INSTALL_RESULT=失败（wheel 缺失）"
321|    goto :VS_DONE
322|)
323|:: 注册 VapourSynth
324|echo Registering VapourSynth...
325|"%VS_PY_CMD%" -m vapoursynth register-install 2>nul
326|"%VS_PY_CMD%" -m vapoursynth config 2>nul
327|echo VapourSynth installed and registered successfully。
328|set "VS_PYTHON=%VS_PY_CMD%"
329|set "VS_INSTALL_RESULT=成功"
330|:VS_DONE
331|echo [结果] VapourSynth result: %VS_INSTALL_RESULT%
332|echo.
333|
334|:: =============================================
335|:: 6. 安装 vs-rife（可选，依赖 Python 和 VapourSynth）
336|:: =============================================
337|echo [4/4] Preparing to install vs-rife (RIFE plugin)...
338|:: 先检查 VapourSynth 是否安装成功
339|if not "%VS_INSTALL_RESULT%"=="成功" (
340|    echo [跳过] VapourSynth not installed, cannot install vs-rife。
341|    set "RIFE_INSTALL_RESULT=跳过（VapourSynth 未安装）"
342|    goto :RIFE_DONE
343|)
344|:: 确定用于安装 vs-rife 的 Python
345|set "RIFE_PYTHON="
346|if defined VS_PYTHON (
347|    if "%VS_PYTHON%"=="python" (
348|        set "RIFE_PYTHON=python"
349|    ) else if exist "%VS_PYTHON%" (
350|        set "RIFE_PYTHON=%VS_PYTHON%"
351|    )
352|)
353|if not defined RIFE_PYTHON (
354|    echo [错误] No usable Python environment found。
355|    set "RIFE_INSTALL_RESULT=失败（无 Python）"
356|    goto :RIFE_DONE
357|)
358|echo.
359|echo vs-rife will use the following Python: %RIFE_PYTHON%
360|echo 注意: vs-rife needs to download from PyPI (requires internet or mirror)。
361|echo.
362|set /p "RIFE_CHOICE=Install vs-rife?？(Y/N): "
363|if /i not "%RIFE_CHOICE%"=="Y" (
364|    echo Skipping vs-rife installation。
365|    set "RIFE_INSTALL_RESULT=跳过（user choice）"
366|    goto :RIFE_DONE
367|)
368|echo Installing vsrife...
369|"%RIFE_PYTHON%" -m pip install -U vsrife 2>&1
370|if errorlevel 1 (
371|    echo [警告] vsrife installation failed，请手动执行: "%RIFE_PYTHON%" -m pip install -U vsrife
372|    set "RIFE_INSTALL_RESULT=失败"
373|) else (
374|    echo vsrife installed successfully。
375|    set "RIFE_INSTALL_RESULT=成功"
376|)
377|:RIFE_DONE
378|echo.
379|
380|:: =============================================
381|:: 7. 配置 PotPlayer（自动写入滤镜和渲染器）
382|:: =============================================
383|echo [附加] Configuring PotPlayer...
384|set "TARGET_INI=%POTPLAYER_DIR%\PotPlayerMini64.ini"
385|set "LAV_AX=%MLVR_DIR%\LAVFilters\x64"
386|set "MAD_AX=%MLVR_DIR%\madVR"
387|set "VPY_SCRIPT=%MLVR_DIR%\vapoursynth
388|ife_2x.vpy"
389|
390|powershell -ExecutionPolicy Bypass -Command ^
391|    "$ini='%TARGET_INI%'; " ^
392|    "$lav='%LAV_AX%'; " ^
393|    "$mad='%MAD_AX%'; " ^
394|    "$vpy='%VPY_SCRIPT%'; " ^
395|    "$vpyDir='%MLVR_DIR%\vapoursynth'; " ^
396|    "$overrides=@( " ^
397|    "  @{idx='0000'; clsid='{EE30215D-164F-4A92-A4EB-9D4C13390F9F}'; name='LAV Video Decoder';    path=\"$lav\LAVVideo.ax\";    merit=8388611}, " ^
398|    "  @{idx='0001'; clsid='{E8E73B6B-4CB3-44A4-BE99-4F7BCB96E491}'; name='LAV Audio Decoder';    path=\"$lav\LAVAudio.ax\";    merit=8388611}, " ^
399|    "  @{idx='0002'; clsid='{171252A0-8820-4AFE-9DF8-5C92B2D66B04}'; name='LAV Splitter';         path=\"$lav\LAVSplitter.ax\"; merit=8388612}, " ^
400|    "  @{idx='0003'; clsid='{B98D13E7-55DB-4385-A33D-09FD1BA26338}'; name='LAV Splitter Source';   path=\"$lav\LAVSplitter.ax\"; merit=8388612}, " ^
401|    "  @{idx='0004'; clsid='{E1A8B82A-32CE-4B0D-BE0D-AA68C772E423}'; name='madVR';                path=\"$mad\madVR64.ax\";     merit=2097152} " ^
402|    "); " ^
403|    "$lines=@(); " ^
404|    "if (Test-Path $ini) { " ^
405|    "  $lines=[System.IO.File]::ReadAllLines($ini, [System.Text.Encoding]::Unicode); " ^
406|    "  $filtered=@(); $skip=$false; " ^
407|    "  foreach($l in $lines){ " ^
408|    "    if($l -match '^\[Override\\\\\d{4}\]'){ $skip=$true; continue } " ^
409|    "    if($skip -and $l -match '^\['){ $skip=$false } " ^
410|    "    if(-not $skip){ $filtered+=$l } " ^
411|    "  }; " ^
412|    "  $lines=$filtered; " ^
413|    "  $lines=$lines | ForEach-Object { " ^
414|    "    if($_ -match '^VideoRen2='){ 'VideoRen2=10' } " ^
415|    "    elseif($_ -match '^VapourSynthScript='){ 'VapourSynthScript='+$vpy } " ^
416|    "    elseif($_ -match '^VapourSynthPath='){ 'VapourSynthPath='+$vpyDir } " ^
417|    "    elseif($_ -match '^UseVapourSynth='){ 'UseVapourSynth=1' } " ^
418|    "    else { $_ } " ^
419|    "  }; " ^
420|    "  $hasRen=$lines | Where-Object { $_ -match '^VideoRen2=' }; " ^
421|    "  if(-not $hasRen){ $lines+='VideoRen2=10' } " ^
422|    "  $hasVS=$lines | Where-Object { $_ -match '^UseVapourSynth=' }; " ^
423|    "  if(-not $hasVS){ " ^
424|    "    $lines+='UseVapourSynth=1'; " ^
425|    "    $lines+='VapourSynthScript='+$vpy; " ^
426|    "    $lines+='VapourSynthPath='+$vpyDir " ^
427|    "  } " ^
428|    "} else { " ^
429|    "  $lines=@('[Settings]','VideoRen2=10','UseVapourSynth=1','VapourSynthScript='+$vpy,'VapourSynthPath='+$vpyDir) " ^
430|    "}; " ^
431|    "$out=@(); $inserted=$false; " ^
432|    "foreach($l in $lines){ " ^
433|    "  if(-not $inserted -and $l -match '^\[[^\\]'){ " ^
434|    "    foreach($o in $overrides){ " ^
435|    "      $out+='[Override\\'+$o.idx+']'; " ^
436|    "      $out+='CLSID='+$o.clsid; " ^
437|    "      $out+='Disabled=0'; " ^
438|    "      $out+='FilterType=0'; " ^
439|    "      $out+='Merit='+$o.merit; " ^
440|    "      $out+='MeritHi=0'; " ^
441|    "      $out+='Name='+$o.name; " ^
442|    "      $out+='Path='+$o.path; " ^
443|    "      $out+=''; " ^
444|    "    }; " ^
445|    "    $inserted=$true " ^
446|    "  }; " ^
447|    "  $out+=$l " ^
448|    "}; " ^
449|    "if(-not $inserted){ " ^
450|    "  foreach($o in $overrides){ " ^
451|    "    $out+='[Override\\'+$o.idx+']'; " ^
452|    "    $out+='CLSID='+$o.clsid; " ^
453|    "    $out+='Disabled=0'; " ^
454|    "    $out+='FilterType=0'; " ^
455|    "    $out+='Merit='+$o.merit; " ^
456|    "    $out+='MeritHi=0'; " ^
457|    "    $out+='Name='+$o.name; " ^
458|    "    $out+='Path='+$o.path; " ^
459|    "    $out+=''; " ^
460|    "  } " ^
461|    "}; " ^
462|    "[System.IO.File]::WriteAllLines($ini, $out, [System.Text.Encoding]::Unicode); " ^
463|    "Write-Host 'PotPlayer 配置已写入:' $ini"
464|
465|if errorlevel 1 (
466|    echo [错误] PotPlayer config write failed。
467|) else (
468|    echo [提示] Auto-configured: LAV Video/Audio/Splitter + madVR 渲染器 + VapourSynth RIFE 补帧
469|    echo [提示] Please ensure PotPlayer's"Save settings to INI"is enabled。
470|)
471|
472|echo.
473|:: =============================================
474|:: 8. 汇总结果
475|:: =============================================
476|echo ==============================================
477|echo             Installation Results Summary
478|echo ==============================================
479|echo madVR       : %MAD_INSTALL_RESULT%
480|echo LAVFilters  : %LAV_INSTALL_RESULT%
481|echo VapourSynth : %VS_INSTALL_RESULT%
482|echo vs-rife     : %RIFE_INSTALL_RESULT%
483|echo.
484|echo Components directory: %MLVR_DIR%
485|echo.
486|
487|:: =============================================
488|:: 9. 后续说明
489|:: =============================================
490|echo =============================================
491|echo             Installation complete！
492|echo =============================================
493|echo.
494|echo [Auto-configured] LAV Video/Audio/Splitter + madVR 渲染器 + VapourSynth RIFE 补帧
495|echo.
496|echo [RIFE 补帧] Script located at: %MLVR_DIR%\vapoursynth
497|ife_2x.vpy
498|echo   - Default: RIFE v4.22 model (2x frame rate)
499|echo   - Edit .vpy file to change model version（model=22/23/25）
500|echo.
501|