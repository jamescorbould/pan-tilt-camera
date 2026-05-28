#!/bin/bash
set -e

# Save the current directory (where the script was run from)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Updating system ==="
sudo apt update && sudo apt upgrade -y

echo "=== Enabling camera and SSH ==="
sudo raspi-config nonint do_camera 0
sudo raspi-config nonint do_ssh 0

echo "=== Installing base dependencies ==="
sudo apt install -y python3-pip python3-dev python3-setuptools mosquitto-clients cmake git build-essential

echo "=== Installing pigpio from source ==="
if [ ! -d "/tmp/pigpio" ]; then
    cd /tmp
    git clone https://github.com/joan2937/pigpio.git
    cd pigpio
    make
    sudo make install
    cd "$SCRIPT_DIR"
fi

echo "=== Configuring library path ==="
sudo ldconfig

echo "=== Installing pigpio Python library ==="
sudo pip3 install pigpio --break-system-packages

echo "=== Creating pigpiod systemd service ==="
sudo tee /etc/systemd/system/pigpiod.service > /dev/null <<EOF
[Unit]
Description=Pigpio daemon
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/pigpiod -l
ExecStop=/bin/systemctl kill pigpiod
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "=== Enabling pigpio ==="
sudo systemctl daemon-reload
sudo systemctl enable --now pigpiod

echo "=== Installing mediamtx ==="
if [ ! -f "/usr/local/bin/mediamtx" ]; then
    # Detect architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "aarch64" ]; then
        MEDIAMTX_ARCH="arm64v8"
    elif [ "$ARCH" = "armv7l" ]; then
        MEDIAMTX_ARCH="armv7"
    else
        echo "ERROR: Unsupported architecture: $ARCH"
        exit 1
    fi
    
    MEDIAMTX_VERSION="v1.9.1"
    cd /tmp
    wget https://github.com/bluenviron/mediamtx/releases/download/${MEDIAMTX_VERSION}/mediamtx_${MEDIAMTX_VERSION}_linux_${MEDIAMTX_ARCH}.tar.gz
    tar -xzf mediamtx_${MEDIAMTX_VERSION}_linux_${MEDIAMTX_ARCH}.tar.gz
    sudo mv mediamtx /usr/local/bin/
    sudo chmod +x /usr/local/bin/mediamtx
    cd "$SCRIPT_DIR"
fi

echo "=== Creating mediamtx configuration ==="
sudo mkdir -p /etc/mediamtx
sudo tee /etc/mediamtx/mediamtx.yml > /dev/null <<EOF
paths:
  cam:
    source: rpiCamera
    rpiCameraCamID: 0
    rpiCameraWidth: 1280
    rpiCameraHeight: 720
    rpiCameraFPS: 30
EOF

echo "=== Creating target directories ==="
sudo mkdir -p /opt/pantilt

# pantilt.py
if [ -f "./pantilt/pantilt.py" ]; then
    echo "Installing pantilt.py → /opt/pantilt/"
    sudo cp ./pantilt/pantilt.py /opt/pantilt/pantilt.py
else
    echo "ERROR: pantilt/pantilt.py not found"
    exit 1
fi

# requirements.txt
if [ -f "./pantilt/requirements.txt" ]; then
    echo "Installing requirements.txt → /opt/pantilt/"
    sudo cp ./pantilt/requirements.txt /opt/pantilt/requirements.txt
else
    echo "ERROR: pantilt/requirements.txt not found"
    exit 1
fi

echo "=== Installing Python dependencies ==="
sudo pip3 install -r /opt/pantilt/requirements.txt --break-system-packages

# pantilt.service
if [ -f "./systemd/pantilt.service" ]; then
    echo "Installing pantilt.service → /etc/systemd/system/"
    sudo cp ./systemd/pantilt.service /etc/systemd/system/pantilt.service
else
    echo "ERROR: systemd/pantilt.service not found"
    exit 1
fi

# rtsp.service
if [ -f "./systemd/rtsp.service" ]; then
    echo "Installing rtsp.service → /etc/systemd/system/"
    sudo cp ./systemd/rtsp.service /etc/systemd/system/rtsp.service
else
    echo "ERROR: systemd/rtsp.service not found"
    exit 1
fi

#############################################
# ENABLE SERVICES
#############################################

echo "=== Reloading systemd ==="
sudo systemctl daemon-reload

echo "=== Enabling pantilt.service ==="
sudo systemctl enable --now pantilt

echo "=== Enabling rtsp.service ==="
sudo systemctl enable --now rtsp

#############################################
# DONE
#############################################

echo "=== Setup complete ==="
echo "RTSP stream available at: rtsp://<pi-ip>:8554/unicast"
echo "MQTT topics: pantilt/pan and pantilt/tilt"
echo "All services installed and running"