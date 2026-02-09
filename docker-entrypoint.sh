#!/bin/bash
set -e

CLAUDE_DIR="$HOME/.claude"
CREDENTIALS_FILE="$CLAUDE_DIR/.credentials.json"

mkdir -p "$CLAUDE_DIR"

# Seed Claude credentials from environment variables
if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
  echo "Seeding Claude credentials from CLAUDE_CODE_OAUTH_TOKEN..."
  # Use node to safely generate JSON (avoids shell injection via token value)
  node -e "
    const fs = require('fs');
    const data = {
      claudeAiOauth: {
        accessToken: process.env.CLAUDE_CODE_OAUTH_TOKEN,
        expiresAt: 9999999999999
      }
    };
    fs.writeFileSync(process.argv[1], JSON.stringify(data, null, 2));
  " "$CREDENTIALS_FILE"
elif [ -n "$ANTHROPIC_API_KEY" ]; then
  echo "ANTHROPIC_API_KEY is set — Claude SDK will use it from environment."
fi

exec "$@"
