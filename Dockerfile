FROM alpine

RUN apk add --no-cache --update openssl bash

COPY ssl-cert-check /
COPY entrypoint.sh /

# nobody:nobody
USER 65534:65534

CMD ["/entrypoint.sh"]
