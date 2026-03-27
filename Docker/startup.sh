#!/bin/bash
set -e

# --- Configuration ---
PAI_DIR="/home/pai/.claude"
CONFIG_DIR="/home/pai/.config/PAI"
APP_DIR="/usr/local/pai"

# Fix permissions for persistent volumes
sudo chown -R pai:pai "/home/pai/.claude" 2>/dev/null || true
sudo chown -R pai:pai "/home/pai/.config" 2>/dev/null || true
sudo chown -R pai:pai "/home/pai/.local" 2>/dev/null || true

mkdir -p "$CONFIG_DIR"
mkdir -p "$PAI_DIR"
mkdir -p "/home/pai/.local/share"

# --- Claude Auth Persistence ---
# Claude Code stores its main auth/config at ~/.claude.json (outside the .claude dir)
if [ ! -L "/home/pai/.claude.json" ]; then
    if [ -f "/home/pai/.claude.json" ]; then
        mv "/home/pai/.claude.json" "$PAI_DIR/.claude.json"
    fi
    ln -snf "$PAI_DIR/.claude.json" "/home/pai/.claude.json"
fi

# --- SSH & User Setup ---
if [ -n "$PAI_PASSWORD" ]; then
    echo "pai:$PAI_PASSWORD" | sudo chpasswd
fi
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo /usr/sbin/sshd

# --- Code Sync Strategy ---
CODE_ITEMS=("PAI" "agents" "hooks" "lib" "skills" "VoiceServer" "CLAUDE.md" "CLAUDE.md.template" "statusline-command.sh")

for item in "${CODE_ITEMS[@]}"; do
    if [ -e "$APP_DIR/$item" ]; then
        ln -snf "$APP_DIR/$item" "$PAI_DIR/$item"
    fi
done

# Ensure persistent directories exist
mkdir -p "$PAI_DIR/MEMORY/STATE"
mkdir -p "$PAI_DIR/MEMORY/LEARNING"
mkdir -p "$PAI_DIR/MEMORY/WORK"
mkdir -p "$PAI_DIR/MEMORY/RELATIONSHIP"
mkdir -p "$PAI_DIR/MEMORY/VOICE"
mkdir -p "$PAI_DIR/USER"

# --- Environment Setup ---
PRINCIPAL_NAME="${PRINCIPAL_NAME:-User}"
TIMEZONE="${TIMEZONE:-UTC}"
AI_NAME="${AI_NAME:-PAI}"
CATCHPHRASE="${CATCHPHRASE:-Ready to go}"
TEMPERATURE_UNIT="${TEMPERATURE_UNIT:-fahrenheit}"
ELEVENLABS_VOICE_ID="${ELEVENLABS_VOICE_ID:-pNInz6obpgDQGcFmaJgB}"

# --- Generate .env ---
ENV_PATH="$CONFIG_DIR/.env"
echo "ELEVENLABS_API_KEY=${ELEVENLABS_API_KEY}" > "$ENV_PATH"
echo "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}" >> "$ENV_PATH"
chmod 600 "$ENV_PATH"

ln -sf "$ENV_PATH" "$PAI_DIR/.env"
ln -sf "$ENV_PATH" "/home/pai/.env"

# --- Patch settings.json ---
SETTINGS_PATH="$PAI_DIR/settings.json"
SETTINGS_STORE="$CONFIG_DIR/settings.json"

if [ ! -f "$SETTINGS_STORE" ]; then
    cp "$APP_DIR/settings.json" "$SETTINGS_STORE"
fi
ln -snf "$SETTINGS_STORE" "$SETTINGS_PATH"

# Update JSON via Python
python3 << EOF
import json
import os

path = "$SETTINGS_STORE"
with open(path, 'r') as f:
    data = json.load(f)

data['env'] = data.get('env', {})
data['env']['PAI_DIR'] = "$PAI_DIR"
data['env']['PAI_CONFIG_DIR'] = "$CONFIG_DIR"

data['principal'] = data.get('principal', {})
data['principal']['name'] = "$PRINCIPAL_NAME"
data['principal']['timezone'] = "$TIMEZONE"

data['daidentity'] = data.get('daidentity', {})
data['daidentity']['name'] = "$AI_NAME"
data['daidentity']['startupCatchphrase'] = "$CATCHPHRASE"

voice_id = "$ELEVENLABS_VOICE_ID"
data['daidentity']['voices'] = data['daidentity'].get('voices', {})
data['daidentity']['voices']['main'] = data['daidentity']['voices'].get('main', {})
data['daidentity']['voices']['main'].update({
    "voiceId": voice_id,
    "stability": 0.35,
    "similarityBoost": 0.80,
    "style": 0.90,
    "speed": 1.1
})
data['daidentity']['voices']['algorithm'] = data['daidentity']['voices'].get('algorithm', {})
data['daidentity']['voices']['algorithm'].update({
    "voiceId": voice_id,
    "stability": 0.35,
    "similarityBoost": 0.80,
    "style": 0.90,
    "speed": 1.1
})

data['preferences'] = data.get('preferences', {})
data['preferences']['temperatureUnit'] = "$TEMPERATURE_UNIT"

with open(path, 'w') as f:
    json.dump(data, f, indent=2)
EOF

# --- Shell Aliases ---
if ! grep -q "alias pai=" /home/pai/.bashrc; then
    echo "alias pai='bun $PAI_DIR/PAI/Tools/pai.ts'" >> /home/pai/.bashrc
    echo "export PATH=\$PATH:/home/pai/.bun/bin" >> /home/pai/.bashrc
fi

# --- Start VoiceServer ---
echo "Starting VoiceServer..."
cd "$PAI_DIR/VoiceServer"
bun run server.ts > /home/pai/voice-server.log 2>&1 &

# --- Start ttyd ---
PORT="${BIND_PORT:-8082}"
echo "Starting PAI Terminal on port $PORT..."
exec ttyd -W -p "$PORT" bash
