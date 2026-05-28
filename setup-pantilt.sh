#!/bin/bash
set -e

echo "=== Updating system ==="
sudo apt update && sudo apt upgrade -y

echo "=== Enabling camera and SSH ==="
sudo raspi-config nonint do_camera 0
sudo raspi-config nonint do_ssh 0

echo "=== Installing base dependencies ==="
sudo apt install -y python3-pip mosquitto-clients cmake git

echo "=== Installing pigpio from source ==="
if [ ! -d "/tmp/pigpio" ]; then
    cd /tmp
    git clone https://github.com/joan2937/pigpio.git
    cd pigpio
    make
    sudo make install
    cd ~
fi

echo "=== Enabling pigpio ==="
sudo systemctl enable --now pigpiod

echo "=== Installing v4l2rtspserver ==="
if [ ! -f "/usr/local/bin/v4l2rtspserver" ]; then
    cd /tmp
    wget https://github.com/mpromonet/v4l2rtspserver/releases/download/v0.2.7/v4l2rtspserver-0.2.7-Linux-armv7l.tar.gz
    tar xzf v4l2rtspserver-0.2.7-Linux-armv7l.tar.gz
    sudo cp v4l2rtspserver-0.2.7-Linux-armv7l/v4l2rtspserver /usr/local/bin/
    sudo chmod +x /usr/local/bin/v4l2rtspserver
    cd ~
fi

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
sudo pip3 install -r /opt/pantilt/requirements.txt

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