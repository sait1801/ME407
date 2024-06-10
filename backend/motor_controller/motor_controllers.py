import time
import machine

# Define the pins for the stepper motor
dir_pin = machine.Pin(12, machine.Pin.OUT)
step_pin = machine.Pin(14, machine.Pin.OUT)

# Constants for the stepper motor
STEPS_PER_REV = 360  # Adjust this based on your motor's specification
STEP_DELAY = 2000  # Microseconds, adjust based on your motor's speed requirements

# PI Controller parameters
Kp = 0.1  # Proportional gain
Ki = 0.01  # Integral gain
integral = 0
previous_error = 0


def move_stepper(direction, steps, delay):
    dir_pin.value(direction)
    for _ in range(steps):
        step_pin.value(1)
        time.sleep_us(delay)
        step_pin.value(0)
        time.sleep_us(delay)


def calculate_steps(angle):
    # Calculate the number of steps for the given angle
    return int((angle / 360) * STEPS_PER_REV)


def pi_controller(target_angle, current_angle):
    global integral, previous_error
    error = target_angle - current_angle
    integral += error
    derivative = error - previous_error
    output = Kp * error + Ki * integral
    previous_error = error
    return output


# Main control loop
while True:
    target_angle = float(input("Enter the desired angle (0-360): "))
    if 0 <= target_angle <= 360:
        current_angle = 0  # This should be replaced with actual feedback if available
        control_signal = pi_controller(target_angle, current_angle)
        steps = calculate_steps(control_signal)
        direction = 1 if control_signal >= 0 else 0
        move_stepper(direction, abs(steps), STEP_DELAY)
        time.sleep(2)  # Wait for 2 seconds before the next input
    else:
        print("Invalid angle. Please enter a value between 0 and 360 degrees.")
