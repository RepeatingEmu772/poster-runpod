FROM runpod/worker-v1-vllm:v2.7.0stable-cuda12.1.0

# Build timestamp to force cache invalidation: 2025-11-24
ENV MODEL_NAME="Qwen/Qwen2.5-VL-7B-Instruct"
ENV MAX_MODEL_LEN=8192
ENV GPU_MEMORY_UTILIZATION=0.85
# worker-vllm reads VLLM_ARGS if present and appends to vLLM launch
ENV VLLM_ARGS="--trust-remote-code"

COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

COPY handler.py /app/handler.py

CMD ["bash", "-c", "set -x; \
  echo 'Starting vLLM...'; \
  python3 -m vllm.entrypoints.openai.api_server \
    --model ${MODEL_NAME} \
    --trust-remote-code \
    --dtype float16 \
    --max-model-len ${MAX_MODEL_LEN} \
    --gpu-memory-utilization ${GPU_MEMORY_UTILIZATION} \
    --host 0.0.0.0 \
    --port 8000 2>&1 | tee /tmp/vllm.log & \
  VLLM_PID=$!; \
  echo \"vLLM started with PID: $VLLM_PID\"; \
  echo 'Waiting for vLLM to be ready (max 180s)...'; \
  for i in {1..180}; do \
    if curl -s http://127.0.0.1:8000/v1/models >/dev/null 2>&1; then \
      echo \"vLLM is ready after ${i}s!\"; \
      break; \
    fi; \
    if ! kill -0 $VLLM_PID 2>/dev/null; then \
      echo 'ERROR: vLLM process died during startup!'; \
      echo 'Last 100 lines of vLLM log:'; \
      tail -100 /tmp/vllm.log; \
      exit 1; \
    fi; \
    sleep 1; \
  done; \
  echo 'vLLM is up! Starting handler...'; \
  exec python3 /app/handler.py"]