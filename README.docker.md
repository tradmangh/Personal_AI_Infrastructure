# PAI Docker Deployment

This setup allows you to deploy Personal AI Infrastructure (PAI) on any server running Docker, including Coolify.

## Features
- **Web-based Terminal**: Access PAI via your browser on port 8080 (powered by `ttyd`).
- **Voice Server**: Background voice notification server on port 8888.
- **Persistent Memory**: Your AI's memory and user files are stored in Docker volumes.
- **Universal Configuration**: One Docker Compose for Public, VPN, or Private modes.

## Deployment on Coolify

1. **New Application**: Select "Public Repository" or "Docker Compose".
2. **Repository**: Use your fork of this repository.
3. **Environment Variables**: Add your API keys and identity preferences.

## 🔒 Deployment Modes (Switch via Environment Variables)

Choose your desired security level by setting these variables in the Coolify dashboard.

### Scenario A: Public (Domain + SSL)
Access via a custom domain. Ports are hidden from the public IP.
- `BIND_IP`: `127.0.0.1`
- `TRAEFIK_ENABLE`: `true`
- `DOMAIN`: `pai.yourdomain.com`
- `VPN_SUBNET`: `0.0.0.0/0` (Allow All)

### Scenario B: VPN Restricted (Domain + SSL) - **Recommended**
Access via a custom domain, but Traefik blocks anyone not on your VPN.
- `BIND_IP`: `127.0.0.1`
- `TRAEFIK_ENABLE`: `true`
- `DOMAIN`: `pai.yourdomain.com`
- `VPN_SUBNET`: `10.8.0.0/24` (Your WireGuard subnet)

### Scenario C: VPN Only (Direct IP)
No domain or SSL. Only accessible via the server's internal VPN IP.
- `BIND_IP`: `10.8.0.1` (Your server's WireGuard IP)
- `TRAEFIK_ENABLE`: `false`
- Access via: `http://10.8.0.1:8080`

## Core Environment Variables
| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | Your Claude API key (Required) |
| `ELEVENLABS_API_KEY` | Your ElevenLabs API key (Optional) |
| `PRINCIPAL_NAME` | Your name |
| `AI_NAME` | Assistant's name (e.g., Jarvis) |
| `TIMEZONE` | e.g., `Europe/Berlin` |

## Persistence
The following directories are persisted:
- `/home/pai/.claude/MEMORY`: AI's learned signals and session history.
- `/home/pai/.claude/USER`: Your personal configuration and project files.
- `/home/pai/.config/PAI`: API keys and core settings.

## Usage in Terminal
Once you open the web terminal:
1. Run `pai` to launch the PAI assistant.
2. The first time you run it, you may need to log in to Claude Code if you didn't provide an API key in the environment.
