# PAI Docker Deployment

This setup allows you to deploy Personal AI Infrastructure (PAI) on any server running Docker, including Coolify.

## Features
- **Web-based Terminal**: Access PAI via your browser on port 8082 (powered by `ttyd`).
- **SSH Access**: Connect directly via SSH using the `pai` user.
- **Voice Server**: Background voice notification server on port 8888.
- **Persistent Memory**: Your AI's memory and user files are stored in Docker volumes.
- **Universal Configuration**: One Docker Compose for Public, VPN, or Private modes.

## Deployment on Coolify

1. **New Application**: Select "Public Repository" or "Docker Compose".
2. **Repository**: Use your fork of this repository.
3. **Docker Compose Path**: Set this to `Docker/docker-compose.yml`.
4. **Environment Variables**: Coolify will auto-detect the variables. Fill in your API keys, identity preferences, and **`PAI_PASSWORD`** for SSH access.

## 🔑 SSH Access
You can connect to the container via SSH:
- **User**: `pai`
- **Password**: (The value of `PAI_PASSWORD`)
- **Default Port**: `2222` (Configurable via `SSH_PORT`)

```bash
ssh pai@<your-server-ip> -p 2222
```

## 🔒 Deployment Modes (Switch via Environment Variables)

Choose your desired security level by setting these variables in the Coolify dashboard.

### Scenario A: Public (Domain + SSL)
Access via a custom domain. Ports are hidden from the public IP (Default).
- `BIND_IP`: `127.0.0.1` (Default)
- `TRAEFIK_ENABLE`: `true`
- `FQDN`: `pai.yourdomain.com`
- `VPN_SUBNET`: `0.0.0.0/0` (Explicitly Allow All)

### Scenario B: VPN Restricted (Domain + SSL) - **Recommended**
Access via a custom domain, but Traefik blocks anyone not on your VPN.
- `BIND_IP`: `127.0.0.1` (Default)
- `TRAEFIK_ENABLE`: `true`
- `FQDN`: `pai.yourdomain.com`
- `VPN_SUBNET`: `10.8.0.0/24` (Your WireGuard subnet)

### Scenario C: VPN Only (Direct IP)
No domain or SSL. Only accessible via the server's internal VPN IP.
- `BIND_IP`: `10.8.0.1` (Your server's WireGuard IP)
- `TRAEFIK_ENABLE`: `false`
- Access via: `http://10.8.0.1:8082`

### Scenario D: Standard Public (Exposed Ports) - **NOT RECOMMENDED**
If you want to access via IP and port directly over the public internet. This exposes your PAI instance to the open web without SSL.
- `BIND_IP`: `0.0.0.0`
- `TRAEFIK_ENABLE`: `false`
- Access via: `http://<public-ip>:8082`

## Core Environment Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `BIND_IP` | Interface IP to bind to | `127.0.0.1` |
| `BIND_PORT` | Port for the terminal | `8082` |
| `SSH_PORT` | Port for SSH access | `2222` |
| `VPN_SUBNET` | IP Allowlist for Traefik | `127.0.0.1/32` |
| `FQDN` | FQDN for Traefik | `localhost` |
| `PAI_PASSWORD` | Password for user `pai` | (None) |
| `ANTHROPIC_API_KEY` | Your Claude API key | (None) |
| `ELEVENLABS_API_KEY` | Your ElevenLabs API key | (None) |
| `PRINCIPAL_NAME` | Your name | `User` |
| `AI_NAME` | Assistant's name | `PAI` |
| `TIMEZONE` | e.g., `Europe/Berlin` | `UTC` |

## Persistence
The following directories are persisted:
- `/home/pai/.claude/MEMORY`: AI's learned signals and session history.
- `/home/pai/.claude/USER`: Your personal configuration and project files.
- `/home/pai/.config/PAI`: API keys and core settings.

## Usage in Terminal
Once you open the web terminal or SSH in:
1. Run `pai` to launch the PAI assistant.
2. The first time you run it, you may need to log in to Claude Code if you didn't provide an API key in the environment.
