# traefik-acme-converter
Converts ACME certificates from Traefik into separated `fullchain` and `privkey`

This repository contains a Docker container designed to watch a given path for an ACME (Let's Encrypt) JSON file. It extracts and decodes the full chain certificate and private key for a specified domain using `jq` and `base64`.

## Prerequisites

- Docker installed on your machine.
- `jq` and `base64` are used within the Docker container, so no need to install those.

## Build

Clone this repository and build the Docker image:

```bash
git clone https://github.com/shobuprime/traefik-acme-converter.git
cd traefik-acme-converter
docker build -t shobuprime/traefik-acme-converter .
```

## Usage

Run the Docker container:

```bash
docker run -v /path/to/watch:/path/to/watch -e DOMAIN="example.com" shobuprime/traefik-acme-converter
```

### Environment Variables

You can specify several environment variables to customize the behavior:

- `WATCH_DIR`: The directory to watch for the ACME JSON file. Defaults to `/path/to/watch`.
- `INTERVAL`: Time in seconds between each check. Defaults to `30`.
- `PROVIDER_PATH`: jq path for your provider's certificates array. Defaults to `.cloudflare.Certificates[]`.
- `DOMAIN`: The domain for which to extract the certificate and key. Defaults to `www.example.com`.
- `ACME_FILE_NAME`: The name of the ACME JSON file. Defaults to `ACME.json`.
- `OUTPUT_DIR`: The directory where the certificate and key files should be saved. Defaults to /app/output.

### Example with Environment Variables

```bash
docker run \
  -e WATCH_DIR=/custom/dir \
  -e INTERVAL=10 \
  -e PROVIDER_PATH=".customProvider.Certificates[]" \
  -e DOMAIN="custom.example.com" \
  -e ACME_FILE_NAME="CustomACME.json" \
  -e OUTPUT_DIR="/custom/output" \
  -v /path/to/watch:/path/to/watch \
  -v /path/to/output:/custom/output \
  shobuprime/traefik-acme-converter
```

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE.md](LICENSE.md) file for details.

---