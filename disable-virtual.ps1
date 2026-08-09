$mmt = "C:\tools\Sunshine\MultiMonitorTool.exe"
$desktopOK = "C:\tools\Sunshine\DesktopOK_x64.exe"

# 1. 실제 모니터 3개 설정(해상도+위치+Primary)을 저장해둔 구성으로 한 번에 복원
& $mmt /LoadConfig "C:\tools\Sunshine\real3.cfg"
Start-Sleep -Seconds 3

# 2. 가상 모니터 끄기
$vdd = Get-PnpDevice -Class Display -ErrorAction SilentlyContinue | Where-Object {
    $_.FriendlyName -eq "Virtual Display Driver" -and $_.InstanceId -like "ROOT\DISPLAY\*"
} | Select-Object -First 1
if ($vdd) { pnputil /disable-device /instanceid $vdd.InstanceId }
Start-Sleep -Seconds 1

# 3. 바탕화면을 실제 경로로 복구
$defaultDesktop = "$env:USERPROFILE\Desktop"

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class KnownFolders {
    [DllImport("shell32.dll")]
    public static extern int SHSetKnownFolderPath(ref Guid rfid, uint dwFlags, IntPtr hToken, [MarshalAs(UnmanagedType.LPWStr)] string pszPath);
}
"@
$FOLDERID_Desktop = [Guid]"B4BFCC3A-DB2C-424C-B029-7FE99A87C641"
[KnownFolders]::SHSetKnownFolderPath([ref]$FOLDERID_Desktop, 0, [IntPtr]::Zero, $defaultDesktop)

# 4. 휴지통 아이콘 항상 보이게 보장
$hideIconsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
New-Item -Path $hideIconsPath -Force | Out-Null
Set-ItemProperty -Path $hideIconsPath -Name "{645FF040-5081-101B-9F08-00AA002F954E}" -Value 0 -Type DWord

Stop-Process -Name explorer -Force
Start-Sleep -Seconds 3
Start-Process explorer.exe
Start-Sleep -Seconds 3

# 5. explorer.exe 재시작 시 자동으로 뜨는 탐색기 창 닫기
try {
    $shellApp = New-Object -ComObject Shell.Application
    foreach ($window in @($shellApp.Windows())) {
        try { $window.Quit() } catch {}
    }
} catch {}
Start-Sleep -Seconds 1

# 6. 아이콘 크기를 먼저 "보통 아이콘"으로 설정 (배치 불러오기 전에!)
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
    [DesktopIconSize]::SendMessage($defView, 0x111, [IntPtr]28750, [IntPtr]::Zero) | Out-Null
}
Start-Sleep -Seconds 1

# 7. 그다음 아이콘 배치 불러오기
& $desktopOK /load /silent "C:\tools\Sunshine\real.dok"
Start-Sleep -Milliseconds 500