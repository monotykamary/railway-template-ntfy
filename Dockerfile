FROM binwiederhier/ntfy:v2.33.1@sha256:29bc952294d58957f6ca6638eca9a653a33555989224edbdf4bb9433ee606497

USER root
RUN apk add --no-cache jq

COPY entrypoint.sh /usr/local/bin/railway-entrypoint
RUN chmod 755 /usr/local/bin/railway-entrypoint

ENTRYPOINT ["/usr/local/bin/railway-entrypoint"]
