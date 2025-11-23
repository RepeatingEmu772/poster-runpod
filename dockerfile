FROM runpod/worker-v1-vllm:v2.7.0stable-cuda12.1.0

ENV MODEL_NAME="Qwen/Qwen2.5-VL-7B-Instruct"
ENV MAX_MODEL_LEN=8192
ENV GPU_MEMORY_UTILIZATION=0.90
# worker-vllm reads VLLM_ARGS if present and appends to vLLM launch
ENV VLLM_ARGS="--trust-remote-code"

COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

COPY handler.py /app/handler.py

CMD ["bash", "-lc", "set -euo pipefail; set -x; \
  echo 'Starting vLLM...'; \
  python3 -m vllm.entrypoints.openai.api_server \
    --model ${MODEL_NAME} \
    --trust-remote-code \
    --dtype float16 \
    --max-model-len ${MAX_MODEL_LEN} \
    --gpu-memory-utilization ${GPU_MEMORY_UTILIZATION} \
    --host 0.0.0.0 \
    --port 8000 & \
  echo 'Waiting for vLLM...'; \
  python3 -c \"import time,urllib.request,sys; url='http://127.0.0.1:8000/v1/models'; ok=False; \
for i in range(90): \
  try: r=urllib.request.urlopen(url,timeout=1); ok=(getattr(r,'status',200)==200); \
  except Exception: pass; \
  time.sleep(1); \
sys.exit(0 if ok else 1)\"; \
  echo 'vLLM up; starting handler...'; \
  exec python3 /app/handler.py"]