import pigpio
import paho.mqtt.client as mqtt

# Physical Pin 16 = GPIO 23 (Pan), Physical Pin 18 = GPIO 24 (Tilt)
PAN_PIN = 23
TILT_PIN = 24

pi = pigpio.pi('localhost', 9000)
pi.set_mode(PAN_PIN, pigpio.OUTPUT)
pi.set_mode(TILT_PIN, pigpio.OUTPUT)

MIN = 500
MAX = 2500

pan_pos = 1500
tilt_pos = 1500

def set_servo(pin, value):
    pi.set_servo_pulsewidth(pin, value)

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

client = mqtt.Client()
client.connect("homeassistant.local")
client.subscribe("pantilt/pan")
client.subscribe("pantilt/tilt")
client.on_message = on_message
client.loop_forever()