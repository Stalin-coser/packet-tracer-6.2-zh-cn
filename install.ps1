# ============================================================
#  Cisco Packet Tracer 6.2 简体中文补丁 —— 一键安装
#  用法：右键本文件 -> “使用 PowerShell 运行”
#        （会自动弹出 UAC 请求管理员权限，因为要写入 Program Files）
# ============================================================
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Definition
$srcPtl = Join-Path $here 'chinese-zh_CN.ptl'
$fileName = 'chinese-zh_CN.ptl'

if (-not (Test-Path $srcPtl)) { throw "同目录下找不到 chinese-zh_CN.ptl，请确认文件和本脚本放在一起。" }

# ---------- 1. 定位 Packet Tracer 安装目录 ----------
$candidates = New-Object System.Collections.Generic.List[string]

# (a) 从桌面快捷方式反推
foreach ($lnkName in @('Cisco Packet Tracer Student.lnk', 'Cisco Packet Tracer.lnk')) {
    $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) $lnkName
    if (Test-Path $lnk) {
        try {
            $sh = New-Object -ComObject WScript.Shell
            $target = $sh.CreateShortcut($lnk).TargetPath
            if ($target) {
                $binDir = Split-Path $target -Parent          # ...\bin
                $candidates.Add((Split-Path $binDir -Parent)) # ...\<安装根>
            }
        } catch { }
    }
}

# (b) 常见默认路径
$candidates.Add('C:\Program Files (x86)\Cisco Packet Tracer 6.2sv')
$candidates.Add('C:\Program Files\Cisco Packet Tracer 6.2sv')

# (c) 兜底：按目录名模糊搜索
Get-ChildItem 'C:\Program Files (x86)', 'C:\Program Files' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like 'Cisco Packet Tracer*' } |
    ForEach-Object { $candidates.Add($_.FullName) }

$root = $null
foreach ($c in ($candidates | Select-Object -Unique)) {
    if ($c -and (Split-Path $c -Leaf) -eq 'Cisco Packet Tracer 6.2sv' -and
        (Test-Path (Join-Path $c 'languages')) -and
        (Test-Path (Join-Path $c 'bin\PacketTracer6.exe'))) { $root = $c; break }
}
if (-not $root) { throw "找不到 Cisco Packet Tracer 6.2sv 安装目录（需包含 languages 和 bin\PacketTracer6.exe）。" }

$destDir = Join-Path $root 'languages'
$destPtl = Join-Path $destDir $fileName
Write-Host "检测到安装目录: $root" -ForegroundColor Cyan

# ---------- 2. 提权（写入 Program Files 需要管理员） ----------
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "需要管理员权限，正在重新以管理员身份启动本脚本..." -ForegroundColor Yellow
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$($MyInvocation.MyCommand.Definition)`""
    )
    exit
}

# ---------- 3. 复制补丁 ----------
Copy-Item -LiteralPath $srcPtl -Destination $destPtl -Force
$installed = Get-Item $destPtl
Write-Host ""
Write-Host "✅ 已安装: $($installed.FullName)" -ForegroundColor Green
Write-Host "   大小: $($installed.Length) 字节"
Write-Host ""
Write-Host "接下来请在 Packet Tracer 里操作 (只需一次):" -ForegroundColor Cyan
Write-Host "   1) 打开 Packet Tracer"
Write-Host "   2) 菜单  Options -> Preferences，停在 Interface 标签页"
Write-Host "   3) 在 Select Language 列表里选中 chinese-zh_CN.ptl"
Write-Host "   4) 点右下角 Change Language，弹窗点 OK"
Write-Host "   5) 关闭 Preferences，完全退出 Packet Tracer 再重新打开"
Write-Host ""
Write-Host "想改回英文: 在同一列表里选 default.ptl，点 Change Language，重启即可。" -ForegroundColor DarkGray
Write-Host ""
Write-Host "按任意键退出..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
