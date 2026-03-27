import asyncio
import websockets
import json
import serial
import time
import os
from dotenv import load_dotenv

load_dotenv()

SERIAL_PORT = os.getenv("SERIAL_PORT", "COM4")
BAUD_RATE = int(os.getenv("BAUD_RATE", "9600"))
WS_HOST = "0.0.0.0"
WS_PORT = 8765


def open_serial():
    """Open serial port, retrying until success."""
    while True:
        try:
            s = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
            time.sleep(2)
            print(f"Serial connected on {SERIAL_PORT}")
            return s
        except serial.SerialException as e:
            print(f"Serial open failed ({e}), retrying in 3s...")
            time.sleep(3)


arduino = open_serial()
clients = set()
latest_sensor_data = ""


# ---------------------- PARSE SENSOR LINE ----------------------
def parse_sensor_line(line):
    data = {}
    try:
        if not line.strip() or '|' not in line:
            return data

        key, value = line.split('|', 1)
        key = key.strip()
        value = value.strip()

        # Normalise Arduino key names to clean display names
        if key == "EC":                     key = "Electrical Conductivity (EC)"
        elif key.lower() == "ph":           key = "pH Level"
        elif key == "Nitrogen":             key = "Nitrogen (N)"
        elif key in ("Phosphorous",
                     "Phosphorus"):         key = "Phosphorus (P)"
        elif key == "Potassium":            key = "Potassium (K)"
        elif key == "Temperature":          key = "temperature"
        elif key == "Humidity":             key = "humidity"
        elif key == "Suggested Crop":       key = "Suggested Crop"

        data[key] = value
    except Exception as e:
        print(f"Error parsing line: {e}")
    return data


# ---------------------- HANDLE CLIENT ----------------------
async def handle_client(websocket):
    print(f"Client connected: {websocket.remote_address}")
    clients.add(websocket)
    try:
        async for message in websocket:
            # No client messages require a response from this server.
            pass
    except Exception as e:
        print(f"Client error: {e}")
    finally:
        clients.discard(websocket)
        print(f"Client disconnected: {websocket.remote_address}")


# ---------------------- BROADCAST DATA ----------------------
async def broadcast_sensor_data():
    global latest_sensor_data, arduino
    full_data = {}

    while True:
        try:
            if arduino.in_waiting:
                line = arduino.readline().decode('utf-8', errors='ignore').strip()
                print(f"Raw from Arduino: {line}")

                if '|' in line:
                    sensor_name, _ = line.split('|', 1)
                    data = parse_sensor_line(line)
                    if data:
                        full_data.update(data)

                    # Potassium is always the last key in the Arduino output cycle.
                    if sensor_name.strip() == 'Potassium':
                        await asyncio.sleep(5)
                        if full_data:
                            latest_sensor_data = ', '.join(
                                f"{k}: {v}" for k, v in full_data.items()
                            )
                            json_data = json.dumps(full_data)
                            print(f"Sending to clients: {json_data}")
                            for client in clients.copy():
                                try:
                                    await client.send(json_data)
                                except Exception:
                                    clients.discard(client)
                        full_data.clear()

        except serial.SerialException as e:
            print(f"Serial error: {e} — reconnecting...")
            full_data.clear()
            try:
                arduino.close()
            except Exception:
                pass
            await asyncio.sleep(2)
            loop = asyncio.get_event_loop()
            arduino = await loop.run_in_executor(None, open_serial)

        except Exception as e:
            print(f"Broadcast loop error (continuing): {e}")

        await asyncio.sleep(0.1)


# ---------------------- MAIN ----------------------
async def main():
    print(f"Starting WebSocket server on ws://{WS_HOST}:{WS_PORT}")
    async with websockets.serve(handle_client, WS_HOST, WS_PORT):
        await broadcast_sensor_data()


if __name__ == "__main__":
    asyncio.run(main())