@echo off
REM ============================================================
REM  一键停止脚本 pause.bat
REM  按端口结束前后端进程
REM ============================================================
echo 正在停止项目 端口 8081 / 5173 ...
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":8081 " ^| findstr "LISTENING"') do taskkill /F /PID %%p >nul 2>&1
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":5173 " ^| findstr "LISTENING"') do taskkill /F /PID %%p >nul 2>&1
echo 已发送停止信号，如窗口仍开着请手动关闭。
pause
