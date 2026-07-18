# Atlas Nexus

> GPU-accelerated LLM serving infrastructure powered by vLLM.

Atlas Nexus provisions and manages a production-ready vLLM inference server on Ubuntu 22.04/24.04 with NVIDIA GPU acceleration. It handles everything from bare-metal host setup to container orchestration.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Atlas Nexus                       │
│                                                      │
│  ┌──────────────┐   ┌──────────────────────────┐    │
│  │  Host Setup   │   │     Docker Compose        │    │
│  │              │   │                          │    │
│  │  • Docker    │   │  ┌────────────────────┐  │    │
│  │  • Compose   │   │  │      vLLM          │  │    │
│  │  • NVIDIA    │   │  │  (LLM Serving)     │  │    │
│  │    Toolkit   │   │  └────────────────────┘  │    │
│  │  • GPU       │   │                          │    │
│  │    Runtime   │   │  Port 8000 → OpenAI API  │    │
│  └──────────────┘   └──────────────────────────┘    │
│                                                      │
│  ┌──────────────────────┐  ┌─────────────────────┐  │
│  │   Cloudflare Tunnel  │  │      Storage         │  │
│  │   (cloudflared)      │  │  ./storage/models/   │  │
│  │   trycloudflare.com  │  │  ← model weights     │  │
│  └──────────────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

---

## Prerequisites

| Requirement | Minimum |
|-------------|---------|
| OS | Ubuntu 22.04 or 24.04 |
| GPU | NVIDIA with 8 GB+ VRAM |
| Driver | NVIDIA driver with CUDA 12.x |
| RAM | 16 GB |
| Disk | 50 GB free |
| Internet | Required for first-time model download |

---

## Quick Start

### One-command setup

```bash
make bootstrap
```

This runs the full pipeline: host install → host check → storage init → vLLM start → health check → Cloudflare tunnel.

### Step-by-step

```bash
# 1. Install host dependencies (Docker, NVIDIA Toolkit, etc.)
sudo make host-install

# 2. Verify everything is ready
make host-check

# 3. Create storage directories
make storage-init

# 4. Start vLLM
make vllm-up

# 5. Check the logs
make vllm-logs
```

Once vLLM is running, the OpenAI-compatible API is available at:

```
http://<host-ip>:8000/v1
```

---

## Commands

### Host Management

| Command | Description |
|---------|-------------|
| `sudo make host-install` | Install Docker, Compose, NVIDIA Toolkit, and configure GPU runtime |
| `make host-check` | Verify host readiness (Docker, GPU, disk, RAM, internet) |
| `sudo make host-update` | Update system packages and show current versions |

### Storage

| Command | Description |
|---------|-------------|
| `make storage-init` | Create all required storage directories |

### vLLM

| Command | Description |
|---------|-------------|
| `make vllm-up` | Start vLLM container in detached mode |
| `make vllm-down` | Stop and remove the vLLM container |
| `make vllm-restart` | Restart the vLLM container |
| `make vllm-logs` | Follow vLLM container logs |
| `make vllm-ps` | Show vLLM container status |
| `make vllm-pull` | Pull the latest vLLM image |

### Bootstrap

| Command | Description |
|---------|-------------|
| `make bootstrap` | Run full provisioning pipeline (host → storage → vLLM → tunnel) |
| `make bootstrap --host --storage` | Run only host install and storage init |
| `make bootstrap --vllm --access` | Start vLLM and tunnel only |
| `make bootstrap --skip-check` | Skip host readiness check |

The bootstrap script is idempotent — it skips steps that are already complete. Use `--help` to see all options:

```bash
./scripts/bootstrap.sh --help
```

### Access (Cloudflare Tunnel)

| Command | Description |
|---------|-------------|
| `sudo make access-install` | Install cloudflared binary |
| `make access-up` | Start a Cloudflare Quick Tunnel to expose vLLM publicly |
| `make access-down` | Stop the Cloudflare tunnel |

The tunnel creates a temporary public URL (`https://*.trycloudflare.com`) that forwards to your local vLLM instance. This is useful for:

- Testing from external clients without exposing your IP
- Sharing access to the API temporarily
- Webhook integrations that need a public endpoint

After running `make access-up`, the public URL is printed to the console and saved to `runtime/cloudflared.url`.

> **Note:** Quick Tunnels are ephemeral. For a permanent tunnel, configure a named tunnel via `cloudflared tunnel create`.

---

## Configuration

All vLLM settings are in `compose/vllm/.env`:

| Variable | Default | Description |
|----------|---------|-------------|
| `CONTAINER_NAME` | `atlas-nexus-vllm` | Docker container name |
| `IMAGE` | `vllm/vllm-openai:latest` | vLLM Docker image |
| `HOST` | `0.0.0.0` | Bind address |
| `PORT` | `8000` | Host port mapping |
| `MODEL` | `Qwen/Qwen3-8B` | Hugging Face model ID |
| `HF_TOKEN` | *(empty)* | Hugging Face access token (for gated models) |
| `DTYPE` | `auto` | Model dtype (`auto`, `half`, `float16`, `bfloat16`) |
| `GPU_MEMORY_UTILIZATION` | `0.90` | Fraction of GPU memory to use |
| `MAX_MODEL_LEN` | `8192` | Maximum sequence length |
| `TRUST_REMOTE_CODE` | `true` | Allow remote code execution |

Copy `.env.example` to `.env` and edit as needed:

```bash
cp compose/vllm/.env.example compose/vllm/.env
```

> **Note:** `.env` is gitignored. Use `.env.example` as a template.

---

## Storage Layout

```
storage/
├── models/              # Model weight files (mounted into vLLM)
├── huggingface/         # Hugging Face cache
├── vllm/
│   ├── cache/           # vLLM internal cache
│   └── logs/            # vLLM logs
├── litellm/
│   ├── config/          # LiteLLM configuration
│   └── logs/            # LiteLLM logs
├── open-webui/
│   ├── data/            # Open WebUI data
│   └── logs/            # Open WebUI logs
├── postgres/            # PostgreSQL data
├── redis/               # Redis data
├── monitoring/
│   ├── prometheus/      # Prometheus data
│   └── grafana/         # Grafana data
└── backups/             # Backup destination
```

---

## API Usage

Once vLLM is running, you can interact with it using any OpenAI-compatible client:

```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-8B",
    "messages": [
      {"role": "user", "content": "Hello, how are you?"}
    ]
  }'
```

---

## Access Configuration

Access settings are in `configs/access.env`:

| Variable | Default | Description |
|----------|---------|-------------|
| `ACCESS_PROVIDER` | `cloudflare` | Tunnel provider |
| `ACCESS_MODE` | `quick` | Tunnel mode (`quick` or `production`) |
| `TARGET_HOST` | `localhost` | Local service host to expose |
| `TARGET_PORT` | `8000` | Local service port to expose |
| `CLOUDFLARED_BIN` | `cloudflared` | Cloudflared binary path |
| `PID_FILE` | `runtime/cloudflared.pid` | Process ID file |
| `LOG_FILE` | `runtime/cloudflared.log` | Tunnel log file |
| `URL_FILE` | `runtime/cloudflared.url` | Public URL file |

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `docker: nvidia-smi: command not found` | NVIDIA driver not installed | Run `sudo make host-install` |
| `docker: Error response from daemon: could not select device driver "nvidia"` | NVIDIA runtime not configured | Run `sudo nvidia-ctk runtime configure --runtime=docker && sudo systemctl restart docker` |
| vLLM container exits immediately | Out of GPU memory | Reduce `GPU_MEMORY_UTILIZATION` or `MAX_MODEL_LEN` in `.env` |
| `make host-check` fails on disk | Disk too full | Free up space (minimum 50 GB recommended) |
| Model fails to download | No internet or missing HF token | Set `HF_TOKEN` in `.env` for gated models |

---

## License

MIT