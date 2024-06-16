#!/bin/sh

# Variables with default values
WATCH_DIR="/traefik/letsencrypt"
PROVIDER_NAME="${PROVIDER_NAME:-myresolver.acme}"
CERT_RESOLVER=${PROVIDER_NAME%.*} # myresolver
PROVIDER=${PROVIDER_NAME#*.} # acme
ACME_FILE_NAME="${ACME_FILE_NAME:-${PROVIDER}.json}"
OUTPUT_DIR="${OUTPUT_DIR:-/app/output}"
USER_UID="${USER_UID:-1000}"
USER_GID="${USER_GID:-1000}"
WEBHOOK_URL="${WEBHOOK_URL:-}"

# Error and log messages
ERR_FILE_NOT_FOUND="File ${ACME_FILE_NAME} not found. Skipping..."
ERR_CERT_NOT_FOUND="Certificate for domain %s not found. Skipping..."
ERR_NOTIFY="Failed to send notification. HTTP code:"
INFO_CERT_EXTRACTED="Certificates for %s have been extracted."
INFO_WAITING="Waiting for modifications to ${ACME_FILE_NAME}..."
INFO_MODIFIED="Modification detected. Refreshing certificates..."
INFO_CHECK_FILE="Checking if ${ACME_FILE_NAME} exists..."
INFO_FILE_FOUND="${ACME_FILE_NAME} found!"
INFO_LOOP_DOMAINS="Found %d certificates. Looping through all the domains..."
INFO_START="Starting initial certificate extraction..."
INFO_NOTIFY="Notification sent successfully."


# Logging function
log() {
  local SEV="$1"
  local MSG="$2"
  printf "%s - %s - %s\n" "$(date --iso-8601=seconds)" "$SEV" "$MSG"
}

# webhook notification
send_webhook_notification() {
    local WEBHOOK_URL="$1"
    local MESSAGE="$2"
    if [ -z "$WEBHOOK_URL" ]; then
        return 2
    fi

    # curl -H "Content-Type: application/json" -X POST -d "{\"username\":\"Traefik ACME Converter\", \"content\":\"$MESSAGE\"}" "$WEBHOOK_URL"
    HTTP_CODE=$(curl -H "Content-Type: application/json" -X POST -d "{\"username\":\"Traefik ACME Converter\", \"content\":\"$MESSAGE\"}" "$WEBHOOK_URL" -w "%{http_code}" -o /dev/null -s)

    if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 204 ]; then
        log "INFO" "$INFO_NOTIFY"
        return 0
    else
        log "ERROR" "$ERR_NOTIFY $HTTP_CODE"
        return 1
    fi
}

check_acme_file() {
  # Check if the ACME.json file exists in the watch directory
  log "INFO" "$INFO_CHECK_FILE"
  if [ -f "${WATCH_DIR}/${ACME_FILE_NAME}" ]; then
    log "INFO" "$INFO_FILE_FOUND"
  else
    log "ERROR" "$ERR_FILE_NOT_FOUND"
    exit 1
  fi
}

extract_certificates() {
  # Getting the length of the "Certificates" array for ${PROVIDER_NAME}
  CERTIFICATE_COUNT=$(jq -r ".${CERT_RESOLVER}.Certificates | length" "${WATCH_DIR}/${ACME_FILE_NAME}")

  log "INFO" "$(printf "$INFO_LOOP_DOMAINS" "$CERTIFICATE_COUNT")"
  for i in $(seq 0 $(($CERTIFICATE_COUNT - 1))); do
    DOMAIN=$(jq -r ".${CERT_RESOLVER}.Certificates[$i].domain.main" "${WATCH_DIR}/${ACME_FILE_NAME}")
    
    # Check if the domain starts with a wildcard and remove it
    if [ "${DOMAIN:0:2}" = "*." ]; then
      DOMAIN=${DOMAIN:2}
    fi
    
    FULLCHAIN=$(jq -r ".${CERT_RESOLVER}.Certificates[$i].certificate" "${WATCH_DIR}/${ACME_FILE_NAME}")
    PRIVKEY=$(jq -r ".${CERT_RESOLVER}.Certificates[$i].key" "${WATCH_DIR}/${ACME_FILE_NAME}")

    # Checking if jq returned anything
    if [ -z "$FULLCHAIN" ] || [ -z "$PRIVKEY" ]; then
      log "WARN" "$(printf "$ERR_CERT_NOT_FOUND" "$DOMAIN")"
    else
      # Creating output directory if it doesn't exist
      mkdir -p "${OUTPUT_DIR}/${DOMAIN}"

      # Saving the fullchain and privkey to files
      echo "$FULLCHAIN" | base64 -d > "${OUTPUT_DIR}/${DOMAIN}/fullchain.pem"
      echo "$PRIVKEY" | base64 -d > "${OUTPUT_DIR}/${DOMAIN}/privkey.pem"

      # Setting the appropriate file permissions
      chown ${USER_UID}:${USER_GID} ${OUTPUT_DIR}/${DOMAIN}/*
      chmod 600 ${OUTPUT_DIR}/${DOMAIN}/*

      log "INFO" "$(printf "$INFO_CERT_EXTRACTED" "$DOMAIN")"
    fi
  done
}


# check acme file
check_acme_file

# Initial extraction
log "INFO" "$INFO_START"
send_webhook_notification "$WEBHOOK_URL" "$INFO_START"
extract_certificates

# Loop indefinitely
while true; do
  # Use inotifywait to wait for the next modification to the ACME.json file
  log "INFO" "$INFO_WAITING"
  send_webhook_notification "$WEBHOOK_URL" "$INFO_WAITING"
  inotifywait -e modify "${WATCH_DIR}/${ACME_FILE_NAME}"

  # extract certificates after modification is detected
  log "INFO" "$INFO_MODIFIED"
  send_webhook_notification "$WEBHOOK_URL" "$INFO_MODIFIED"
  extract_certificates
done
