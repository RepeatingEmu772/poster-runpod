FROM runpod/worker-vllm:latest

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

COPY handler.py /app/handler.py

# vLLM server is started by base image entrypoint.
# We just run handler after vLLM comes up.
CMD ["python", "/app/handler.py"]