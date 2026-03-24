#!/bin/bash
set -e

# --- Configuration ---
PAI_DIR="/home/pai/.claude"
CONFIG_DIR="/home/pai/.config/PAI"
APP_DIR="/usr/local/pai"

mkdir -p "$CONFIG_DIR"
mkdir -p "$PAI_DIR"

# Symlink app files from APP_DIR to PAI_DIR
# These are the files that should NOT be in persistent volumes
for item in "$APP_DIR"/*; do
    base=$(basename "$item")
    if [ "$base" != "MEMORY" ] && [ "$base" != "USER" ]; then
        ln -snf "$item" "$PAI_DIR/$base"
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
# Default values if not provided
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

# Symlinks for .env
ln -sf "$ENV_PATH" "$PAI_DIR/.env"
ln -sf "$ENV_PATH" "/home/pai/.env"

# --- Patch settings.json ---
SETTINGS_PATH="$PAI_DIR/settings.json"

# Check if settings.json is already a symlink, if not, create it
if [ ! -L "$SETTINGS_PATH" ] && [ -f "$SETTINGS_PATH" ]; then
    rm "$SETTINGS_PATH"
fi
ln -snf "$APP_DIR/settings.json" "$SETTINGS_PATH"

# Wait, we need to modify settings.json, so it CANNOT be a symlink to a read-only APP_DIR
# We'll copy it from APP_DIR to CONFIG_DIR and symlink back
SETTINGS_STORE="$CONFIG_DIR/settings.json"
if [ ! -f "$SETTINGS_STORE" ]; then
    cp "$APP_DIR/settings.json" "$SETTINGS_STORE"
fi
ln -snf "$SETTINGS_STORE" "$SETTINGS_PATH"

# Use python to update JSON
python3 << EOF
import json
import os

path = "$SETTINGS_STORE"
with open(path, 'r') as f:
    data = json.load(f)

# Update environment
data['env'] = data.get('env', {})
data['env']['PAI_DIR'] = "$PAI_DIR"
data['env']['PAI_CONFIG_DIR'] = "$CONFIG_DIR"

# Update identity
data['principal'] = data.get('principal', {})
data['principal']['name'] = "$PRINCIPAL_NAME"
data['principal']['timezone'] = "$TIMEZONE"

data['daidentity'] = data.get('daidentity', {})
data['daidentity']['name'] = "$AI_NAME"
data['daidentity']['startupCatchphrase'] = "$CATCHPHRASE"

# Update voices
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

# --- Patch VoiceServer for Linux ---
# We can't patch directly in APP_DIR if it's read-only, so we'll copy VoiceServer to PAI_DIR
if [ ! -d "$PAI_DIR/VoiceServer" ] || [ -L "$PAI_DIR/VoiceServer" ]; then
    rm -rf "$PAI_DIR/VoiceServer"
    cp -r "$APP_DIR/VoiceServer" "$PAI_DIR/VoiceServer"
fi

VOICE_SERVER_TS="$PAI_DIR/VoiceServer/server.ts"
sed -i 's/\/usr\/bin\/afplay/mpg123/g' "$VOICE_SERVER_TS"
sed -i 's/-v/--gain/g' "$VOICE_SERVER_TS"

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
echo "Starting PAI Terminal on port 8080..."
exec ttyd -p 8080 bash
