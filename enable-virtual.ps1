$mmt = "C:\tools\Sunshine\MultiMonitorTool.exe"
$desktopOK = "C:\tools\Sunshine\DesktopOK_x64.exe"
$devcon = "C:\tools\Sunshine\VDD.Control.25.7.23\Dependencies\devcon.exe"
$infPath = "C:\tools\Sunshine\VDD.Control.25.7.23\SignedDrivers\x86\VDD\MttVDD.inf"

$width  = $env:SUNSHINE_CLIENT_WIDTH
$height = $env:SUNSHINE_CLIENT_HEIGHT
$fps    = $env:SUNSHINE_CLIENT_FPS
if (-not $width)  { $width  = 1920 }
if (-not $height) { $height = 1080 }
if (-not $fps)    { $fps    = 60 }

# 1. VDD 인스턴스 동적 탐색
$vdd = Get-PnpDevice -Class Display -ErrorAction SilentlyContinue | Where-Object {
    $_.FriendlyName -eq "Virtual Display Driver" -and $_.InstanceId -like "ROOT\DISPLAY\*"
} | Select-Object -First 1

$needReinstall = $false
if (-not $vdd) {
    $needReinstall = $true
} else {
    pnputil /enable-device /instanceid $vdd.InstanceId | Out-Null
    Start-Sleep -Seconds 1
    $checkDevice = Get-PnpDevice -InstanceId $vdd.InstanceId -ErrorAction SilentlyContinue
    if (-not $checkDevice -or $checkDevice.Status -ne "OK") {
        $needReinstall = $true
    }
}

# 2. 실패 감지 시 자동 재설치
if ($needReinstall) {
    if ($vdd) {
        pnputil /remove-device /instanceid $vdd.InstanceId | Out-Null
    }

    $driverEntry = pnputil /enum-drivers | Select-String -Pattern "mttvdd\.inf" -Context 5,0
    if ($driverEntry) {
        $block = $driverEntry.Context.PreContext + $driverEntry.Line
        $publishedLine = $block | Where-Object { $_ -match "oem\d+\.inf" } | Select-Object -Last 1
        if ($publishedLine -match "(oem\d+\.inf)") {
            $oemName = $matches[1]
            pnputil /delete-driver $oemName /uninstall /force | Out-Null
        }
    }

    Start-Sleep -Seconds 2
    & $devcon install $infPath "Root\MttVDD" | Out-Null
    Start-Sleep -Seconds 3

    $vdd = Get-PnpDevice -Class Display -ErrorAction SilentlyContinue | Where-Object {
        $_.FriendlyName -eq "Virtual Display Driver" -and $_.InstanceId -like "ROOT\DISPLAY\*"
    } | Select-Object -First 1

    if (-not $vdd) { exit 1 }
    pnputil /enable-device /instanceid $vdd.InstanceId | Out-Null
}

# 3. 가상 모니터가 실제로 잡힐 때까지 최대 30초 재시도
$vname = $null
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 1
    & $mmt /scomma "$env:TEMP\mon.csv"
    Start-Sleep -Milliseconds 300
    $csv = Import-Csv "$env:TEMP\mon.csv"
    $virtual = $csv | Where-Object { $_.Adapter -eq "Virtual Display Driver" } | Select-Object -First 1
    if ($virtual) { $vname = $virtual.Name; break }
}
if (-not $vname) { exit 1 }

# 4. 해상도 설정과 Primary 지정을 반드시 분리
& $mmt /SetMonitors "Name=$vname Width=$width Height=$height BitsPerPixel=32 DisplayFrequency=$fps"
Start-Sleep -Seconds 1
& $mmt /SetPrimary $vname
Start-Sleep -Seconds 1

# 5. 실제 모니터 3개 끄기
& $mmt /disable "\\.\DISPLAY1"
& $mmt /disable "\\.\DISPLAY2"
& $mmt /disable "\\.\DISPLAY3"
Start-Sleep -Seconds 2

# 6. 바탕화면을 가상 모드용 폴더로 전환
$virtualDesktop = "$env:USERPROFILE\Desktop_Virtual_Icons"
New-Item -ItemType Directory -Path $virtualDesktop -Force | Out-Null

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class KnownFolders {
    [DllImport("shell32.dll")]
    public static extern int SHSetKnownFolderPath(ref Guid rfid, uint dwFlags, IntPtr hToken, [MarshalAs(UnmanagedType.LPWStr)] string pszPath);
}
"@
$FOLDERID_Desktop = [Guid]"B4BFCC3A-DB2C-424C-B029-7FE99A87C641"
[KnownFolders]::SHSetKnownFolderPath([ref]$FOLDERID_Desktop, 0, [IntPtr]::Zero, $virtualDesktop)

# 7. 휴지통 아이콘 숨기기
$hideIconsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
New-Item -Path $hideIconsPath -Force | Out-Null
Set-ItemProperty -Path $hideIconsPath -Name "{645FF040-5081-101B-9F08-00AA002F954E}" -Value 1 -Type DWord

Stop-Process -Name explorer -Force
Start-Sleep -Seconds 3
Start-Process explorer.exe
Start-Sleep -Seconds 3

# 8. explorer.exe 재시작 시 자동으로 뜨는 탐색기 창 닫기
try {
    $shellApp = New-Object -ComObject Shell.Application
    foreach ($window in @($shellApp.Windows())) {
        try { $window.Quit() } catch {}
    }
} catch {}
Start-Sleep -Seconds 1

# 9. 아이콘 크기를 먼저 "큰 아이콘"으로 설정 (배치 불러오기 전에!)
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class DesktopIconSize {
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);
    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    public static IntPtr FindDefView() {
        IntPtr progman = FindWindow("Progman", null);
        IntPtr defView = FindWindowEx(progman, IntPtr.Zero, "SHELLDLL_DefView", null);
        if (defView != IntPtr.Zero) return defView;
        IntPtr result = IntPtr.Zero;
        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
            IntPtr dv = FindWindowEx(hWnd, IntPtr.Zero, "SHELLDLL_DefView", null);
            if (dv != IntPtr.Zero) { result = dv; return false; }
            return true;
        }, IntPtr.Zero);
        return result;
    }
}
"@
$defView = [IntPtr]::Zero
for ($i = 0; $i -lt 10; $i++) {
    $defView = [DesktopIconSize]::FindDefView()
    if ($defView -ne [IntPtr]::Zero) { break }
    Start-Sleep -Milliseconds 500
}
if ($defView -ne [IntPtr]::Zero) {
    [DesktopIconSize]::SendMessage($defView, 0x111, [IntPtr]28751, [IntPtr]::Zero) | Out-Null
}
Start-Sleep -Seconds 1

# 10. 그다음 아이콘 배치 불러오기
& $desktopOK /load /silent "C:\tools\Sunshine\virtual.dok"
Start-Sleep -Milliseconds 500