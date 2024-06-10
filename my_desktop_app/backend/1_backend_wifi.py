import wifi
import socketpool
import board
import digitalio

# Connect to WiFi
ssid = 'POCO X5 5G Sait'
password = 'ekmekkadayifi'

print("Connecting to WiFi...")
wifi.radio.connect(ssid, password)
print("Connected to WiFi:", wifi.radio.ipv4_address)

# Create a socket server
pool = socketpool.SocketPool(wifi.radio)
server = pool.socket(pool.AF_INET, pool.SOCK_STREAM)
server.bind(('0.0.0.0', 80))
server.listen(1)
print('Listening on', (wifi.radio.ipv4_address, 80))

# Function to handle received commands
def handle_command(command):
    if command == 'led_on':
        print("led_on")
    elif command == 'led_off':
        print("led_pff")
    # Add more command handling logic here

# Main loop
led = digitalio.DigitalInOut(board.LED)
led.direction = digitalio.Direction.OUTPUT

while True:
    try:
        print("Waiting for connection...")
        client, addr = server.accept()
        print('Client connected from', addr)
        
        with client:
            buffer = bytearray(1024)
            while True:
                num_bytes = client.recv_into(buffer)
                if num_bytes == 0:
                    break
                command = str(buffer[:num_bytes], 'utf-8')
                print('Received command:', command)
                handle_command(command)
                
    except OSError as e:
        print('Connection closed')

