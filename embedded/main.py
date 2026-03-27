import asyncio
import websockets
import json
import serial
import time
import os
from dotenv import load_dotenv

load_dotenv()

SERIAL_PORT = 'COM4'
BAUD_RATE = 9600

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

        # BUG FIX: "Phosphorous" (Arduino typo) → "Phosphorus (P)" (correct spelling)
        # All keys normalised here so the rest of the codebase uses clean names.
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
    # BUG FIX: removed the "GET_AI_SUGGESTION" / suggest_plants() block entirely.
    # AI recommendations are now handled exclusively by the FastAPI service
    # (get_recommendations.py).  The WebSocket server's only job is to stream
    # live sensor readings to the Flutter app.
    print(f"Client connected: {websocket.remote_address}")
    clients.add(websocket)
    try:
        async for message in websocket:
            # No client messages require a response from this server anymore.
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
                # errors='ignore' prevents UnicodeDecodeError from crashing the server
                line = arduino.readline().decode('utf-8', errors='ignore').strip()
                print(f"Raw from Arduino: {line}")

                if '|' in line:
                    sensor_name, _ = line.split('|', 1)
                    data = parse_sensor_line(line)
                    if data:
                        full_data.update(data)

                    # Potassium is always the last key in the Arduino output cycle.
                    # Wait 5 s to let any trailing bytes clear, then broadcast.
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
            # Hardware-level COM port error – close and reconnect without blocking asyncio.
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

        # Always yield to asyncio
        await asyncio.sleep(0.1)

# ---------------------- MAIN ----------------------
async def main():
    print("Starting WebSocket server on ws://0.0.0.0:8765")
    async with websockets.serve(handle_client, "0.0.0.0", 8765):
        await broadcast_sensor_data()

if __name__ == "__main__":
    asyncio.run(main())import asyncio
import websockets
import json
import serial
import time
import openai
import os
from dotenv import load_dotenv
#load_dotenv()
#api_token = os.getenv("API_KEY")

api_token = "api-key"
SERIAL_PORT = 'COM4'
BAUD_RATE = 9600

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

# ---------------------- ASYNC OPENAI SUGGESTION ----------------------
async def suggest_plants(sensor_data: str, api_token: str) -> str:
    client = openai.AsyncOpenAI(api_key=api_token)
    prompt = f"""
    You are a smart agriculture assistant.
    Based on the following soil data and context, suggest 2 to 3 suitable plants to grow.

    Soil data:
    {sensor_data}

    Context:
    Give short answers. I want you also to give short information for what the plant needs such as how many times should I water a plant etc.
    """

    try:
        response = await client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.3,
            max_tokens=300
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        return f"Error: {e}"

# ---------------------- PARSE SENSOR LINE ----------------------
def parse_sensor_line(line):
    data = {}
    try:
        if not line.strip() or '|' not in line:
            return data

        key, value = line.split('|', 1)
        key = key.strip()
        value = value.strip()

        if key == "EC": key = "Electrical Conductivity (EC)"
        elif key.lower() == "ph": key = "pH Level"
        elif key == "Nitrogen": key = "Nitrogen (N)"
        elif key == "Phosphorous": key = "Phosphorus (P)"
        elif key == "Potassium": key = "Potassium (K)"
        elif key == "Temperature": key = "temperature"
        elif key == "Humidity": key = "humidity"
        elif key == "Suggested Crop": key = "Suggested Crop"

        data[key] = value
    except Exception as e:
        print(f"Error parsing line: {e}")
    return data

# ---------------------- HANDLE CLIENT ----------------------
async def handle_client(websocket):
    global latest_sensor_data
    print(f"Client connected: {websocket.remote_address}")
    clients.add(websocket)
    try:
        async for message in websocket:
            if message == "GET_AI_SUGGESTION" and latest_sensor_data:
                suggestion = await suggest_plants(latest_sensor_data, api_token)
                await websocket.send(json.dumps({"ai_suggestion": suggestion}))
    except Exception as e:
        print(f"Client error: {e}")
    finally:
        clients.discard(websocket)  # discard never raises KeyError
        print(f"Client disconnected: {websocket.remote_address}")

# ---------------------- BROADCAST DATA ----------------------
async def broadcast_sensor_data():
    global latest_sensor_data, arduino
    full_data = {}

    while True:
        try:
            if arduino.in_waiting:
                # errors='ignore' prevents UnicodeDecodeError from crashing the server
                line = arduino.readline().decode('utf-8', errors='ignore').strip()
                print(f"Raw from Arduino: {line}")

                # No | means it's a header/separator line — skip processing but
                # still fall through to await asyncio.sleep to yield the event loop
                if '|' in line:
                    sensor_name, _ = line.split('|', 1)
                    data = parse_sensor_line(line)
                    if data:
                        full_data.update(data)

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
            # Hardware-level COM port error (e.g. ClearCommError, device disconnected)
            # Close the broken port and reconnect — runs in executor to avoid blocking asyncio
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

        # Always yield to asyncio — this is what was missing with `continue`
        await asyncio.sleep(0.1)

# ---------------------- MAIN ----------------------
async def main():
    print("Starting WebSocket server on ws://0.0.0.0:8765")
    async with websockets.serve(handle_client, "0.0.0.0", 8765):
        await broadcast_sensor_data()

if __name__ == "__main__":
    asyncio.run(main())
