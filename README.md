# Pan-Tilt Camera System

A lightweight, modern pan-tilt camera system built on Raspberry Pi.

## Features

- 🎥 RTSP video streaming
- 🎮 MQTT-based pan/tilt control
- ⚙️ Smooth servo motion using hardware PWM
- 🏠 Native Home Assistant integration

This project is designed to be simple, reliable, and easy to extend.

---

## Setup Instructions

### 1. Clone the repository onto the Raspberry Pi

```bash
git clone https://github.com/<your-username>/pan-tilt-camera.git
cd pan-tilt-camera
```

### 2. Make the setup script executable

```bash
chmod +x setup-pantilt.sh
```

### 3. Run the setup script

```bash
sudo ./setup-pantilt.sh
```

The script will:

- Install all required packages
- Enable camera + SSH
- Install pigpio + Python dependencies
- Install RTSP streaming
- Copy project files into system locations
- Install and enable systemd services

### After Installation

- **RTSP stream:** `rtsp://<pi-ip>:8554/unicast`
- **MQTT topics:** `pantilt/pan` and `pantilt/tilt`

---

## 🎥 Camera Streaming

The Pi exposes a standard RTSP stream using `v4l2rtspserver`.

**Default stream URL:**

```
rtsp://<pi-ip>:8554/unicast
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
    stream_source: "rtsp://<pi-ip>:8554/unicast"
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

## 🔧 Troubleshooting

### Camera not streaming

```bash
sudo systemctl status rtsp
```

### Pan/tilt not responding

```bash
sudo systemctl status pantilt
```

### Test MQTT manually

```bash
mosquitto_pub -t pantilt/pan -m left
```

### Servos jitter

Use a separate 5V supply if needed.
