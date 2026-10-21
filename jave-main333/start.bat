@echo off
REM ============================================================
REM  一键启动脚本 start.bat
REM  同时拉起前端(Vue/Vite) 与 后端(Spring Boot)，并自动打开网页
REM  本机每次重启 node_modules / target 会被清空，脚本自动重建
REM  前端端口 5173，后端端口 8081
REM  后端需 MySQL: 127.0.0.1:3306 / login_db / root / 123456
REM ============================================================
setlocal
set "ROOT=%~dp0"
set "FE=%ROOT%login-vue"
set "BE=%ROOT%springBootTest"
set "URL=http://127.0.0.1:5173"

echo [1/5] 检查环境 node / java ...
where node >nul 2>&1 || (echo 缺少 node，请先安装 Node.js & pause & exit /b 1)
where java >nul 2>&1 || (echo 缺少 java，请先安装 JDK 17+ & pause & exit /b 1)

echo [2/5] 尝试启动 MySQL 服务(若已安装) ...
net start MySQL   >nul 2>&1
net start MySQL80 >nul 2>&1
net start MySQL57 >nul 2>&1

REM ---- 确保 login_db 与 user 表存在（环境重置后库会被清空，这里自动重建；幂等，不破坏已有账号）----
set "MYSQL_BIN=C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
if not exist "%MYSQL_BIN%" set "MYSQL_BIN=mysql.exe"
"%MYSQL_BIN%" -uroot -p123456 < "%ROOT%sql\ensure_db.sql" >nul 2>&1

echo [3/5] 前端：安装依赖并启动 Vite(5173) ...
start "login-vue" cmd /k "pushd "%FE%" && npm ci --prefer-offline --no-audit --no-fund --progress=false && npm run dev"

echo [4/5] 后端：启动 Spring Boot(8081) ...
start "springBoot" cmd /k "pushd "%BE%" && call mvnw.cmd -o -T 1C spring-boot:run -DskipTests || call mvnw.cmd -T 1C spring-boot:run -DskipTests"

echo [5/5] 等待前端就绪后自动打开网页 ...
set /a tries=0
:wait5173
netstat -ano | findstr ":5173 " | findstr "LISTENING" >nul 2>&1
if not errorlevel 1 goto openbrowser
set /a tries+=1
if %tries% geq 90 (
  echo 等待前端超时，请手动打开 %URL%
  goto end
)
timeout /t 2 >nul 2>&1
goto wait5173
:openbrowser
start "" "%URL%"
echo 已自动打开网页：%URL%
:end
echo 启动完成。前端窗口与后端窗口已打开；关闭窗口或运行 pause.bat 即可停止。
pause
