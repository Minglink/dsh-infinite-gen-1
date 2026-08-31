@echo off
chcp 65001 >nul
title 安装无限三代插件
echo.
echo ======================================================
echo    DeepSeek 破甲插件「无限三代」安装向导
echo ======================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
echo.
echo 按任意键退出...
pause >nul