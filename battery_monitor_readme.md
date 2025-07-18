# 🔋 Smart Battery Monitor for Home Assistant

Automatically manage your laptop's battery health by controlling a smart plug through Home Assistant. This script prevents overcharging while ensuring your laptop stays powered when needed.

## 📋 Overview

This solution is perfect for laptops running as mini-servers. It automatically:
- **Turns ON** the smart plug when battery drops to 10% and is discharging
- **Turns OFF** the smart plug when battery percentage stays unchanged for 20 minutes (indicating full charge)
- **Sends notifications** via ntfy.sh when actions are taken
- **Logs all activities** with timestamps

## 🏗️ System Architecture

![System Architecture](architecture-diagram.png)

The system works through a simple but effective setup:

1. **Mini-Server (Laptop)** runs the monitoring script
2. **Home Assistant** receives API calls to control the smart plug
3. **Smart Plug** controls power to the laptop's AC adapter
4. **Notifications** are sent via ntfy.sh when actions are taken

**Logic Flow:**
- Battery ≤ 10% + Discharging → Smart Plug ON
- Battery unchanged for 20+ minutes → Smart Plug OFF (prevents overcharging)

## 🚀 Features

- ⚡ **Automatic Power Management**: Smart plug control based on battery state
- 🔋 **Battery Health Protection**: Prevents overcharging by monitoring charge completion
- 📱 **Push Notifications**: Real-time alerts via ntfy.sh
- 📊 **Detailed Logging**: Complete activity logs with timestamps
- 🔄 **Systemd Service**: Runs as a system service with auto-restart
- 🛡️ **Error Handling**: Robust error handling and recovery

## 📦 Prerequisites

### Hardware
- Laptop with battery (obviously!)
- Smart plug compatible with Home Assistant
- Home Assistant instance running on your network

### Software
- Linux system (Ubuntu/Debian recommended)
- `upower` utility for battery monitoring
- `curl` for API calls
- `bc` for floating-point calculations

## 🛠️ Installation

### 1. Install Dependencies

```bash
sudo apt update
sudo apt install upower curl bc
```

### 2. Download the Script

```bash
sudo curl -o /usr/local/bin/battery_monitor.sh https://raw.githubusercontent.com/yourusername/battery-monitor/main/battery_monitor.sh
sudo chmod +x /usr/local/bin/battery_monitor.sh
```

### 3. Configure the Script

Edit the script to match your setup:

```bash
sudo nano /usr/local/bin/battery_monitor.sh
```

Update these variables:
- `HOME_ASSISTANT_URL`: Your Home Assistant URL
- `HOME_ASSISTANT_TOKEN`: Your long-term access token
- `SMART_PLUG_ENTITY`: Your smart plug entity ID
- `NTFY_URL`: Your ntfy.sh notification URL

### 4. Set Up as System Service

```bash
sudo curl -o /etc/systemd/system/battery-monitor.service https://raw.githubusercontent.com/yourusername/battery-monitor/main/battery-monitor.service

sudo systemctl daemon-reload
sudo systemctl enable battery-monitor.service
sudo systemctl start battery-monitor.service
```

## ⚙️ Configuration

### Home Assistant Setup

#### 1. Find Your Smart Plug Entity ID

1. Go to **Settings** → **Devices & Services** → **Entities**
2. Search for your smart plug
3. Note the entity ID (e.g., `switch.mbp_smartplug`)

#### 2. Generate Long-Term Access Token

1. Go to your **Profile** (click your name in the sidebar)
2. Scroll down to **Long-Lived Access Tokens**
3. Click **Create Token**
4. Give it a name and copy the token

### Notification Setup (Optional)

1. Visit [ntfy.sh](https://ntfy.sh)
2. Choose a unique topic name
3. Use the URL format: `ntfy.sh/your-topic-name`

## 🔧 Script Configuration

```bash
# Configuration
HOME_ASSISTANT_URL="http://192.168.1.100:8123"
HOME_ASSISTANT_TOKEN="your-long-term-access-token-here"
SMART_PLUG_ENTITY="switch.your_smartplug_entity"
NTFY_URL="ntfy.sh/your-unique-topic"
```

## 📊 How It Works

### Battery Monitoring Logic

1. **Every 30 seconds**: Check battery percentage and state
2. **Every minute**: Log detailed battery information
3. **Low Battery Trigger**: When battery ≤ 10% and discharging → Turn ON smart plug
4. **Full Battery Trigger**: When battery percentage unchanged for 20 minutes → Turn OFF smart plug

### State Tracking

The script tracks:
- Current battery percentage
- Battery state (charging/discharging/full)
- Smart plug state (on/off)
- How long battery percentage has been unchanged

## 📱 Service Management

```bash
# Check service status
sudo systemctl status battery-monitor.service

# View logs
sudo journalctl -u battery-monitor.service -f

# Restart service
sudo systemctl restart battery-monitor.service

# Stop service
sudo systemctl stop battery-monitor.service
```

## 📋 Log Output Example

```
2024-07-18 14:30:15 - Battery: 45% (charging) | Plug: on | Unchanged: 0/40
2024-07-18 14:30:45 - Battery: 46% (charging) | Plug: on | Unchanged: 0/40
2024-07-18 14:31:15 - === Every minute battery check ===
2024-07-18 14:31:15 - state:               charging
2024-07-18 14:31:15 - percentage:          46%
2024-07-18 14:31:15 - time to full:        2.1 hours
2024-07-18 14:31:15 - === End minute check ===
```

## 🔍 Troubleshooting

### Common Issues

1. **"upower not found"**: Install with `sudo apt install upower`
2. **"curl not found"**: Install with `sudo apt install curl`
3. **API connection failed**: Check Home Assistant URL and token
4. **Smart plug not responding**: Verify entity ID in Home Assistant

### Debug Commands

```bash
# Test battery info
upower -i $(upower -e | grep 'BAT') | grep -E "state|to\ full|percentage"

# Test Home Assistant connection
curl -H "Authorization: Bearer YOUR_TOKEN" \
     "http://YOUR_HA_URL:8123/api/states/switch.your_smartplug"

# Check service logs
sudo journalctl -u battery-monitor.service --since "1 hour ago"
```

## 🎯 Customization

### Modify Trigger Points

Edit these values in the script:
- **Low battery threshold**: Change `10` in the condition `$CURRENT_PERCENTAGE <= 10`
- **Unchanged duration**: Change `40` (20 minutes) in `$UNCHANGED_COUNT -ge 40`
- **Check interval**: Change `30` in `sleep 30` (30 seconds)

### Add More Notifications

You can add email, Discord, or other notification methods by extending the notification functions.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Home Assistant community for the excellent platform
- ntfy.sh for simple notification service
- upower developers for battery monitoring tools

## 📞 Support

If you encounter issues:
1. Check the [troubleshooting section](#-troubleshooting)
2. Review the [logs](#-service-management)
3. Open an issue on GitHub

---

⭐ **Star this repository** if you find it helpful!

🔗 **Share** with others who might benefit from automated battery management!