# Pan-Tilt Camera System

A lightweight, modern pan-tilt camera system built on Raspberry Pi with MQTT control and RTSP streaming.

**Hardware:** This project is designed for the [Duinotech XC9050 Pan-Tilt HAT](https://github.com/Jaycar-Electronics/Pan-Tilt-Camera). The HAT provides convenient servo connectors and is available from Jaycar Electronics.

## Features

- 🎥 RTSP video streaming via MediaMTX
- 🎮 MQTT-based pan/tilt control
- ⚙️ Smooth servo motion using hardware PWM (pigpio)
- 🏠 Native Home Assistant integration
- 🔧 Compatible with XC9050 Pan-Tilt HAT or direct GPIO wiring

This project is designed to be simple, reliable, and easy to extend.

---

## Prerequisites

**Hardware:**
- Raspberry Pi (tested on Pi 3/4/5)
- Raspberry Pi Camera Module (CSI ribbon cable camera)
- **Duinotech XC9050 Pan-Tilt HAT** (recommended) or compatible GPIO breakout
  - Includes 2x mounting points for servo motors
  - Available from [Jaycar Electronics](https://www.jaycar.com.au/)
  - See [official Jaycar project guide](https://github.com/Jaycar-Electronics/Pan-Tilt-Camera)
- 2x Micro servo motors (e.g., SG90 or similar)

**Software:**
- Raspberry Pi OS (64-bit or 32-bit)
- MQTT broker (Mosquitto on Pi, or Home Assistant's built-in broker)

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
- Install pigpio from source + Python dependencies
- Install pigpio daemon (configured for port 9000)
- Install MediaMTX RTSP server (architecture auto-detected)
- Configure camera settings
- Copy project files to `/opt/pantilt/`
- Install and enable systemd services (pigpiod, pantilt, rtsp)
- Configure MQTT connection to localhost

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
### Setting Up via Home Assistant UI

**Step 1: Add MQTT Integration**

1. Go to **Settings** → **Devices & Services**
2. Click **+ Add Integration** (bottom right)
3. Search for **MQTT**
4. Enter connection details:
   - **Broker:** Your Raspberry Pi IP address (e.g., `192.168.1.100`)
   - **Port:** `1883`
   - Leave username/password blank if you configured `allow_anonymous true` in Mosquitto
5. Click **Submit**

**Step 2: Add the Camera**

1. Go to **Settings** → **Devices & Services**
2. Click **+ Add Integration**
3. Search for **Generic Camera**
4. Fill in:
   - **Name:** `Pan Tilt Camera`
   - **Stream Source URL:** `rtsp://192.168.1.100:8554/cam` (replace with your Pi IP)
5. Click **Submit**

The camera entity will be created as `camera.pan_tilt_camera`

**Step 3: Create Dashboard with Camera & Controls**

1. Go to your **Home** page (Overview)
2. Click the **pencil icon** in the top right (or three dots → **Edit Dashboard**)
   - If you don't see this option, click the three dots → **Take Control** first
3. Click **+ ADD CARD**

**Add Camera Card:**
1. Search for **Camera**
2. Select **Camera** card type
3. Choose **Pan Tilt Camera** from the entity list
4. Click **Save**

**Add Control Buttons:**

For each direction button, repeat these steps:

1. Click **+ ADD CARD**
2. Search for **Button**
3. Click **Button** card
4. Configure:
   - **Name:** `Pan Left ⬅️` (or `Pan Right ➡️`, `Tilt Up ⬆️`, `Tilt Down ⬇️`)
   - **Tap Action:** `Call Service`
   - **Service:** `mqtt.publish`
   - **Service Data:** Click **Edit in YAML** and enter:
     ```yaml
     topic: pantilt/pan
     payload: left
     ```

Repeat for all four buttons:
- **Pan Left:** topic `pantilt/pan`, payload `left`
- **Pan Right:** topic `pantilt/pan`, payload `right`
- **Tilt Up:** topic `pantilt/tilt`, payload `up`
- **Tilt Down:** topic `pantilt/tilt`, payload `down`

**Step 4: Arrange the Layout**

1. While still in edit mode, drag cards to arrange them
2. Optional: Use a **Grid Card** or **Vertical Stack** to organize:
   - Camera on top
   - Four directional buttons below in a grid pattern
3. Click **Done** to save the dashboard

You can now view the camera stream and control the pan/tilt servos from your Home Assistant dashboard! 🎯
---

## � Hardware Wiring

### For Duinotech XC9050 Pan-Tilt HAT

Simply plug the servos into the labeled connectors on the HAT:
- **Pan Servo** → "Pan" connector on HAT (uses GPIO 16 / IO16)
- **Tilt Servo** → "Tilt" connector on HAT (uses GPIO 18 / IO18)

**Reference:** [Official Jaycar XC9050 Project](https://github.com/Jaycar-Electronics/Pan-Tilt-Camera)

### For Generic GPIO Wiring (without HAT)

Connect servos directly to Raspberry Pi GPIO pins:

- **Pan Servo:**
  - Signal → GPIO 16 (Physical Pin 36)
  - Power → 5V (Pin 2 or 4)
  - Ground → GND (Pin 6)

- **Tilt Servo:**
  - Signal → GPIO 18 (Physical Pin 12)
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

### Camera image is upside down or flipped

Edit the MediaMTX configuration to flip the image:

```bash
sudo nano /etc/mediamtx/mediamtx.yml
```

Add flip settings under the `cam` path:

```yaml
paths:
  cam:
    source: rpiCamera
    rpiCameraCamID: 0
    rpiCameraWidth: 1280
    rpiCameraHeight: 720
    rpiCameraFPS: 30
    rpiCameraHFlip: yes
    rpiCameraVFlip: yes
```

Set both to `yes` for 180° rotation (upside down fix), or use them individually:
- `rpiCameraHFlip: yes` - Mirror image horizontally
- `rpiCameraVFlip: yes` - Flip image vertically

Then restart the service:

```bash
sudo systemctl restart rtsp
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

**Note:** pigpiod runs on port 9000 (to avoid conflict with MediaMTX on port 8888). The pantilt.py script is configured to connect to this port automatically.

Test servos manually:

```bash
mosquitto_pub -t pantilt/pan -m left
mosquitto_pub -t pantilt/pan -m right
mosquitto_pub -t pantilt/tilt -m up
mosquitto_pub -t pantilt/tilt -m down
```

If servos don't move:
1. Verify servos are plugged into IO16 (pan) and IO18 (tilt) on the XC9050 HAT
2. Check servo power connections (red to 5V, brown/black to GND)
3. Test MQTT broker is running: `sudo systemctl status mosquitto`
4. Check pantilt service logs: `sudo journalctl -u pantilt -n 20`

### "Can't connect to pigpio at localhost(9000)" error

If pantilt service logs show this error, the pigpiod service file has the wrong port configured.

Check the current port:

```bash
cat /etc/systemd/system/pigpiod.service | grep ExecStart
```

Should show: `ExecStart=/usr/local/bin/pigpiod -p 9000`

If it shows port 8889 or anything else, fix it:

```bash
sudo nano /etc/systemd/system/pigpiod.service
```

Change the ExecStart line to:
```
ExecStart=/usr/local/bin/pigpiod -p 9000
```

Then reload and restart services:

```bash
sudo systemctl daemon-reload
sudo systemctl restart pigpiod
sudo systemctl restart pantilt
```

Verify it's working:

```bash
sudo systemctl status pigpiod
sudo systemctl status pantilt
```

### MediaMTX "bind: address already in use" on port 8889

If rtsp service fails with `ERR: listen tcp :8889: bind: address already in use`, this is a WebRTC port conflict with pigpiod's socket interface.

Check what's using port 8889:

```bash
sudo netstat -tulpn | grep 8889
```

If it shows pigpiod, disable WebRTC in MediaMTX (you only need RTSP anyway):

```bash
sudo nano /etc/mediamtx/mediamtx.yml
```

Add `webrtc: no` at the top before `paths:`:

```yaml
# Disable WebRTC to avoid port conflict with pigpiod on 8889
webrtc: no

paths:
  cam:
    source: rpiCamera
    # ... rest of config
```

Then restart:

```bash
sudo systemctl restart rtsp
sudo systemctl status rtsp
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

---

## References

- **Hardware Guide:** [Jaycar XC9050 Pan-Tilt Camera Project](https://github.com/Jaycar-Electronics/Pan-Tilt-Camera) - Official assembly and wiring guide for the XC9050 HAT
- **MediaMTX:** [RTSP Server](https://github.com/bluenviron/mediamtx) - Lightweight RTSP streaming with libcamera support
- **pigpio:** [GPIO Library](https://abyz.me.uk/rpi/pigpio/) - Hardware PWM servo control
- **Home Assistant:** [Camera Integration](https://www.home-assistant.io/integrations/camera/) - RTSP camera setup guide

---

## License

MIT License - Feel free to use and modify for your own projects!
