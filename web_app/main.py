import sys
import os
import contextlib
import io
import asyncio
import socket
import struct
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import time

# Ensure we can import beamng_edu from the parent directory
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    from beamng_edu import Carro
except ImportError:
    # Fallback if running from root
    sys.path.append(os.getcwd())
    from beamng_edu import Carro

app = FastAPI()

# Setup templates
templates = Jinja2Templates(directory="web_app/templates")

# Global lock to ensure single-student access
execution_lock = asyncio.Lock()

# Global Telemetry State
LATEST_TELEMETRY = {"speed": 0.0, "rpm": 0.0}

class CodeRequest(BaseModel):
    code: str
    pilot_name: str

def get_latest_telemetry():
    """Returns the current telemetry state."""
    return LATEST_TELEMETRY

async def telemetry_listener():
    """Background task to listen for UDP OutGauge packets."""
    UDP_IP = "0.0.0.0"
    UDP_PORT = 4444
    
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((UDP_IP, UDP_PORT))
    sock.setblocking(False)
    
    print(f"📡 Listening for OutGauge Telemetry on {UDP_IP}:{UDP_PORT}...")
    
    loop = asyncio.get_running_loop()
    
    while True:
        try:
            # Struct format based on standard OutGauge (96 bytes)
            # We only care about Speed (m/s) and RPM
            # C struct: time(I), car(4s), flags(H), gear(c), plid(c), speed(f), rpm(f), ...
            # Format: I 4s H c c f f ...
            # 4 + 4 + 2 + 1 + 1 = 12 bytes offset before Speed
            # Speed is float (4 bytes), RPM is float (4 bytes)
            
            data = await loop.sock_recv(sock, 1024)
            
            if len(data) >= 20: # Ensure we have enough data for speed/rpm
                # Unpack Speed (offset 12) and RPM (offset 16)
                # We use little-endian (<)
                # 12x means skip 12 bytes
                # f is float
                # f is float
                speed_ms, rpm_val = struct.unpack_from('<ff', data, 12)
                
                # Convert Speed m/s to km/h
                speed_kmh = speed_ms * 3.6
                
                LATEST_TELEMETRY["speed"] = round(speed_kmh, 1)
                LATEST_TELEMETRY["rpm"] = round(rpm_val, 0)
                
                # Debug logging (optional, maybe too verbose)
                # print(f"Telemetry: {speed_kmh} km/h, {rpm_val} RPM")
                
        except Exception as e:
            print(f"Telemetry Error: {e}")
            await asyncio.sleep(1)

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(telemetry_listener())

def run_student_code_sync(code_str: str, pilot_name: str):
    """
    Synchronous function to execute student code.
    Connects to the car, runs the code, captures output, and disconnects.
    """
    output_buffer = io.StringIO()
    
    # Redirect stdout to capture all prints, including those from Carro class
    with contextlib.redirect_stdout(output_buffer):
        print(f"🚗 PILOT {pilot_name} is driving...")
        carro = None
        try:
            # Connect to Host
            try:
                carro = Carro(ip="host.docker.internal", porta=65432)
                # Inject Telemetry Callback
                carro.set_telemetry_source(get_latest_telemetry)
                
            except Exception as e:
                print(f"Error connecting to BeamNG Server: {str(e)}")
                print("Ensure the server.exe is running on the host.")
                return output_buffer.getvalue()

            # Preparing the execution environment
            # We inject 'carro' and 'time'. 'print' is naturally captured by redirect_stdout.
            safe_globals = {
                "carro": carro,
                "time": time,
            }

            try:
                exec(code_str, safe_globals)
            except Exception as e:
                print(f"Error during execution: {str(e)}")
        finally:
            # Always disconnect to free up the socket
            if carro:
                try:
                    carro.desconectar()
                except:
                    pass

    return output_buffer.getvalue()

@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})

@app.get("/projector", response_class=HTMLResponse)
async def read_projector(request: Request):
    return templates.TemplateResponse("projector.html", {"request": request})

@app.post("/run")
async def run_code(request: CodeRequest):
    # Queue Logic: We use 'async with' to wait for the lock.
    # Requests will queue up here until the lock is available.
    async with execution_lock:
        try:
            # Run the blocking code execution in a separate thread so we don't block the async event loop
            loop = asyncio.get_running_loop()
            result = await loop.run_in_executor(None, run_student_code_sync, request.code, request.pilot_name)
            return {"status": "success", "output": result if result else "Execution finished (no output)."}
        except Exception as e:
            return {"status": "error", "output": f"Server Error: {str(e)}"}
