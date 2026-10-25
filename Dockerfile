FROM binwiederhier/ntfy:v2.34.0@sha256:901e14503d3f605f445be0e68f2ac71f0aa73391897ce6ceb599f8c48d8b3792

USER root
RUN apk add --no-cache jq

COPY entrypoint.sh /usr/local/bin/railway-entrypoint
RUN chmod 755 /usr/local/bin/railway-entrypoint

ENTRYPOINT ["/usr/local/bin/railway-entrypoint"]
