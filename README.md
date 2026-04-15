WattPulse ⚡

WattPulse is an intelligent, universal Linux power diagnostic utility. It bridges the gap between simple battery monitoring and professional electrical troubleshooting, designed specifically to identify the "ghosts in the machine" that haunt portable hardware.

📜 Historical Origins

WattPulse was born out of necessity rather than surplus. The software was created because its author, not being a millionaire, frequently relied on used or budget power supplies sourced from secondary markets.

While these "bargain" adapters often work, they frequently exhibit erratic behaviors—random screen dimming, unexpected CPU throttling, or rhythmic power-cycling. WattPulse provides the transparency needed to trust your budget gear and ensure your "cheap" supply isn't actually a liability to your logic board.

🌟 Key Features

1. Relative Voltage Sag Analysis

WattPulse calculates the percentage drop in voltage under load.

    Sag > 15%: Indicates a "Brownout." Your power adapter or battery cells lack the capacity to maintain pressure under load.

    Sag < 5%: If power disconnects occur despite stable voltage, the issue is physical (data-pin handshake, dirty ports, or cable internal fractures).

2. Intelligent OS Automation

To prevent "False Positive" logs caused by your computer's screen saver or idle-dimming settings, WattPulse automatically detects and suspends:

    X11 Screen Savers (via xset)

    MATE Power Manager idle-dimming (via gsettings)

    Note: All original user settings are captured and restored automatically upon exit.

3. Precision Timed Runs

Perform "Hands-Off" diagnostics with the -t flag. The script provides a live countdown on the dashboard and auto-exits to a diagnostic summary once the timer hits zero.

🛠 Installation

Prerequisites

Requires upower, bc, and x11-xserver-utils. For stress testing, stress-ng is recommended.

Ubuntu / Linux Mint / Debian:
```bash
sudo apt update && sudo apt install upower bc stress-ng x11-xserver-utils
```

Fedora:
```bash
sudo dnf install upower bc stress-ng xorg-x11-server-utils
```

⌨️ Usage

Standard Dashboard

Live monitoring of voltage, charge, and power states.
```bash
./wattpulse.sh
```

Timed Stress Test (The "Clean-Room" Test)

Triggers a CPU stress test for 60 seconds and auto-exits to a diagnostic summary.
```bash
./wattpulse.sh -s -t 60
```

Options

    -h, --help: Extended help menu with hardware reference tables.

    -v, --version: Show current version.

    -l, --log-file: Export session logs to a timestamped file.

📖 Diagnostic Reference

Voltage "Floor" Table

If your voltage drops below these levels during a stress test, your adapter or battery is likely failing.

| Model | Healthy Range | Critical Floor | Recommended |
| :--- | :--- | :--- | :--- |
| MBP 15" (2015) | 12.0V - 12.6V | ~10.8V | 85W MagSafe 2 |
| MBP 13" (2015) | 11.5V - 12.1V | ~10.5V | 60W MagSafe 2 |
| MBA 13" (2015) | 8.0V - 8.6V | ~7.2V | 45W MagSafe 2 |
| Raspberry Pi (All) | 4.75V - 5.25V | ~4.63V | 2.5A - 3.0A USB |

🍓 Raspberry Pi Specific Diagnostics

On Raspberry Pi systems, power issues are usually about "quality" rather than "quantity."

    Under-voltage: Triggered if voltage drops below 4.63V. WattPulse will flag these kernel events in the summary.

    The Cable Trap: Low-quality USB cables have high resistance. A 3A brick is useless if a thin cable causes a massive Voltage Sag under load.

    Peripheral Load: If adding a USB drive causes your "Max Voltage" to sag more than 0.2V, your PSU is insufficient for your current HAT/USB configuration.

💡 Hardware Troubleshooting

If WattPulse identifies an Intermittent Connection:

    The Toothpick Trick: Magnetic ports (like MagSafe) attract metallic dust. Use a wooden toothpick to clean the corners of the port.

    Pin Inspection: Ensure all gold pins on the charger spring back freely. Blackened pins indicate carbon buildup (arcing) and should be cleaned with 90% Isopropyl alcohol.

⚖️ License

MIT License - Developed to keep Linux systems (and their budget power supplies) electrically sound.
