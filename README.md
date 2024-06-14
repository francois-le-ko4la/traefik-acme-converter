# traefik-acme-converter
Converts ACME certificates from Traefik into separate `fullchain` and `privkey` files for each domain.
You can send notifications through a Discord webhook to track the process.

This repository contains a Docker container designed to watch a given path for an ACME (Let's Encrypt) JSON file. It automatically extracts and decodes the full chain certificates and private keys for all domains specified in the JSON file using `jq` and `base64`.

## Build

Clone this repository and build the Docker image:

```bash
git clone https://github.com/francois-le-ko4la/traefik-acme-converter.git
cd traefik-acme-converter
docker build -t ko4la/traefik-acme-converter .
```

## Usage

### Environment Variables

You can specify several environment variables to customize the behavior:

- `WATCH_DIR`: The directory to watch for the ACME JSON file. Defaults to `/traefik/certs`. This directory must be used in your volume definition to see the Traefik json file.
- `OUTPUT_DIR`: The directory where the certificates and key files should be saved. Defaults to `/app/output`. This directory must be used in your volume definition to see the Traefik json file.
- `CERT_RESOLVER`: The resolver is responsible for retrieving certificates from an ACME server. Defaults to `myresolver`. 
- `PROVIDER`: Provider name. Defaults to `ACME`.
- `ACME_FILE_NAME`: Automatically constructed from the `PROVIDER` variable. Defaults to `ACME.json` (or `${PROVIDER}.json`). If your filename is different than `${PROVIDER}.json` you can define another filename.
- `WEBHOOK_URL`: The webhook url to send notifications (Discord)
- `USER_UID` / `USER_GID`

### Example

Below I give this traefik example with docker-compose file:
```yaml
version: '3'
services:
  traefik:
    container_name: traefik
    image: traefik:latest
    command:
      ...
      - --certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json
```

Your setup can also be done in a yaml setup :
```yaml
certificatesResolvers:
  myresolver:
    acme:
      email: your-email@example.com
      storage: acme.json
      httpChallenge:
        # used during the challenge
        entryPoint: web
        ....
```

In this example we define this docker-compose:
```yaml
version: '3'
services:
  traefik-acme-converter:
    container_name: traefik-acme-converter
    image: ko4la/traefik-acme-converter
    environment:
      - PROVIDER=acme                                     # PROVIDER = acme and ACME_FILE_NAME = acme.json
      - WEBHOOK_URL=${TRAEFIK_ACME_DISCORD_WH}            # Our discord webhook
      - USER_UID=0                                        # USER_UID
      - USER_GID=0                                        # USER_GID
    volumes:
      - /opt/traefik/letsencrypt:/traefik/letsencrypt:ro. # WATCH_DIR - our JSON is in /opt/traefik/letsencrypt
      - /etc/letsencrypt/live:/app/output                 # OUTPUT_DIR - we use /etc/letsencrypt to write our certificates
```

Start your container and check:
```sh
docker compose up -d traefik-acme-converter
docker logs traefik-acme-converter
```

Example of container logs:
```
2024-06-14T16:46:17+00:00 - INFO - Checking if acme.json exists...
2024-06-14T16:46:17+00:00 - INFO - acme.json found!
2024-06-14T16:46:17+00:00 - INFO - Starting initial certificate extraction...
2024-06-14T16:46:17+00:00 - INFO - Notification sent successfully.
2024-06-14T16:46:17+00:00 - INFO - Found XX certificates. Looping through all the domains...
2024-06-14T16:46:18+00:00 - INFO - Certificates for domain.local have been extracted.
2024-06-14T16:46:18+00:00 - INFO - Certificates for xx.domain.local have been extracted.
2024-06-14T16:46:19+00:00 - INFO - Waiting for modifications to acme.json...
2024-06-14T16:46:19+00:00 - INFO - Notification sent successfully.
Setting up watches.
Watches established.
```

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE.md](LICENSE.md) file for details.

---
