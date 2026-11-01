# EBO SE Bridge — Home Assistant add-on

Local, cloud-free bridge for the **Enabot EBO SE** robot, packaged as a Home Assistant
add-on for an **x86_64 HAOS host**.

* video: H.265 passthrough → MediaMTX RTSP (`rtsp://…:8554/ebo`) → HA Generic Camera
* control/telemetry: MQTT Discovery (buttons, switches, sensors)
* the small ARM64 Android bridge process runs through `qemu-aarch64` user-mode;
  Python, ffmpeg and MediaMTX stay native x86_64

## Why this exists

The EBO SE is a **TUTK/Kalay** (ThroughTek) device. It has no RTSP, no ONVIF and no open
TCP ports — the ROLA app talks to it over a proprietary UDP P2P protocol. The only
community implementation is
[lilium360/ebo-se-lan-bridge](https://github.com/lilium360/ebo-se-lan-bridge) (MIT), with
ARM64/QEMU and control work in the [guru1987](https://github.com/guru1987/ebo-se-lan-bridge)
fork. This repository only repackages that code as an add-on; all credit goes upstream.

**No proprietary component is redistributed here.** The TUTK `.so` libraries, the Android
bionic runtime and the robot credentials are *not* in this repository: you extract them
from your own ROLA APK / your own device and drop them into `/config/ebo-se/runtime`.

## Required runtime files (not in git)

```
/config/ebo-se/runtime/
├── bionic/            # linker (linker64), libc.so libm.so libdl.so libc++.so liblog.so
│                      # libstdc++.so libnetd_client.so  ← from the Android /apex + /system/lib64
├── lib/               # libTUTKGlobalAPIs.so libIOTCAPIs.so libRDTAPIs.so libAVAPIs.so
│                      # ← lib/arm64-v8a/ inside your own ROLA APK
└── ebo_bridge-arm64   # built from ebo_bridge.c with the Android NDK (aarch64-linux-android24)
```

Credentials come from the add-on options (see `config.yaml`), never from files.

## Local differences from upstream

| Change | Why |
|---|---|
| `IOTC_Connect_ByUIDEx` input struct is **160 bytes** with the auth-type field at `+0x98` | TUTK **4.3.9.x arm64** rejects the upstream 152-byte layout with `-46 IOTC_ER_INVALID_ARG` (disassembled check: `cmp w8,#0xa0`) |
| optional `EBO_REGION` → `TUTK_SDK_Set_Region(n)` | Kalay 2.0 partitions by region; the ROLA client runs in the CN partition |
| arch-aware `qemu-aarch64` | same image works on x86_64 HAOS and on native aarch64 |

## Install

1. Settings → Add-ons → Add-on Store → ⋮ → Repositories → add this repo URL
2. Install **EBO SE Bridge (local TUTK)**, fill the options, start
3. Home Assistant → Settings → Devices & Services → MQTT: the `EBO-SE` device appears
4. Add **Generic Camera**: `rtsp://ebo:<stream_pass>@<ha-host>:8554/ebo` (TCP transport)

Only one client may stream from the robot at a time: close the ROLA app while the bridge
is connected.
