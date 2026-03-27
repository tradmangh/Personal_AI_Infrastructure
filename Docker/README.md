# PAI Docker Deployment

This setup allows you to deploy Personal AI Infrastructure (PAI) on any server running Docker, including Coolify.

## Features
- **Web-based Terminal**: Access PAI via your browser on port 8082 (powered by `ttyd`).
- **SSH Access**: Connect directly via SSH using the `pai` user.
- **Voice Server**: Background voice notification server on port 8888.
- **Persistent Memory**: Your sessions and AI memories are stored in Docker volumes.
- **Healthcheck**: Coolify automatically monitors the container status.

## Deployment on Coolify

1. **New Application**: Select "Public Repository" or "Docker Compose".
2. **Repository**: Use your fork of this repository.
3. **Docker Compose Path**: Set this to `Docker/docker-compose.yml`.
4. **Environment Variables**: Coolify will auto-detect the variables. Fill in your API keys, identity preferences, and **`PAI_PASSWORD`** for SSH access.
5. **Domains**: In the Coolify UI, set your domain (e.g., `https://pai.yourdomain.com`) and map it to port **`8082`**.

## 🔒 Security Modes (Switch via Environment Variables)

### Scenario A: Local/VPN Access (Direct IP)
The terminal is only accessible via the server's internal VPN IP.
- `BIND_IP`: `10.8.0.1` (Your server's WireGuard IP)
- Access via: `http://10.8.0.1:8082`

### Scenario B: Public Access (Coolify Proxy)
Ports are hidden from the public IP, but accessible via your Coolify domain.
- `BIND_IP`: `127.0.0.1` (Default)
- Configure domain in Coolify dashboard pointing to port `8082`.

## Core Environment Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `BIND_IP` | Interface IP to bind to | `127.0.0.1` |
| `BIND_PORT` | Internal port for terminal | `8082` |
| `SSH_PORT` | External port for SSH access | `2222` |
| `PAI_PASSWORD` | Password for user `pai` | (None) |
| `ANTHROPIC_API_KEY` | Your Claude API key | (None) |
| `ELEVENLABS_API_KEY` | Your ElevenLabs API key | (None) |
| `PRINCIPAL_NAME` | Your name | `User` |
| `AI_NAME` | Assistant's name | `PAI` |
| `TIMEZONE` | e.g., `Europe/Berlin` | `UTC` |

## Persistence
The following directories are persisted:
- `/home/pai/.claude`: Sessions, auth tokens, and AI memories.
- `/home/pai/.config`: Global settings and API keys.

## Usage in Terminal
Once you open the web terminal or SSH in:
1. Run `pai` to launch the PAI assistant.
2. The first time you run it, you may need to log in to Claude Code if you didn't provide an API key in the environment.
