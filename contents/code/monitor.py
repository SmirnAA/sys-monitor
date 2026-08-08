#!/usr/bin/env python3
import json
import re
import shutil
import subprocess
import time
from pathlib import Path


CPU_HWMON_NAMES = {"coretemp", "k10temp", "zenpower", "cpu_thermal"}
CPU_THERMAL_TYPES = {"x86_pkg_temp", "TCPU", "acpitz"}


def read_text(path):
    try:
        return Path(path).read_text(encoding="utf-8").strip()
    except OSError:
        return None


def read_cpu_raw():
    raw = read_text("/proc/stat")
    if not raw:
        return {"idle": 0, "total": 0}

    first = raw.splitlines()[0].split()[1:]
    values = [int(value) for value in first]
    idle = values[3] + values[4]
    total = sum(values)
    return {"idle": idle, "total": total}


def read_mem_info():
    raw = read_text("/proc/meminfo")
    if not raw:
        return {
            "ramPct": 0,
            "swapPct": 0,
            "ramUsedMB": 0,
            "ramTotalMB": 0,
            "swapUsedMB": 0,
            "swapTotalMB": 0,
        }

    def get_value(key):
        match = re.search(rf"^{re.escape(key)}:\s+(\d+)", raw, flags=re.MULTILINE)
        return int(match.group(1)) if match else 0

    total = get_value("MemTotal")
    available = get_value("MemAvailable")
    free = get_value("MemFree")
    buffers = get_value("Buffers")
    cached = get_value("Cached")
    swap_total = get_value("SwapTotal")
    swap_free = get_value("SwapFree")

    fallback_used = total - free - buffers - cached
    used = max(0, total - available if available else fallback_used)
    swap_used = max(0, swap_total - swap_free)

    return {
        "ramPct": round((used / total) * 100) if total else 0,
        "swapPct": round((swap_used / swap_total) * 100) if swap_total else 0,
        "ramUsedMB": round(used / 1024),
        "ramTotalMB": round(total / 1024),
        "swapUsedMB": round(swap_used / 1024),
        "swapTotalMB": round(swap_total / 1024),
    }


def read_net_raw():
    raw = read_text("/proc/net/dev")
    if not raw:
        return {"rxBytes": 0, "txBytes": 0}

    rx_bytes = 0
    tx_bytes = 0
    for line in raw.splitlines()[2:]:
        parts = line.split()
        if len(parts) < 10:
            continue

        name = parts[0].rstrip(":")
        if name == "lo":
            continue

        rx_bytes += int(parts[1])
        tx_bytes += int(parts[9])

    return {"rxBytes": rx_bytes, "txBytes": tx_bytes}


def detect_gpu():
    if shutil.which("nvidia-smi"):
        return "nvidia"
    if Path("/sys/class/drm/card0/device/gpu_busy_percent").exists():
        return "amd"
    return "none"


def read_gpu_percent(gpu_type):
    if gpu_type == "amd":
        value = read_text("/sys/class/drm/card0/device/gpu_busy_percent")
        return int(value) if value and value.isdigit() else 0

    if gpu_type == "nvidia":
        try:
            result = subprocess.run(
                [
                    "nvidia-smi",
                    "--query-gpu=utilization.gpu",
                    "--format=csv,noheader,nounits",
                ],
                check=True,
                capture_output=True,
                text=True,
                timeout=1.5,
            )
            return int(result.stdout.strip() or 0)
        except (OSError, subprocess.SubprocessError, ValueError):
            return 0

    return None


def find_cpu_temp_path():
    hwmon_root = Path("/sys/class/hwmon")
    for hwmon in hwmon_root.glob("hwmon*"):
        name = read_text(hwmon / "name")
        if name not in CPU_HWMON_NAMES:
            continue

        for index in range(1, 33):
            label_path = hwmon / f"temp{index}_label"
            input_path = hwmon / f"temp{index}_input"
            label = read_text(label_path) or ""
            if not input_path.exists():
                continue
            if re.search(r"package", label, flags=re.IGNORECASE):
                return input_path

        fallback = hwmon / "temp1_input"
        if fallback.exists():
            return fallback

    thermal_root = Path("/sys/class/thermal")
    for zone in thermal_root.glob("thermal_zone*"):
        zone_type = read_text(zone / "type")
        if zone_type not in CPU_THERMAL_TYPES:
            continue

        temp_file = zone / "temp"
        if temp_file.exists():
            return temp_file

    return None


def read_cpu_temp():
    path = find_cpu_temp_path()
    if not path:
        return None

    raw = read_text(path)
    if not raw:
        return None

    try:
        milli_c = int(raw)
    except ValueError:
        return None

    if milli_c <= 0:
        return None
    return round(milli_c / 1000)


def main():
    gpu_type = detect_gpu()
    payload = {
        "timestampMs": round(time.time() * 1000),
        "cpuRaw": read_cpu_raw(),
        "mem": read_mem_info(),
        "netRaw": read_net_raw(),
        "gpuType": gpu_type,
        "gpuPct": read_gpu_percent(gpu_type),
        "cpuTemp": read_cpu_temp(),
    }
    print(json.dumps(payload, separators=(",", ":")))


if __name__ == "__main__":
    main()
