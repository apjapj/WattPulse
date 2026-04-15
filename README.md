WattPulse ⚡

WattPulse is an intelligent, universal Linux power diagnostic utility. It is designed to bridge the gap between simple battery monitoring and professional electrical troubleshooting.

By tracking Voltage Sag and correlating it with real-time kernel power events, WattPulse can differentiate between a failing power supply (Brownout) and a physical connection fault (Handshake/Port issues).

🌟 Key Features
1. Relative Voltage Sag Analysis

WattPulse calculates the percentage drop in voltage under load.

    Sag > 15%: Indicates a "Brownout." Your power adapter or battery cells lack the capacity to maintain pressure.

    Sag < 5%: If power disconnects occur despite stable voltage, the issue is physical (data-pin handshake, dirty ports, or cable wiggles).

2. Intelligent OS Automation

To prevent "False Positive" logs caused by your computer's screen saver or idle-dimming settings, WattPulse automatically detects and suspends:

    X11 Screen Savers (via xset)

    MATE Power Manager idle-dimming (via gsettings)

    Note: All original user settings are captured and restored automatically upon exit.

3. Precision Timed Runs

Perform "Hands-Off" diagnostics with the -t flag. The script provides a live countdown on the dashboard and auto-exits to a summary report once the timer hits zero.

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

Setup
```bash
git clone https://github.com/apjapj/WattPulse.git
cd WattPulse
chmod +x wattpulse.sh
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

If your voltage drops below these levels during a stress test, your adapter is likely failing.
| Model | Healthy Range | Critical Floor | Recommended |
| :--- | :--- | :--- | :--- |
| MBP 15" (2015) | 12.0V - 12.6V | ~10.8V | 85W MagSafe 2 |
| MBP 13" (2015) | 11.5V - 12.1V | ~10.5V | 60W MagSafe 2 |
| MBA 13" (2015) | 8.0V - 8.6V | ~7.2V | 45W MagSafe 2 |

Interpreting Summary Logs

    backlight-helper events: With OS dimming disabled, these indicate the hardware physically lost the AC connection.

    intel_powerclamp / thermal: Indicates the CPU is throttling due to heat during the stress test.

    dbus-daemon / Notifications: MATE is attempting to warn you that the charger was disconnected.

💡 Hardware Troubleshooting

If WattPulse identifies an Intermittent Connection:

    The Toothpick Trick: Magnetic ports (like MagSafe) attract metallic dust. Use a wooden toothpick to clean the corners of the port.

    Pin Inspection: Ensure all gold pins on the charger spring back freely. Blackened pins indicate carbon buildup/arcing and should be cleaned with 90% Isopropyl alcohol.

⚖️ License

MIT License - Developed to keep Linux systems electrically sound.
