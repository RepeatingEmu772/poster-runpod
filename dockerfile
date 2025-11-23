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
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]