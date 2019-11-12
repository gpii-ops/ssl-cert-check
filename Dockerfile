FROM alpine

RUN apk add --update openssl bash curl && \
    rm -rf /var/cache/apk/*

COPY ssl-cert-check /
COPY entrypoint.sh /

RUN chmod +rx /entrypoint.sh ssl-cert-check

CMD ["/entrypoint.sh"]
