# Moonlight + Sunshine 가상 모니터 전환 시스템

## 이 시스템이 하는 일

Sunshine으로 원격 스트리밍(Moonlight)할 때, 다음이 전부 자동으로 처리됩니다.

- **가상 모니터 앱으로 접속하면**: 실제 모니터 전부 꺼짐 → 가상 모니터가 켜지고, **접속한 기기의 해상도에 맞춰 자동으로 크기 조정** → 바탕화면이 가상 모드 전용 아이콘 배치로 전환
- **접속을 종료하면**: 가상 모니터 꺼짐 → 실제 모니터 전부 원래 상태(해상도·배치)로 복구 → 바탕화면도 원래 아이콘 배치·크기로 복구
- **바탕화면 종료 버튼**: 가상 모드로 켜져 있는 상태에서 실수로 컴퓨터를 끄는 걸 방지하기 위해, 이 버튼을 누르면 항상 먼저 실제 모드로 복구한 뒤 종료됩니다.
- VDD(가상 디스플레이 드라이버)가 재부팅 후 가끔 오류를 내는 문제에 대한 **자동 감지 + 재설치 로직**도 포함되어 있습니다.

---

## 🤖 이 파일을 Claude에게 보여주시는 분께

이 zip 파일과 README를 Claude(claude.ai)에게 업로드하고 "내 환경에 맞게 이 시스템 설정해줘"라고 요청하시면 됩니다. Claude가 참고할 수 있도록 아래에 전체 구조와 각 파일의 역할, 그리고 **반드시 사용자별로 다시 만들어야 하는 값들(placeholder)**을 정리해뒀습니다. Claude는 아래 순서를 따라가면서, 사용자에게 본인 모니터 개수/배치, 접속할 기기 종류(폰 기종, 태블릿, PC 해상도) 등을 확인 질문으로 물어보고, 그 값에 맞게 스크립트의 해당 부분을 채워주면 됩니다.

**중요**: `real.dok`, `virtual.dok`는 내용이 비어있고, `real3.cfg`는 `#모니터정보`라는 주석 한 줄만 있는 빈 placeholder 파일입니다. 이건 원래 소유자의 개인 바탕화면 파일 목록과 모니터 시리얼 번호가 담겨있어서 공유 전에 일부러 지운 것이며, **실제 기능을 쓰려면 사용자 본인 PC에서 반드시 새로 생성해야 합니다.** 아래 "5단계"와 "7단계"에 정확한 생성 명령이 있습니다.

---

## 필요한 프로그램 (다운로드)

| 프로그램 | 용도 | 출처 |
|---|---|---|
| **Sunshine** | 원격 스트리밍 호스트 (이미 설치되어 있다는 전제) | [github.com/LizardByte/Sunshine](https://github.com/LizardByte/Sunshine) |
| **Moonlight** | 클라이언트 앱 (접속하는 쪽 기기에 설치) | [moonlight-stream.org](https://moonlight-stream.org) |
| **Virtual Display Driver (VDD)** | 가상 모니터를 만들어주는 드라이버 (MikeTheTech 제작) | [github.com/VirtualDrivers/Virtual-Display-Driver](https://github.com/VirtualDrivers/Virtual-Display-Driver) — 이 패키지의 `VDD.Control.25.7.23` 폴더에 설치 파일 포함됨 |
| **MultiMonitorTool** | 모니터 켜기/끄기, 해상도 변경을 명령줄로 제어 | [nirsoft.net/utils/multi_monitor_tool.html](https://www.nirsoft.net/utils/multi_monitor_tool.html) — 이 패키지에 포함됨 |
| **DesktopOK** | 바탕화면 아이콘 배치(위치)를 저장/복원 | [softwareok.com](https://www.softwareok.com/?seite=Freeware/DesktopOK) — 이 패키지에 포함됨 (`DesktopOK_x64.exe`) |

Windows 11 + NVIDIA GPU 환경에서 만들어졌습니다. 다른 GPU/Windows 버전에서는 일부 단계(특히 아이콘 크기 제어, `SendMessage` 관련 부분)가 다르게 동작할 수 있습니다.

---

## 폴더 구조

```
C:\tools\Sunshine\                     ← 경로는 원하는 대로 바꿔도 됨 (스크립트 안 경로 문자열도 같이 바꿔야 함)
├── MultiMonitorTool.exe
├── DesktopOK_x64.exe
├── VDD.Control.25.7.23\               ← VDD 드라이버 설치 파일 일체
│   ├── VDD Control.exe                ← 관리자 권한으로 실행해서 Install 누르면 드라이버 설치됨
│   └── Dependencies\devcon.exe        ← 자동 재설치 로직에서 사용
├── enable-virtual.ps1                 ← 가상 모니터 진입 시 실행 (Sunshine "Do" 명령)
├── disable-virtual.ps1                ← 실제 모니터 복귀 시 실행 (Sunshine "Undo" 명령)
├── desktop-shutdown.ps1               ← 바탕화면 종료 버튼이 실행하는 스크립트
├── fix-real-desktop.ps1               ← 수동 복구용 (실제 모드 배치/크기 강제 재적용)
├── fix-virtual-desktop.ps1            ← 수동 복구용 (가상 모드 배치/크기 강제 재적용)
├── real.dok                           ← [placeholder, 비어있음] 실제 모드 바탕화면 배치 저장 파일
├── virtual.dok                        ← [placeholder, 비어있음] 가상 모드 바탕화면 배치 저장 파일
└── real3.cfg                          ← [placeholder, "#모니터정보"만 있음] 실제 모니터 배치 저장 파일

C:\VirtualDisplayDriver\vdd_settings.xml   ← VDD 설치 후 자동 생성됨, 해상도 목록 직접 편집 필요
```

---

## 설정 순서

### 1단계 — VDD 설치

`VDD.Control.25.7.23\VDD Control.exe`를 **관리자 권한으로 실행** → **Install** 클릭.

설치되면 `C:\VirtualDisplayDriver\vdd_settings.xml`이 자동 생성됩니다.

### 2단계 — vdd_settings.xml에 원하는 해상도 등록

기본값에는 접속할 기기(휴대폰, 태블릿 등)에 딱 맞는 해상도가 없을 수 있습니다. 파일을 열어서 `<resolutions>` 섹션에 원하는 해상도를 추가하세요. 예시(FHD/QHD/16:10 태블릿/아이폰 15 프로맥스 해상도 조합):

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

**본인 접속 기기에 맞는 해상도로 `<resolution>` 항목을 추가/수정하세요.** (예: 안드로이드 폰이면 그 기종의 실제 해상도로)

수정 후 VDD Control 앱에서 **Restart Driver** 하거나 재부팅.

### 3단계 — 물리 모니터 번호 확인

```powershell
C:\tools\Sunshine\MultiMonitorTool.exe /stext C:\tools\Sunshine\monitors.txt
notepad C:\tools\Sunshine\monitors.txt
```

`\\.\DISPLAY1`, `\\.\DISPLAY2` 같은 번호가 실제 모니터 몇 대인지, 어떤 모니터인지 확인하세요. **모니터가 3대가 아니면 `enable-virtual.ps1`/`disable-virtual.ps1` 안의 `/enable`, `/disable` 줄 개수를 실제 대수에 맞게 수정해야 합니다.**

### 4단계 — VDD 인스턴스 확인 (스크립트가 자동으로 찾긴 하지만 최초 1회 확인 권장)

```powershell
Get-PnpDevice -Class Display | Where-Object { $_.FriendlyName -eq "Virtual Display Driver" }
```

정상 설치됐으면 여기 뜹니다. (스크립트는 이 장치를 매번 이름으로 자동 검색하므로, 재설치돼서 ID가 바뀌어도 문제없습니다.)

### 5단계 — real3.cfg 생성 (실제 모니터 배치 저장) — **placeholder를 실제 값으로 교체**

지금 `real3.cfg`는 `#모니터정보`라는 주석만 있는 빈 파일입니다. 실제 모니터들이 원하는 배치(위치, 해상도, 주 모니터)로 정상 표시된 상태에서 아래 명령으로 덮어써서 실제 값을 채우세요:

```powershell
C:\tools\Sunshine\MultiMonitorTool.exe /SaveConfig "C:\tools\Sunshine\real3.cfg"
```

이 파일은 `disable-virtual.ps1`이 실제 모드로 복귀할 때 모니터 해상도·위치·주 모니터를 한 번에 정확히 복원하는 데 쓰입니다.

### 6단계 — 가상 모드용 바탕화면 폴더 준비 (선택사항, 바탕화면 전환 기능을 쓰려면 필수)

```powershell
New-Item -ItemType Directory -Path "$env:USERPROFILE\Desktop_Virtual_Icons" -Force
```

가상 모드일 때 보여주고 싶은 바로가기만 이 폴더에 복사해두세요. (이 폴더 내용이 가상 모드 바탕화면이 됩니다.)

### 7단계 — real.dok / virtual.dok 생성 (바탕화면 아이콘 배치 저장) — **placeholder를 실제 값으로 교체**

지금 두 파일은 비어있는 placeholder입니다. 각 모드에서 원하는 아이콘 배치·크기로 정리한 뒤 아래 명령으로 저장하세요.

**실제 모드에서** (바탕화면이 원하는 배치·아이콘 크기인 상태에서):
```powershell
C:\tools\Sunshine\DesktopOK_x64.exe /save /silent "C:\tools\Sunshine\real.dok"
```

**가상 모드에서** (`enable-virtual.ps1`을 한 번 수동 실행해서 가상 모드로 들어간 뒤, `Desktop_Virtual_Icons` 폴더 내용이 원하는 배치·아이콘 크기인 상태에서):
```powershell
C:\tools\Sunshine\DesktopOK_x64.exe /save /silent "C:\tools\Sunshine\virtual.dok"
```

> ⚠️ **주의**: `/save`는 기존 파일을 덮어씁니다. 저장하기 전에 반드시 지금 화면 배치가 원하시는 상태인지 확인하세요 — 흐트러진 상태로 저장하면 되돌릴 방법이 없습니다.

### 8단계 — Sunshine에 앱 등록

Sunshine WebUI(`https://localhost:47990`) → Applications → 신규 추가:

- **이름**: `Virtual Monitor`
- **명령**: 비워둠
- **명령 준비**:
  - 실행(Do): `powershell.exe -ExecutionPolicy Bypass -File "C:\tools\Sunshine\enable-virtual.ps1"`
  - 취소(Undo): `powershell.exe -ExecutionPolicy Bypass -File "C:\tools\Sunshine\disable-virtual.ps1"`
  - **관리자 권한으로 실행 반드시 체크**

### 9단계 — 바탕화면 종료 버튼 (선택사항)

가상 모드인 채로 실수로 종료하는 걸 막고 싶으면, UAC 팝업 없이 실행되는 종료 버튼을 만듭니다.

```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-ExecutionPolicy Bypass -File "C:\tools\Sunshine\desktop-shutdown.ps1"'
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest
Register-ScheduledTask -TaskName "SunshineDesktopShutdown" -Action $action -Principal $principal -Force
```

바탕화면에 바로가기를 만들고 대상을 아래로 지정:
```
C:\WINDOWS\system32\schtasks.exe /run /tn "SunshineDesktopShutdown"
```

---

## 파일별 상세 설명

- **enable-virtual.ps1**: VDD 활성화(실패 시 자동 재설치) → 접속 기기 해상도로 가상 모니터 설정 → 실제 모니터 끄기 → 바탕화면을 가상 모드 폴더로 전환 → 휴지통 숨김 → 아이콘 크기를 큰 아이콘으로 → `virtual.dok`으로 배치 복원
- **disable-virtual.ps1**: `real3.cfg`로 실제 모니터 배치 한 번에 복원 → 가상 모니터 끄기 → 바탕화면을 실제 경로로 복원 → 휴지통 다시 보이기 → 아이콘 크기를 보통 아이콘으로 → `real.dok`으로 배치 복원
- **desktop-shutdown.ps1**: `disable-virtual.ps1` 실행 후 `shutdown.exe`로 종료
- **fix-real-desktop.ps1 / fix-virtual-desktop.ps1**: 자동 전환이 타이밍 문제로 꼬였을 때, 수동으로 배치·크기만 다시 맞추는 보조 스크립트 (바탕화면 바로가기로 등록해두면 편함)

바탕화면 아이콘 크기 전환은 `SendMessage`로 바탕화면 창(`SHELLDLL_DefView`)에 `WM_COMMAND`를 직접 보내는 방식입니다 (큰 아이콘=28751, 보통 아이콘=28750 — Spy++로 검증된 값). 키보드 단축키(Ctrl+Shift+2/3) 방식은 다른 프로그램이 포커스를 채가면 엉뚱한 곳에 적용되는 문제가 있어 이 방식으로 대체했습니다.

---

## 알려진 이슈

- **VDD가 재부팅 후 간헐적으로 "장치가 연결되지 않았습니다" 오류를 냅니다.** `enable-virtual.ps1`에 이 상황을 자동 감지해서 드라이버를 제거→재설치하는 로직이 포함되어 있어 대부분 자동 복구되지만, 100% 보장되지는 않습니다. 반복되면 `VDD Control.exe`로 수동 재설치가 필요할 수 있습니다.
- 바탕화면 아이콘 배치는 파일명 기준으로 저장/복원됩니다. 새 파일을 바탕화면에 추가한 뒤에도 예전 배치를 유지하려면, 배치를 정리하고 `/save`로 다시 저장해야 그 이후부터 반영됩니다.
