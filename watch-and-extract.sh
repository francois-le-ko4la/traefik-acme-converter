#!/bin/sh

# Variables with default values
WATCH_DIR="${WATCH_DIR:-/traefik/certs}"
INTERVAL="${INTERVAL:-600}"
PROVIDER_PATH="${PROVIDER_PATH:-.cloudflare.Certificates[]}"
DOMAIN="${DOMAIN:-www.example.com}"
ACME_FILE_NAME="${ACME_FILE_NAME:-ACME.json}"
OUTPUT_DIR="${OUTPUT_DIR:-/app/output}"

# Loop indefinitely
while true; do

  # Check if the ACME.json file exists in the watch directory
  echo "Checking if \"${WATCH_DIR}/${ACME_FILE_NAME}\" exists..." 
  if [ -f "${WATCH_DIR}/${ACME_FILE_NAME}" ]; then

    echo "\"${WATCH_DIR}/${ACME_FILE_NAME}\" found!"

    echo "Extracting the fullchain and privkey using jq"
    FULLCHAIN=$(jq -r "${PROVIDER_PATH} | select(.domain.main==\"${DOMAIN}\").certificate" "${WATCH_DIR}/${ACME_FILE_NAME}")
    PRIVKEY=$(jq -r "${PROVIDER_PATH} | select(.domain.main==\"${DOMAIN}\").key" "${WATCH_DIR}/${ACME_FILE_NAME}")

    echo "Checking if jq returned anything"
    if [ -z "$FULLCHAIN" ] || [ -z "$PRIVKEY" ]; then
      echo "Certificate for domain ${DOMAIN} not found. Please try another domain name..."
      echo "Skipping..."
    else
      echo "Creating output directory if it doesn't exist..."
      mkdir -p "${OUTPUT_DIR}/${DOMAIN}"

      echo "Saving the fullchain and privkey to files..."
      echo "$FULLCHAIN" | base64 -d > "${OUTPUT_DIR}/${DOMAIN}/fullchain.pem"
      echo "$PRIVKEY" | base64 -d > "${OUTPUT_DIR}/${DOMAIN}/privkey.pem"
      echo "Certificates for ${DOMAIN} have been extracted."
    fi
  else
    echo "File ${WATCH_DIR}/${ACME_FILE_NAME} not found. Skipping..."
  fi

  # Sleep for the defined interval before the next iteration
  sleep ${INTERVAL}
done
