FROM binwiederhier/ntfy:v2.32.0@sha256:59250e1d8be2ee2186c4560322f625faef22ace380331f05b63f8842dbd62602

USER root
RUN apk add --no-cache jq

COPY entrypoint.sh /usr/local/bin/railway-entrypoint
RUN chmod 755 /usr/local/bin/railway-entrypoint

ENTRYPOINT ["/usr/local/bin/railway-entrypoint"]
