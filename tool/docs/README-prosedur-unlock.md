# Unlock Bootloader — Itel S23 (S665L) / Unisoc T606

Guide to unlock the bootloader on the Itel S23 (S665L) using the CVE-2022-38694 exploit on the Unisoc T606 (UMS9230) chipset.

## Device Info

| Property | Value |
|---|---|
| Brand | Itel |
| Model | S665L (S23) |
| Android | 12 (SDK 31) |
| Build | S665L-F065OPRSUVApAqAr-S-GL-20250207V533 |
| SoC | Unisoc T606 (UMS9230) |
| CPU | 2x Cortex-A75 + 6x Cortex-A55 (ARMv8, 64-bit) |
| Storage | UFS |
| Slot | A/B |

## Prerequisites

- Linux (tested on Fedora 43)
- `adb` and `fastboot` installed
- USB data cable (not charge-only)
- Battery at least 80%
- **OEM Unlocking** enabled in Developer Options
- **USB Debugging** enabled in Developer Options
- Back up all data (will be wiped after unlock)

## File Structure

```
ubl-itel-s23/
├── README.md
├── CLAUDE.md
├── recovery/
│   ├── TWRP_S665L.img              # TWRP recovery image
│   └── OrangeFox_S665L.img         # OrangeFox recovery image
└── tools/
    └── spreadtrum_flash_linux/
        ├── spd_dump                 # BootROM communication tool
        ├── gen_spl-unlock           # Unlock payload generator
        ├── unlock.sh                # Automated unlock script
        ├── fdl1-dl.bin              # First-stage loader
        ├── fdl2-dl.bin              # Second-stage loader
        ├── fdl2-cboot.bin           # Modified uboot for unlock
        ├── custom_exec_no_verify_65015f08.bin  # CVE exploit payload
        ├── custom_exec_no_verify_65015f48.bin  # CVE exploit payload (alt)
        ├── splloader.bin            # SPL backup (generated during process)
        ├── uboot.bin                # uboot backup (generated during process)
        ├── spl-unlock.bin           # Unlock payload (generated during process)
        └── ums9230/itel/            # FDL binaries for Itel UMS9230
```

## How It Works (CVE-2022-38694)

This exploit takes advantage of a vulnerability in the Unisoc BootROM that allows writing data to a memory region before signature verification completes.

```
Normal:   BootROM → verify(FDL1) → REJECT (unsigned)
Exploit:  BootROM → overwrite verify() → verify = always_true
               → accept(FDL1) → ACCEPT → unlock bootloader
```

The `custom_exec_no_verify` payload (96 bytes) overwrites the signature verification function pointer at address `0x65015f08`, causing the BootROM to accept any FDL1 without checking its signature.

## Unlock Process

### Initial Setup

1. Install udev rules for USB access:

```bash
sudo tee /etc/udev/rules.d/51-android.rules << 'EOF'
# Google/Android (ADB & Fastboot)
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"
# Spreadtrum/Unisoc
SUBSYSTEM=="usb", ATTR{idVendor}=="1782", MODE="0666", GROUP="plugdev"
EOF
sudo udevadm control --reload-rules && sudo udevadm trigger
```

2. Copy FDL files and exploit payloads to the working directory:

```bash
cd tools/spreadtrum_flash_linux
cp ums9230/itel/fdl1-dl.bin ums9230/itel/fdl2-dl.bin ums9230/itel/fdl2-cboot.bin .
cp ums9230/custom_exec_no_verify_65015f08.bin ums9230/custom_exec_no_verify_65015f48.bin .
chmod +x spd_dump gen_spl-unlock
```

### Step 1 — Backup splloader & uboot, erase splloader

Phone must be **powered on and connected via USB**. After this step, the phone will not boot until Step 6.

```bash
sudo ./spd_dump exec_addr 0x65015f48 fdl fdl1-dl.bin 0x65000800 \
  fdl fdl2-dl.bin 0x9efffe00 exec \
  r splloader r uboot e splloader e splloader_bak reset
```

Back up `splloader.bin` and `uboot.bin` to a safe location:

```bash
cp splloader.bin uboot.bin backup_spl/
```

### Step 2 — Generate unlock payload

```bash
./gen_spl-unlock splloader.bin 0xfd28
```

Output: `spl-unlock.bin`

> The offset `0xfd28` is specific to this firmware. Check the size of `splloader.bin` — the offset should match the file size.

### Step 3 — Flash modified uboot

Enter BROM mode: power off the phone, hold **Volume Down**, then plug in USB.

```bash
sudo ./spd_dump exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 \
  fdl fdl2-dl.bin 0x9efffe00 exec \
  w uboot fdl2-cboot.bin reset
```

### Step 4 — Send unlock payload

Enter BROM mode again, then:

```bash
sudo ./spd_dump exec_addr 0x65015f08 fdl spl-unlock.bin 0x65000800
```

If you see `device removed, exiting...` it means **success**.

### Step 5 — Verify unlock status

Enter BROM mode again, then:

```bash
sudo ./spd_dump exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 \
  fdl fdl2-dl.bin 0x9efffe00 exec \
  verbose 2 read_part miscdata 8192 64 m.bin reset
```

- `recv 64 zero` = still **LOCKED** (failed)
- `recv 32 string + hash data` = **UNLOCKED** (success)

### Step 6 — Restore splloader & uboot

Enter BROM mode again, then:

```bash
sudo ./spd_dump exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 \
  fdl fdl2-dl.bin 0x9efffe00 exec \
  w splloader splloader.bin w uboot uboot.bin reset
```

The phone will reboot. Select **Factory Reset** when Android Recovery appears.

### Verify via ADB

After the phone boots into Android:

```bash
adb shell getprop ro.boot.vbmeta.device_state
# Expected: unlocked

adb shell getprop ro.boot.flash.locked
# Expected: 0
```

## Important Notes

- After unlocking, the phone will display a warning screen on boot (this is normal)
- OTA updates will likely stop working
- Warranty is voided
- Do not delete `splloader.bin` and `uboot.bin` — they are needed for restore if something goes wrong
- Step 1 uses address `0x65015f48`, steps 3-6 use `0x65015f08`

## Credits & References

### Tools

- **spd_dump / CVE-2022-38694 Unlock Bootloader**
  by [TomKing062](https://github.com/TomKing062) / QuTick102
  https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader

- **Recovery Collections & Spreadtrum Flash Tool (Linux)**
  by [Massatriof16](https://github.com/Massatriof16)
  https://massatriof16.github.io/recovery-collections/#alat

- **unisoc-unlock** (Python alternative)
  by [patrislav1](https://github.com/patrislav1)
  https://github.com/patrislav1/unisoc-unlock

### Guides & References

- [Itel S23 Unlock Bootloader Guide — XDA Forums](https://xdaforums.com/t/itel-s23-unlock-bootloader-guide-for-windows-based-pc-laptop.4742794/)
- [How to unlock Unisoc (SPD) bootloader using Identifier Token — Hovatek](https://www.hovatek.com/forum/thread-32287.html)
- [SUBUT — Spreadtrum/Unisoc Bootloader Unlock Tool (Web)](https://thegammasqueeze.github.io/subut-rehost/)

### Recovery Images

- **TWRP & OrangeFox for Itel S23** — from [Massatriof16 Recovery Collections](https://massatriof16.github.io/recovery-collections/)
