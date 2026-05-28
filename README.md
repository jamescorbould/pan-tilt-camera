# Pan-Tilt Camera System

A lightweight, modern pan-tilt camera system built on Raspberry Pi.

## Features

- 🎥 RTSP video streaming via MediaMTX
- 🎮 MQTT-based pan/tilt control
- ⚙️ Smooth servo motion using hardware PWM
- 🏠 Native Home Assistant integration

This project is designed to be simple, reliable, and easy to extend.

---

## Prerequisites

- Raspberry Pi (tested on Pi 3/4/5)
- Raspberry Pi Camera Module (CSI ribbon cable camera)
- 2x Servo motors for pan/tilt
- MQTT broker (Mosquitto or built into Home Assistant)
- Raspberry Pi OS (64-bit or 32-bit)

---

## Setup Instructions

### 1. Clone the repository onto the Raspberry Pi

```bash
git clone https://github.com/jamescorbould/pan-tilt-camera.git
cd pan-tilt-camera
```

### 2. Run the setup script

```bash
sudo bash setup-pantilt.sh
```

**Note:** Run with `bash` (not `./setup-pantilt.sh`) to avoid line ending issues.

The script will:

- Update the system
- Enable camera and SSH
- Install pigpio + Python dependencies
- Build and install pigpio daemon
- Install MediaMTX RTSP server (architecture auto-detected)
- Configure camera settings
- Copy project files to `/opt/pantilt/`
- Install and enable systemd services

### 3. Configure the camera (if needed)

If the camera isn't detected after setup, edit boot configuration:

```bash
sudo nano /boot/firmware/config.txt
```

Or on older systems:

```bash
sudo nano /boot/config.txt
```

Ensure these lines are present:

```
start_x=1
gpu_mem=128
camera_auto_detect=1
```

Then reboot:

```bash
sudo reboot
```

### 4. Verify installation

After reboot, check services:

```bash
sudo systemctl status pigpiod
sudo systemctl status rtsp
sudo systemctl status pantilt
```

Check camera detection:

```bash
vcgencmd get_camera
```

Should show: `supported=1 detected=1` or `libcamera interfaces=1`

### After Installation

- **RTSP stream:** `rtsp://<pi-ip>:8554/cam`
- **MQTT topics:** `pantilt/pan` and `pantilt/tilt`

---

## 🎥 Camera Streaming

The Pi exposes a standard RTSP stream using `mediamtx`.

**Default stream URL:**

```
rtsp://<pi-ip>:8554/cam
```

This works with:

- Home Assistant
- Frigate
- VLC
- Blue Iris
- Any RTSP-compatible client

---

## 🎮 MQTT Pan-Tilt Control

The Python controller listens for MQTT messages:

| Topic | Commands |
|-------|----------|
| `pantilt/pan` | `left` / `right` |
| `pantilt/tilt` | `up` / `down` |

Each command moves the servo in small increments for smooth control.

---

## 🏠 Home Assistant Integration

### Add the Camera

```yaml
camera:
  - platform: generic
    name: Pan Tilt Camera
    stream_source: "rtsp://<pi-ip>:8554/cam"
```

### Add MQTT Buttons

```yaml
mqtt:
  button:
    - name: Pan Left
      command_topic: "pantilt/pan"
      payload_press: "left"

    - name: Pan Right
      command_topic: "pantilt/pan"
      payload_press: "right"

    - name: Tilt Up
      command_topic: "pantilt/tilt"
      payload_press: "up"

    - name: Tilt Down
      command_topic: "pantilt/tilt"
      payload_press: "down"
```

### Dashboard Example

```yaml
type: grid
columns: 3
cards:
  - type: button
    name: Up
    entity: button.tilt_up
  - type: button
    name: Left
    entity: button.pan_left
  - type: button
    name: Right
    entity: button.pan_right
  - type: button
    name: Down
    entity: button.tilt_down
```

---

## � Hardware Wiring

### Servo Connections

Connect servos to the Raspberry Pi GPIO pins:

- **Pan Servo:**
  - Signal → GPIO 12 (Pin 32)
  - Power → 5V (Pin 2 or 4)
  - Ground → GND (Pin 6)

- **Tilt Servo:**
  - Signal → GPIO 13 (Pin 33)
  - Power → 5V (Pin 2 or 4)
  - Ground → GND (Pin 6)

**Note:** For heavy servos or multiple servos, use an external 5V power supply to avoid brownouts.

### Camera Module

Connect the camera ribbon cable to the **CAMERA** port (not DISPLAY):
- Blue side of ribbon faces the USB/Ethernet ports on the Pi
- Blue side faces away from the lens on the camera module

---

## 🔧 Troubleshooting

### Camera not streaming

Check RTSP service status:

```bash
sudo systemctl status rtsp
```

View detailed logs:

```bash
sudo journalctl -u rtsp -n 50
```

### Camera not detected

Check if camera is recognized:

```bash
vcgencmd get_camera
ls -l /dev/video*
```

Should show `supported=1 detected=1` or `libcamera interfaces=1`

If not detected:
1. Power off completely: `sudo shutdown -h now`
2. Reseat the camera ribbon cable (ensure correct orientation)
3. Verify boot configuration has `start_x=1` and `gpu_mem=128`
4. Reboot and check again

### Pan/tilt not responding

Check pantilt service:

```bash
sudo systemctl status pantilt
```

Test pigpio daemon:

```bash
sudo systemctl status pigpiod
```

### Test MQTT manually

```bash
mosquitto_pub -t pantilt/pan -m left
mosquitto_pub -t pantilt/tilt -m up
```

### Servos jitter or don't move smoothly

- Use a separate 5V power supply for servos (brownout protection)
- Check GPIO pin connections
- Verify pigpiod is running

### RTSP stream timeout in Home Assistant

1. Verify rtsp service is running: `sudo systemctl status rtsp`
2. Check firewall allows port 8554
3. Test locally on Pi: `curl rtsp://localhost:8554/cam`
4. Verify correct Pi IP address in Home Assistant config
5. Check network connectivity between HA and Pi

### Wrong architecture error (mediamtx)

The setup script auto-detects architecture. To verify:

```bash
uname -m
```

- `aarch64` = 64-bit ARM (uses arm64v8 binary)
- `armv7l` = 32-bit ARM (uses armv7 binary)

If you see architecture errors, manually download the correct version from [MediaMTX releases](https://github.com/bluenviron/mediamtx/releases).

### Line ending errors when running setup script

If you see "command not found" errors, run with bash explicitly:

```bash
sudo bash setup-pantilt.sh
```

Or convert line endings:

```bash
sudo apt install dos2unix -y
dos2unix setup-pantilt.sh
chmod +x setup-pantilt.sh
sudo ./setup-pantilt.sh
```
