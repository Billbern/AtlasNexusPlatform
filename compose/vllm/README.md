# vLLM — Atlas Nexus

This directory contains the Docker Compose configuration for running [vLLM](https://github.com/vllm-project/vllm), a high-throughput, memory-efficient LLM serving engine with an OpenAI-compatible API.

---

## Quick Start

```bash
# From the project root
make vllm-up

# Or from this directory
docker compose up -d
```

The API will be available at `http://localhost:8000/v1`.

---

## Configuration

Edit `.env` in this directory to configure the vLLM instance:

| Variable | Default | Description |
|----------|---------|-------------|
| `CONTAINER_NAME` | `atlas-nexus-vllm` | Docker container name |
| `IMAGE` | `vllm/vllm-openai:latest` | vLLM Docker image tag |
| `HOST` | `0.0.0.0` | Bind address inside the container |
| `PORT` | `8000` | Host port (maps to container port 8000) |
| `MODEL` | `Qwen/Qwen3-8B` | Hugging Face model ID to serve |
| `HF_TOKEN` | *(empty)* | Hugging Face token for gated models |
| `DTYPE` | `auto` | Model precision (`auto`, `half`, `float16`, `bfloat16`) |
| `GPU_MEMORY_UTILIZATION` | `0.90` | Fraction of GPU memory to allocate |
| `MAX_MODEL_LEN` | `8192` | Maximum sequence length in tokens |
| `TRUST_REMOTE_CODE` | `true` | Allow remote code execution from Hugging Face |

---

## Commands

| Command | Description |
|---------|-------------|
| `make vllm-up` | Start vLLM in detached mode |
| `make vllm-down` | Stop and remove the container |
| `make vllm-restart` | Restart the container |
| `make vllm-logs` | Follow container logs |
| `make vllm-ps` | Show container status |
| `make vllm-pull` | Pull the latest vLLM image |

---

## Model Storage

Model weights are stored in `../../storage/models/` (mounted at `/models` inside the container). vLLM will download the model from Hugging Face on first startup and cache it here for subsequent runs.

---

## API Endpoints

Once running, vLLM exposes an OpenAI-compatible API:

| Endpoint | Description |
|----------|-------------|
| `GET /health` | Health check |
| `GET /v1/models` | List available models |
| `POST /v1/chat/completions` | Chat completions |
| `POST /v1/completions` | Text completions |

---

## Health Check

```bash
curl http://localhost:8000/health
```

Returns `{"status": "ok"}` when the server is ready to accept requests.

---

## Notes

- The container uses `ipc: host` and `shm_size: 8g` for optimal shared memory performance.
- NVIDIA GPU runtime is required (`runtime: nvidia`).
- The `--trust-remote-code` flag is enabled by default for Qwen models.