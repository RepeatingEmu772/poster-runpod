#!/bin/bash
set -x

# Function to start vLLM
start_vllm() {
  echo "Starting vLLM server..."
  python3 -m vllm.entrypoints.openai.api_server \
    --model "${MODEL_NAME}" \
    --trust-remote-code \
    --dtype float16 \
    --max-model-len "${MAX_MODEL_LEN}" \
    --gpu-memory-utilization "${GPU_MEMORY_UTILIZATION}" \
    --host 0.0.0.0 \
    --port 8000 \
    2>&1 | tee /tmp/vllm.log &
  
  VLLM_PID=$!
  echo "vLLM started with PID: $VLLM_PID"
  echo $VLLM_PID > /tmp/vllm.pid
}

# Function to check if vLLM is healthy
check_vllm() {
  curl -s http://127.0.0.1:8000/v1/models >/dev/null 2>&1
  return $?
}

# Start vLLM
start_vllm

# Wait for vLLM to be ready
echo "Waiting for vLLM to be ready..."
for i in {1..120}; do
  if check_vllm; then
    echo "vLLM is ready after ${i}s!"
    break
  fi
  
  # Check if process is still alive
  if ! kill -0 $(cat /tmp/vllm.pid 2>/dev/null) 2>/dev/null; then
    echo "ERROR: vLLM process died during startup!"
    echo "Last 100 lines of vLLM log:"
    tail -100 /tmp/vllm.log
    exit 1
  fi
  
  if [ $i -eq 120 ]; then
    echo "ERROR: vLLM not ready after 120s"
    echo "Last 100 lines of vLLM log:"
    tail -100 /tmp/vllm.log
    exit 1
  fi
  
  sleep 1
done

# Start vLLM health monitor in background
(
  while true; do
    sleep 5
    if ! kill -0 $(cat /tmp/vllm.pid 2>/dev/null) 2>/dev/null; then
      echo "WARNING: vLLM process died! Attempting restart..."
      start_vllm
      # Wait for it to be ready again
      for i in {1..60}; do
        if check_vllm; then
          echo "vLLM restarted successfully!"
          break
        fi
        sleep 1
      done
    fi
  done
) &

echo "Starting RunPod handler..."
exec python3 /app/handler.py
