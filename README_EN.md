# Moonlight + Sunshine Virtual Monitor Switching System

[Download](https://github.com/De-Mi-Ke/Sunshine_VDD/releases/tag/Main)


## What This System Does

When streaming remotely via Sunshine (with Moonlight as the client), the following happens automatically:

- **When you connect via the "Virtual Monitor" app**: all physical monitors turn off → a virtual monitor turns on and **automatically resizes to match the resolution of the connecting device** → the desktop switches to a virtual-mode icon layout
- **When you disconnect**: the virtual monitor turns off → all physical monitors are restored to their original state (resolution/layout) → the desktop is restored to its original icon layout/size
- **Desktop shutdown button**: to prevent accidentally shutting down the PC while still in virtual mode, this button always restores real mode first, then shuts down
- Includes **automatic detection + reinstall logic** for a known issue where the VDD (Virtual Display Driver) occasionally fails after a reboot

---

## For Whoever Shows This to Claude

Upload this zip and README to Claude (claude.ai) and ask it to "set up this system for my environment." Below is the full structure, the role of each file, and the **placeholder values that must be regenerated per user**, so Claude can walk you through it. Claude should ask you about your monitor count/layout and the devices you'll connect from (phone model, tablet, PC resolution, etc.), then fill in the corresponding parts of the scripts.

**Important**: `real.dok` and `virtual.dok` are empty, and `real3.cfg` contains only a single comment line, `#MonitorInfo`. These originally contained the previous owner's personal desktop file list and monitor serial number, which were intentionally removed before sharing. **You must regenerate these on your own PC for the system to actually work.** See Steps 5 and 7 below for the exact commands.

---

## Required Software (Downloads)

| Program | Purpose | Source |
|---|---|---|
| **Sunshine** | Remote streaming host (assumed already installed) | [github.com/LizardByte/Sunshine](https://github.com/LizardByte/Sunshine) |
| **Moonlight** | Client app (install on the connecting device) | [moonlight-stream.org](https://moonlight-stream.org) |
| **Virtual Display Driver (VDD)** | Creates the virtual monitor (by MikeTheTech) | [github.com/VirtualDrivers/Virtual-Display-Driver](https://github.com/VirtualDrivers/Virtual-Display-Driver) — installer included in this package's `VDD.Control.25.7.23` folder |
| **MultiMonitorTool** | Command-line control for turning monitors on/off and changing resolution | [nirsoft.net/utils/multi_monitor_tool.html](https://www.nirsoft.net/utils/multi_monitor_tool.html) — included in this package |
| **DesktopOK** | Saves/restores desktop icon layout (position) | [softwareok.com](https://www.softwareok.com/?seite=Freeware/DesktopOK) — included in this package (`DesktopOK_x64.exe`) |

Built and tested on Windows 11 with an NVIDIA GPU. On other GPUs/Windows versions, some steps (particularly icon-size control via `SendMessage`) may behave differently.

---

## Folder Structure

```
C:\tools\Sunshine\                     ← path can be changed freely (just update the path strings inside the scripts too)
├── MultiMonitorTool.exe
├── DesktopOK_x64.exe
├── VDD.Control.25.7.23\               ← full VDD driver installer files
│   ├── VDD Control.exe                ← run as Administrator, click Install to install the driver
│   └── Dependencies\devcon.exe        ← used by the auto-reinstall logic
├── enable-virtual.ps1                 ← runs when entering virtual mode (Sunshine "Do" command)
├── disable-virtual.ps1                ← runs when restoring real mode (Sunshine "Undo" command)
├── desktop-shutdown.ps1               ← run by the desktop shutdown button
├── fix-real-desktop.ps1               ← manual recovery (force-reapply real-mode layout/size)
├── fix-virtual-desktop.ps1            ← manual recovery (force-reapply virtual-mode layout/size)
├── real.dok                           ← [placeholder, empty] saved real-mode desktop icon layout
├── virtual.dok                        ← [placeholder, empty] saved virtual-mode desktop icon layout
└── real3.cfg                          ← [placeholder, contains only "#MonitorInfo"] saved real monitor layout

C:\VirtualDisplayDriver\vdd_settings.xml   ← auto-created after installing VDD; resolution list must be edited manually
```

---

## Setup Steps

### Step 1 — Install VDD

Run `VDD.Control.25.7.23\VDD Control.exe` **as Administrator** → click **Install**.

This automatically creates `C:\VirtualDisplayDriver\vdd_settings.xml`.

### Step 2 — Register the resolutions you want in vdd_settings.xml

The default settings may not include the exact resolution of the devices you'll connect from (phone, tablet, etc.). Open the file and add the resolutions you need under `<resolutions>`. Example (a combination of FHD / QHD / 16:10 tablet / iPhone 15 Pro Max resolution):

```xml
<?xml version='1.0' encoding='utf-8'?>
<vdd_settings>
    <monitors>
        <count>1</count>
    </monitors>
    <gpu>
        <friendlyname>default</friendlyname>
    </gpu>
    <global>
        <g_refresh_rate>60</g_refresh_rate>
        <g_refresh_rate>90</g_refresh_rate>
        <g_refresh_rate>120</g_refresh_rate>
        <g_refresh_rate>144</g_refresh_rate>
        <g_refresh_rate>165</g_refresh_rate>
        <g_refresh_rate>244</g_refresh_rate>
    </global>
    <resolutions>
        <resolution>
            <width>1920</width>
            <height>1080</height>
            <refresh_rate>60</refresh_rate>
        </resolution>
        <resolution>
            <width>2560</width>
            <height>1440</height>
            <refresh_rate>60</refresh_rate>
        </resolution>
        <resolution>
            <width>1920</width>
            <height>1200</height>
            <refresh_rate>60</refresh_rate>
        </resolution>
        <resolution>
            <width>2796</width>
            <height>1290</height>
            <refresh_rate>60</refresh_rate>
        </resolution>
    </resolutions>
    <options>
        <CustomEdid>false</CustomEdid>
        <PreventSpoof>false</PreventSpoof>
        <EdidCeaOverride>false</EdidCeaOverride>
        <HardwareCursor>true</HardwareCursor>
        <SDR10bit>false</SDR10bit>
        <HDRPlus>false</HDRPlus>
        <logging>false</logging>
        <debuglogging>false</debuglogging>
    </options>
</vdd_settings>
```

**Add/edit the `<resolution>` entries to match the devices you'll actually connect from** (e.g., your Android phone's real resolution).

After editing, click **Restart Driver** in VDD Control, or reboot.

### Step 3 — Identify your physical monitor numbers

```powershell
C:\tools\Sunshine\MultiMonitorTool.exe /stext C:\tools\Sunshine\monitors.txt
notepad C:\tools\Sunshine\monitors.txt
```

Check how many physical monitors you have and which `\\.\DISPLAY1`, `\\.\DISPLAY2`, etc. correspond to which. **If you don't have exactly 3 monitors, you must edit the number of `/enable` and `/disable` lines in `enable-virtual.ps1`/`disable-virtual.ps1` to match your actual count.**

### Step 4 — Verify the VDD instance (scripts find it automatically, but a one-time check is recommended)

```powershell
Get-PnpDevice -Class Display | Where-Object { $_.FriendlyName -eq "Virtual Display Driver" }
```

If installed correctly, it should appear here. (The scripts look this device up by name every time, so it still works even if reinstalling changes its instance ID.)

### Step 5 — Generate real3.cfg (saved real-monitor layout) — **replace the placeholder with real data**

`real3.cfg` currently just contains a `#MonitorInfo` comment. With your physical monitors displayed in your desired layout (position, resolution, primary monitor), overwrite it with the real values:

```powershell
C:\tools\Sunshine\MultiMonitorTool.exe /SaveConfig "C:\tools\Sunshine\real3.cfg"
```

This file is used by `disable-virtual.ps1` to restore your monitors' resolution, position, and primary monitor all at once when returning to real mode.

### Step 6 — Prepare the virtual-mode desktop folder (optional, required only if you want the desktop-switching feature)

```powershell
New-Item -ItemType Directory -Path "$env:USERPROFILE\Desktop_Virtual_Icons" -Force
```

Copy only the shortcuts you want visible in virtual mode into this folder. (This folder's contents become the virtual-mode desktop.)

### Step 7 — Generate real.dok / virtual.dok (saved desktop icon layout) — **replace the placeholders with real data**

Both files are currently empty placeholders. Arrange the icons and icon size the way you want in each mode, then save:

**In real mode** (with your desktop arranged and sized the way you want):
```powershell
C:\tools\Sunshine\DesktopOK_x64.exe /save /silent "C:\tools\Sunshine\real.dok"
```

**In virtual mode** (run `enable-virtual.ps1` manually once to enter virtual mode, then arrange `Desktop_Virtual_Icons` the way you want):
```powershell
C:\tools\Sunshine\DesktopOK_x64.exe /save /silent "C:\tools\Sunshine\virtual.dok"
```

> ⚠️ **Warning**: `/save` overwrites the existing file. Always double-check your current layout is correct before saving — if you save a messed-up layout, there's no way to undo it.

### Step 8 — Register the app in Sunshine

Sunshine WebUI (`https://localhost:47990`) → Applications → Add new:

- **Name**: `Virtual Monitor`
- **Command**: leave empty
- **Command Preparations**:
  - Do: `powershell.exe -ExecutionPolicy Bypass -File "C:\tools\Sunshine\enable-virtual.ps1"`
  - Undo: `powershell.exe -ExecutionPolicy Bypass -File "C:\tools\Sunshine\disable-virtual.ps1"`
  - **Make sure "Run As Administrator" is checked**

### Step 9 — Desktop shutdown button (optional)

To prevent accidentally shutting down while still in virtual mode, set up a shutdown button that runs without a UAC prompt:

```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-ExecutionPolicy Bypass -File "C:\tools\Sunshine\desktop-shutdown.ps1"'
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest
Register-ScheduledTask -TaskName "SunshineDesktopShutdown" -Action $action -Principal $principal -Force
```

Create a desktop shortcut with its target set to:
```
C:\WINDOWS\system32\schtasks.exe /run /tn "SunshineDesktopShutdown"
```

---

## File-by-File Details

- **enable-virtual.ps1**: Enables VDD (auto-reinstalls on failure) → sets the virtual monitor to the connecting device's resolution → turns off physical monitors → switches the desktop to the virtual-mode folder → hides the Recycle Bin → sets icon size to large → restores layout from `virtual.dok`
- **disable-virtual.ps1**: Restores physical monitor layout in one shot via `real3.cfg` → turns off the virtual monitor → restores the desktop to the real path → shows the Recycle Bin again → sets icon size to medium → restores layout from `real.dok`
- **desktop-shutdown.ps1**: Runs `disable-virtual.ps1`, then shuts down via `shutdown.exe`
- **fix-real-desktop.ps1 / fix-virtual-desktop.ps1**: Manual helper scripts to re-apply layout/size if automatic switching gets thrown off by timing issues (handy to register as desktop shortcuts)

Desktop icon size switching works by sending a `WM_COMMAND` message directly to the desktop window (`SHELLDLL_DefView`) via `SendMessage` (Large icons = 28751, Medium icons = 28750 — values verified with Spy++). A keyboard-shortcut approach (Ctrl+Shift+2/3) was tried first but abandoned because it could get intercepted by whatever window happened to have focus at the time; this direct-message approach was used instead.

---

## Known Issues

- **VDD occasionally fails with a "device is not connected" error after a reboot.** `enable-virtual.ps1` includes logic to automatically detect this and reinstall the driver, which resolves it in most cases, but this isn't guaranteed 100% of the time. If it keeps happening, a manual reinstall via `VDD Control.exe` may be needed.
- Desktop icon layout is saved/restored by filename. If you add new files to the desktop, you'll need to rearrange things and re-run `/save` for the new layout (including the new files) to be preserved going forward.
