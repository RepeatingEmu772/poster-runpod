runpod serverless endpoint for poster-ui

this uses a VLM

env vars 
```
HF_MODEL_NAME=Qwen/Qwen2.5-VL-7B-Instruct
MODEL_NAME=Qwen/Qwen2.5-VL-7B-Instruct
MAX_MODEL_LEN=8192
GPU_MEMORY_UTILIZATION=0.95
```


sample request 

```
{
  "input": {
    "instruction": "add bold title 'Sweet Treats' at the top in white text",
    "canvasContext": {
      "dimensions": {
        "width": 1024,
        "height": 1024
      },
      "existingImage": {
        "url": "https://d2p7pge43lyniu.cloudfront.net/output/311dbcae-d485-4e7b-9579-b7735d97ffdb-u1_6ae3e5a8-44a2-410a-9338-17ef4fac6479.jpeg",
        "bounds": {
          "x": 112,
          "y": 112,
          "width": 800,
          "height": 800
        }
      },
      "existingShapes": [
        {
          "id": "shape:image123",
          "type": "image",
          "bounds": { "x": 112, "y": 112, "width": 800, "height": 800 }
        }
      ]
    }
  }
}
```


for curl
```bash
curl -X POST https://api.runpod.ai/v2/t9etsws45uhy7a/run \
    -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer YOUR_API_KEY' \
    -d '{
  "input": {
    "instruction": "add bold title '\''Sweet Treats'\'' at the top in white text",
    "canvasContext": {
      "dimensions": {
        "width": 1024,
        "height": 1024
      },
      "existingImage": {
        "url": "https://d2p7pge43lyniu.cloudfront.net/output/311dbcae-d485-4e7b-9579-b7735d97ffdb-u1_6ae3e5a8-44a2-410a-9338-17ef4fac6479.jpeg",
        "bounds": {
          "x": 112,
          "y": 112,
          "width": 800,
          "height": 800
        }
      },
      "existingShapes": [
        {
          "id": "shape:image123",
          "type": "image",
          "bounds": {
            "x": 112,
            "y": 112,
            "width": 800,
            "height": 800
          }
        }
      ]
    }
  }
}'
```
