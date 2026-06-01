import pigpio
import paho.mqtt.client as mqtt
import time
import sys

# XC9050 HAT: IO16 = GPIO 16 (Pan), IO18 = GPIO 18 (Tilt)
PAN_PIN = 16
TILT_PIN = 18

MIN = 500
MAX = 2500

pan_pos = 1500
tilt_pos = 1500

pi = None
client = None

def init_pigpio():
    """Initialize pigpio connection with retry logic"""
    global pi
    retry_count = 0
    max_retries = 10
    
    while retry_count < max_retries:
        try:
            print(f"Connecting to pigpiod (attempt {retry_count + 1}/{max_retries})...")
            pi = pigpio.pi('localhost', 9000)
            if pi.connected:
                print("✓ Connected to pigpiod")
                pi.set_mode(PAN_PIN, pigpio.OUTPUT)
                pi.set_mode(TILT_PIN, pigpio.OUTPUT)
                return True
            else:
                print("✗ pigpiod not ready")
        except Exception as e:
            print(f"✗ pigpiod connection error: {e}")
        
        retry_count += 1
        if retry_count < max_retries:
            time.sleep(2)
    
    print("Failed to connect to pigpiod after multiple attempts")
    return False

def set_servo(pin, value):
    if pi and pi.connected:
        pi.set_servo_pulsewidth(pin, value)

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("✓ Connected to MQTT broker")
        client.subscribe("pantilt/pan")
        client.subscribe("pantilt/tilt")
        print("✓ Subscribed to topics")
    else:
        print(f"✗ MQTT connection failed with code {rc}")

def on_disconnect(client, userdata, rc):
    if rc != 0:
        print(f"✗ Unexpected MQTT disconnect (code {rc}), will auto-reconnect...")

def on_message(client, userdata, msg):
    global pan_pos, tilt_pos
    command = msg.payload.decode()

    if msg.topic.endswith("pan"):
        if command == "left": pan_pos = max(MIN, pan_pos - 100)
        if command == "right": pan_pos = min(MAX, pan_pos + 100)
        set_servo(PAN_PIN, pan_pos)

    if msg.topic.endswith("tilt"):
        if command == "up": tilt_pos = max(MIN, tilt_pos - 100)
        if command == "down": tilt_pos = min(MAX, tilt_pos + 100)
        set_servo(TILT_PIN, tilt_pos)

def main():
    global client
    
    # Initialize pigpio
    if not init_pigpio():
        sys.exit(1)
    
    # Initialize MQTT client with automatic reconnection
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_disconnect = on_disconnect
    client.on_message = on_message
    
    # Enable automatic reconnection
    retry_count = 0
    max_retries = 30
    connected = False
    
    while retry_count < max_retries and not connected:
        try:
            print(f"Connecting to MQTT broker (attempt {retry_count + 1}/{max_retries})...")
            client.connect("localhost", 1883, 60)
            connected = True
        except Exception as e:
            print(f"✗ MQTT connection error: {e}")
            retry_count += 1
            if retry_count < max_retries:
                time.sleep(2)
    
    if not connected:
        print("Failed to connect to MQTT broker after multiple attempts")
        sys.exit(1)
    
    # Start MQTT loop (will auto-reconnect on disconnect)
    print("✓ Pan-Tilt controller ready")
    client.loop_forever()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nShutting down...")
        if pi:
            pi.stop()
        sys.exit(0)