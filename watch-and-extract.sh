#!/bin/sh

# Variables with default values
WATCH_DIR="${WATCH_DIR:-/path/to/watch}"
INTERVAL="${INTERVAL:-30}"
PROVIDER_PATH="${PROVIDER_PATH:-.cloudflare.Certificates[]}"
DOMAIN="${DOMAIN:-www.example.com}"
ACME_FILE_NAME="${ACME_FILE_NAME:-ACME.json}"
OUTPUT_DIR="${OUTPUT_DIR:-/app/output}"

while :; do
  ACME_FILE_PATH="$WATCH_DIR/$ACME_FILE_NAME"
  DOMAIN_DIR="$OUTPUT_DIR/$DOMAIN"

  # Create output directory for domain if it does not exist
  mkdir -p "$DOMAIN_DIR"

  if [ -f "$ACME_FILE_PATH" ]; then
    # Extract and decode certificate
    cat "$ACME_FILE_PATH" | jq -r "$PROVIDER_PATH | select(.domain.main == \"$DOMAIN\").certificate" | base64 -d > "$DOMAIN_DIR/fullchain.pem"

    # Extract and decode private key
    cat "$ACME_FILE_PATH" | jq -r "$PROVIDER_PATH | select(.domain.main == \"$DOMAIN\").key" | base64 -d > "$DOMAIN_DIR/privatekey.pem"

    echo "Extracted certificate and key for $DOMAIN to $DOMAIN_DIR"
  else
    echo "$ACME_FILE_PATH not found. Waiting..."
  fi

  sleep $INTERVAL
done
