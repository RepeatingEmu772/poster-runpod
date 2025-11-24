#!/usr/bin/env python3
import os
import subprocess
import time
import requests
import sys

MODEL_NAME = os.environ.get("MODEL_NAME", "Qwen/Qwen2.5-VL-7B-Instruct")
MAX_MODEL_LEN = os.environ.get("MAX_MODEL_LEN", "8192")
GPU_MEMORY_UTILIZATION = os.environ.get("GPU_MEMORY_UTILIZATION", "0.85")

print("Starting vLLM server...")

# Start vLLM in background
vllm_process = subprocess.Popen([
    "python3", "-m", "vllm.entrypoints.openai.api_server",
    "--model", MODEL_NAME,
    "--trust-remote-code",
    "--dtype", "float16",
    "--max-model-len", MAX_MODEL_LEN,
    "--gpu-memory-utilization", GPU_MEMORY_UTILIZATION,
    "--host", "0.0.0.0",
    "--port", "8000"
], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

print(f"vLLM started with PID: {vllm_process.pid}")

# Wait for vLLM to be ready
print("Waiting for vLLM to be ready (max 300s)...")
for i in range(300):
    # Check if process is still alive
    if vllm_process.poll() is not None:
        print("ERROR: vLLM process died during startup!")
        print("vLLM output:")
        if vllm_process.stdout:
            print(vllm_process.stdout.read())
        sys.exit(1)
    
    # Check if server is responding
    try:
        response = requests.get("http://127.0.0.1:8000/v1/models", timeout=1)
        if response.status_code == 200:
            print(f"vLLM is ready after {i+1}s!")
            break
    except:
        pass
    
    if i == 299:
        print("ERROR: Timeout waiting for vLLM")
        sys.exit(1)
    
    time.sleep(1)

print("Starting RunPod handler...")
# Now start the handler
os.execvp("python3", ["python3", "/app/handler.py"])
