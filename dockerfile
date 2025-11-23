FROM runpod/worker-v1-vllm:stable-cuda12.4.0

ENV MODEL_NAME="Qwen/Qwen2.5-VL-7B-Instruct"
ENV MAX_MODEL_LEN=8192
ENV GPU_MEMORY_UTILIZATION=0.90
# worker-vllm reads VLLM_ARGS if present and appends to vLLM launch
ENV VLLM_ARGS="--trust-remote-code"

COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

COPY handler.py /app/handler.py

# Start vLLM OpenAI server in the background, wait for it, then start the Runpod handler.
# We do this explicitly because overriding CMD can prevent the base image's vLLM launch.
CMD ["bash", "-lc", "python3 -m vllm.entrypoints.openai.api_server --model ${MODEL_NAME} --trust-remote-code --dtype float16 --max-model-len ${MAX_MODEL_LEN} --gpu-memory-utilization ${GPU_MEMORY_UTILIZATION} --host 0.0.0.0 --port 8000 & \
  echo 'Waiting for vLLM...'; \
  python3 - <<'PY' \
import time, urllib.request
url='http://127.0.0.1:8000/v1/models'
for i in range(60):
    try:
        with urllib.request.urlopen(url, timeout=1) as r:
            if r.status == 200:
                print('vLLM is up')
                raise SystemExit(0)
    except Exception:
        time.sleep(1)
print('vLLM did not start in time')
raise SystemExit(1)
PY \
  && echo 'Starting handler...' \
  && python3 /app/handler.py"]
