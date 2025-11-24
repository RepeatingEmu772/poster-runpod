FROM runpod/pytorch:2.1.1-py3.10-cuda12.1.1-devel-ubuntu22.04

# Build timestamp to force cache invalidation: 2025-11-24
ENV MODEL_NAME="Qwen/Qwen2.5-VL-7B-Instruct"
ENV MAX_MODEL_LEN=8192
ENV GPU_MEMORY_UTILIZATION=0.85

# Install vLLM and dependencies
RUN pip install --no-cache-dir vllm==0.6.3 transformers==4.46.0

COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

COPY handler.py /app/handler.py
COPY start.py /app/start.py

WORKDIR /app

CMD ["python3", "/app/start.py"]