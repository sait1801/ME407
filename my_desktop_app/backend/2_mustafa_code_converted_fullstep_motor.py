import time
import math
import board
import digitalio
import pwmio
from adafruit_motor import stepper
import wifi
import socketpool
# Constants
STEPS_PER_REV = 200  # steps per revolution
EXPOSURE_TIME = 1  # seconds
PROJECTION_WIDTH = 3.1  # mm
PROJECTION_HEIGHT = 2.4  # mm
TOTAL_WIDTH = 101.6  # mm
LEAD_SCREW_PITCH = 2  # mm

# Calculate maximum zone indices
zoneIndexXMax = math.ceil(TOTAL_WIDTH / PROJECTION_WIDTH)
zoneIndexYMax = math.ceil(TOTAL_WIDTH / PROJECTION_HEIGHT)

# Calculate steps for projection width and height
projectionWidthInSteps = int(
    PROJECTION_WIDTH * STEPS_PER_REV / LEAD_SCREW_PITCH)
projectionHeightInSteps = int(
    PROJECTION_HEIGHT * STEPS_PER_REV / LEAD_SCREW_PITCH)

# Initialize PWM outputs for stepper motors
pwmX_A1 = pwmio.PWMOut(board.GP0, frequency=1500)
pwmX_A2 = pwmio.PWMOut(board.GP1, frequency=1500)
pwmX_B1 = pwmio.PWMOut(board.GP2, frequency=1500)
pwmX_B2 = pwmio.PWMOut(board.GP3, frequency=1500)

pwmY_A1 = pwmio.PWMOut(board.GP4, frequency=1500)
pwmY_A2 = pwmio.PWMOut(board.GP5, frequency=1500)
pwmY_B1 = pwmio.PWMOut(board.GP6, frequency=1500)
pwmY_B2 = pwmio.PWMOut(board.GP7, frequency=1500)

# Initialize stepper motors
motorX = stepper.StepperMotor(pwmX_A1, pwmX_A2, pwmX_B1, pwmX_B2)
motorY = stepper.StepperMotor(pwmY_A1, pwmY_A2, pwmY_B1, pwmY_B2)

# Initialize end switches
endSwitchX = digitalio.DigitalInOut(board.GP26)
endSwitchX.direction = digitalio.Direction.INPUT
endSwitchX.pull = digitalio.Pull.UP

endSwitchY = digitalio.DigitalInOut(board.GP27)
endSwitchY.direction = digitalio.Direction.INPUT
endSwitchY.pull = digitalio.Pull.UP

# Global variables
absoluteX = 0
absoluteY = 0
zoneIndexX = 0
zoneIndexY = 0


def stepX(stepCount, direction):
    global absoluteX
    for _ in range(stepCount):
        motorX.onestep(direction=direction)
    absoluteX += stepCount if direction == stepper.FORWARD else -stepCount


def stepY(stepCount, direction):
    global absoluteY
    for _ in range(stepCount):
        motorY.onestep(direction=direction)
    absoluteY += stepCount if direction == stepper.FORWARD else -stepCount


def targetX(targetStep):
    global absoluteX
    if targetStep > absoluteX:
        stepX(targetStep - absoluteX, stepper.FORWARD)
    else:
        stepX(absoluteX - targetStep, stepper.BACKWARD)
    absoluteX = targetStep


def targetY(targetStep):
    global absoluteY
    if targetStep > absoluteY:
        stepY(targetStep - absoluteY, stepper.FORWARD)
    else:
        stepY(absoluteY - targetStep, stepper.BACKWARD)
    absoluteY = targetStep


def moveTo(targetZoneX, targetZoneY):
    targetX(targetZoneX * projectionWidthInSteps)
    targetY(targetZoneY * projectionHeightInSteps)


def loopThroughSubstrate():
    global zoneIndexX, zoneIndexY
    while zoneIndexY < zoneIndexYMax:
        while zoneIndexX < zoneIndexXMax:
            print(f"Moving to zone {zoneIndexX}, {zoneIndexY}")
            moveTo(zoneIndexX, zoneIndexY)
            print("Exposing...")
            time.sleep(EXPOSURE_TIME)
            zoneIndexX += 1
        zoneIndexX = 0
        zoneIndexY += 1


def calibrate():
    global absoluteX, absoluteY
    # Calibrate X axis
    print("Calibrating X until end switch is triggered.")
    while endSwitchX.value:
        stepX(10, stepper.BACKWARD)
    print("End switch is triggered, setting absolute angle to 0")
    absoluteX = 0

    # Calibrate Y axis
    print("Calibrating Y until end switch is triggered.")
    while endSwitchY.value:
        stepY(10, stepper.BACKWARD)
    print("End switch is triggered, setting absolute angle to 0")
    absoluteY = 0


def setup():
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

    print("Stepper test!")
    # calibrate() todo
    # loopThroughSubstrate() todo

    return server


# Run the setup function
server = setup()

# The loop function runs over and over again forever
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

    except OSError as e:
        print('Connection closed')
