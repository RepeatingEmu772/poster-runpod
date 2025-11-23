import os, json, base64, io, requests, runpod
from PIL import Image

VLLM_URL = os.environ.get("VLLM_OPENAI_URL", "http://127.0.0.1:8000/v1/chat/completions")
MODEL_NAME = os.environ.get("MODEL_NAME", "Qwen/Qwen2.5-VL-7B-Instruct")

def _download_image(url: str) -> Image.Image:
    r = requests.get(url, timeout=20)
    r.raise_for_status()
    return Image.open(io.BytesIO(r.content)).convert("RGB")

def _image_to_data_url(img: Image.Image) -> str:
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    b64 = base64.b64encode(buf.getvalue()).decode("utf-8")
    return f"data:image/png;base64,{b64}"

def _build_prompt(job_input: dict) -> str:
    instr = job_input["instruction"]
    dims = job_input["canvasContext"]["dimensions"]
    img_bounds = job_input["canvasContext"]["existingImage"]["bounds"]
    existing_shapes = job_input["canvasContext"].get("existingShapes", [])

    return f"""
You are a layout assistant for a poster editor.

Task:
Given an image and an instruction, propose where to place new text on the canvas.

Canvas:
- width: {dims["width"]} px
- height: {dims["height"]} px

Existing main image bounds:
- x: {img_bounds["x"]}
- y: {img_bounds["y"]}
- width: {img_bounds["width"]}
- height: {img_bounds["height"]}

Existing shapes (may be empty):
{json.dumps(existing_shapes, ensure_ascii=False)}

Instruction:
{instr}

Return ONLY valid JSON of the form:
{{
  "success": true,
  "elements": [
    {{
      "type": "text",
      "content": "<text to add>",
      "position": {{ "x": <int>, "y": <int> }},
      "style": {{
        "fontSize": <int>,
        "fontWeight": "bold|normal",
        "color": "#RRGGBB",
        "fontFamily": "<family>"
      }},
      "bounds": {{ "width": <int>, "height": <int> }}
    }}
  ],
  "reasoning": "<one short sentence>"
}}

Rules:
- Place text in negative space, avoid overlapping salient subjects.
- Prefer top area if instruction says "top".
- Use high-contrast color relative to background.
- Pick one best placement.
""".strip()

def handler(job):
    job_input = job["input"]

    image_url = job_input["canvasContext"]["existingImage"]["url"]
    img = _download_image(image_url)
    data_url = _image_to_data_url(img)

    prompt = _build_prompt(job_input)

    payload = {
        "model": MODEL_NAME,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "image_url", "image_url": {"url": data_url}},
                    {"type": "text", "text": prompt}
                ]
            }
        ],
        "temperature": 0.2,
        "max_tokens": 400
    }

    resp = requests.post(VLLM_URL, json=payload, timeout=60)
    resp.raise_for_status()
    content = resp.json()["choices"][0]["message"]["content"].strip()

    # fallback
    try:
        return json.loads(content)
    except Exception:
        return {
            "success": False,
            "elements": [],
            "reasoning": "Model did not return valid JSON.",
            "raw": content
        }

runpod.serverless.start({"handler": handler})