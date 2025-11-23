FROM runpod/worker-v1-vllm:v2.5.0stable-cuda12.1.0

ENV MODEL_NAME="Qwen/Qwen2.5-VL-7B-Instruct"
ENV MAX_MODEL_LEN=8192
ENV GPU_MEMORY_UTILIZATION=0.95
# worker-vllm reads VLLM_ARGS if present and appends to vLLM launch
ENV VLLM_ARGS="--trust-remote-code"

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

COPY handler.py /app/handler.py

# vLLM server is started by base image entrypoint.
# We just run handler after vLLM comes up.
CMD ["python", "/app/handler.py"]


