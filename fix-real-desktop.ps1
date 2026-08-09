$desktopOK = "C:\tools\Sunshine\DesktopOK_x64.exe"

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
$defView = [DesktopIconSize]::FindDefView()
if ($defView -ne [IntPtr]::Zero) {
    [DesktopIconSize]::SendMessage($defView, 0x111, [IntPtr]28750, [IntPtr]::Zero) | Out-Null
}
Start-Sleep -Seconds 1

& $desktopOK /load /silent "C:\tools\Sunshine\real.dok"