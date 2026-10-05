# Apple T2 Touch Bar (`t2-touchbar`) on Gentoo Linux

This directory provides Gentoo Portage packaging files (`ebuild`, udev rules, XDG autostart, and OpenRC/systemd service units) to install and configure **kait2en-touchbar** (`t2-touchbar`) for Apple Silicon T2 MacBooks (MacBookPro15,1; MacBookPro15,2; MacBookPro15,3; MacBookPro15,4; MacBookPro16,1; MacBookPro16,2; MacBookPro16,3; MacBookPro16,4).

---

## 1. How `t2-touchbar` Works

On Apple T2 MacBooks, the Touch Bar is composed of:
1. **OLED Display**: Managed via DRM (Direct Rendering Manager) dumb buffers through the `appletbdrm` kernel driver (`/dev/dri/card*`).
2. **Touch Digitizer & Fn Keys**: Multi-touch capacitive sensor exposed via `appletb_kbd` / `appletb_bl` as input event devices (`/dev/input/event*`).
3. **Haptic Actuator & Backlight**: Taptic engine pulses and display brightness controllable via `/sys/class/leds/*` and `/sys/class/backlight/*`.
4. **Virtual Input Device**: Virtual keyboard injected via `/dev/uinput` to emit standard media keys, volume, display/keyboard brightness, and function key events (`KEY_F1`-`KEY_F12`).

`kait2en-touchbar` is a lightweight userspace daemon written in Rust that:
- Directly renders modern interactive UI layouts using `tiny-skia` into DRM dumb buffers.
- Listens to touch events using `libevdev` and emits corresponding keys or haptic feedback.
- Listens for biometric prompt signals on D-Bus (`org.kait2en.TouchId`) to display Touch ID animations during fingerprint authentication.
- Automatically handles idle dimming, screen sleep, and wake upon touch.

---

## 2. Directory Structure

```
gentoo/
├── README.md
└── app-laptop/
    └── t2-touchbar/
        ├── metadata.xml
        ├── t2-touchbar-0.1.0.ebuild   # Snapshot release with locked Cargo crates
        ├── t2-touchbar-9999.ebuild    # Live git ebuild (git-r3)
        └── files/
            ├── 99-t2-touchbar.rules           # Udev rules assigning standard video/input groups
            ├── kait2en-touchbar.desktop       # XDG autostart entry for desktop environments
            ├── kait2en-touchbar-attach.initd  # OpenRC init script for system daemon
            └── kait2en-touchbar-attach.confd  # OpenRC configuration file
```

---

## 3. Requirements & System Preparation

### 3.1 Kernel Configuration
The ebuild automatically validates your running or installed kernel configuration using Gentoo's `linux-info.eclass`. Ensure the following kernel options are enabled:

| Kernel Symbol | Required | Description |
|---|---|---|
| `CONFIG_DRM_APPLETBDRM` | `=m` or `=y` | Apple T2 Touch Bar DRM display driver |
| `CONFIG_HID_APPLETB_BL` | `=m` or `=y` | Touch Bar backlight driver |
| `CONFIG_HID_APPLETB_KBD` | `=m` or `=y` | Touch Bar touch digitizer & input driver |
| `CONFIG_INPUT_UINPUT` | `=m` or `=y` | Userspace input injection driver (`/dev/uinput`) |
| `CONFIG_BACKLIGHT_CLASS_DEVICE` | `=y` or `=m` | Linux backlight subsystem |

### 3.2 Standard User Groups (No Custom Groups)
In accordance with Gentoo security standards, `t2-touchbar` **does not** create custom ad-hoc groups. Instead, udev rules (`99-t2-touchbar.rules`) grant access to Gentoo's standard system groups:
- **`video`** group: Grants read/write access to the DRM display (`/dev/dri/card*`) and backlight controls.
- **`input`** group: Grants read/write access to touch digitizers (`/dev/input/event*`) and the virtual input node (`/dev/uinput`).

Verify that your desktop user belongs to both `video` and `input`:
```bash
id $USER
```
If either group is missing, add your user:
```bash
sudo usermod -aG video,input $USER
```
> [!IMPORTANT]
> If you modified group memberships, log out and log back in (or restart your session) for the changes to take effect.

### 3.3 Font Dependencies
`kait2en-touchbar` renders system labels and icons using TrueType/OpenType fonts. The ebuild depends on `media-fonts/adwaita-fonts` (or `media-fonts/inter`, `media-fonts/cantarell`) and automatically patches font search paths to standard Gentoo locations:
- `/usr/share/fonts/Adwaita/AdwaitaSans-Regular.ttf`
- `/usr/share/fonts/inter/InterVariable.ttf`
- `/usr/share/fonts/cantarell/Cantarell-VF.otf`

---

## 4. Installation via Overlay

### 4.1 Copy to Local Overlay
Copy the package files into your Gentoo overlay (e.g. `t2-overlay`):
```bash
mkdir -p /path/to/overlay/app-laptop/t2-touchbar
cp -r app-laptop/t2-touchbar/* /path/to/overlay/app-laptop/t2-touchbar/
```

### 4.2 Generate Manifest
Generate digests for the snapshot release:
```bash
cd /path/to/overlay/app-laptop/t2-touchbar
ebuild t2-touchbar-0.1.0.ebuild manifest
```
*(Alternatively, use `pkgdev manifest` if working within a configured repository).*

### 4.3 Emerge Package
Install `t2-touchbar`:
```bash
sudo emerge -av app-laptop/t2-touchbar
```

---

## 5. Running and Autostart

`kait2en-touchbar` supports both user-session autostart and system services:

### 5.1 Desktop Session (XDG Autostart)
By default, the package installs `/etc/xdg/autostart/kait2en-touchbar.desktop`.
When logging into any standard graphical desktop (GNOME, KDE Plasma, Sway, Hyprland, etc.), `kait2en-touchbar` starts automatically in the user's session.

### 5.2 Systemd
* **User Session Service** (recommended for graphical sessions):
  ```bash
  systemctl --user enable --now kait2en-touchbar.service
  ```
* **System Attach Service** (if running as a system service):
  ```bash
  sudo systemctl enable --now kait2en-touchbar-attach.service
  ```

### 5.3 OpenRC
For OpenRC systems, a dedicated init script is installed:
```bash
# Add to default runlevel and start immediately
sudo rc-update add kait2en-touchbar-attach default
sudo rc-service kait2en-touchbar-attach start
```

---

## 6. Verification and Troubleshooting

1. **Check Touch Bar Detection**:
   ```bash
   kait2en-touchbar --status
   ```
2. **Run Interactively**:
   ```bash
   kait2en-touchbar --verbose
   ```
3. **Verify Permissions**:
   If permission denied errors occur on `/dev/uinput` or `/dev/dri/card*`:
   - Verify `groups` includes `video` and `input`.
   - Reload udev rules:
     ```bash
     sudo udevadm control --reload-rules && sudo udevadm trigger
     ```
