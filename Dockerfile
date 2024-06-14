FROM alpine:latest
RUN apk add --no-cache inotify-tools jq coreutils curl
WORKDIR /app
COPY watch-and-extract.sh /app
RUN chmod +x /app/watch-and-extract.sh
CMD [ "/app/watch-and-extract.sh" ]
