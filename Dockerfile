FROM binwiederhier/ntfy:v2.30.0@sha256:8563a39da2f5a47360618b2ab9200239c76b37f4145f6d627d9ab4368abd23f0

USER root
RUN apk add --no-cache jq

COPY entrypoint.sh /usr/local/bin/railway-entrypoint
RUN chmod 755 /usr/local/bin/railway-entrypoint

ENTRYPOINT ["/usr/local/bin/railway-entrypoint"]
