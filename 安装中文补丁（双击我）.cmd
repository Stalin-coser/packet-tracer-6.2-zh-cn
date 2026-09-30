@echo off
chcp 65001 >nul
title Cisco Packet Tracer 6.2 简体中文补丁 - 安装
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
if errorlevel 1 (
  echo.
  echo [出错] 安装未完成，请查看上面的红色提示。
  pause
)
