#!/bin/sh
set -eu

require() {
  name="$1"
  eval "value=\${$name:-}"
  if [ -z "$value" ]; then
    printf 'Required variable %s is not set.\n' "$name" >&2
    exit 1
  fi
}

for name in \
  RAILWAY_PUBLIC_DOMAIN \
  NTFY_ADMIN_USER \
  NTFY_ADMIN_PASSWORD \
  S3_ENDPOINT \
  S3_ACCESS_KEY_ID \
  S3_SECRET_ACCESS_KEY \
  S3_BUCKET \
  S3_REGION
do
  require "$name"
done

case "$NTFY_ADMIN_USER" in
  *[!A-Za-z0-9._-]*|'')
    printf 'NTFY_ADMIN_USER may contain only letters, numbers, dot, underscore, and hyphen.\n' >&2
    exit 1
    ;;
esac

if [ "${#NTFY_ADMIN_PASSWORD}" -lt 16 ]; then
  printf 'NTFY_ADMIN_PASSWORD must contain at least 16 characters.\n' >&2
  exit 1
fi

urlencode() {
  jq -nr --arg value "$1" '$value | @uri'
}

S3_ENDPOINT=${S3_ENDPOINT:-}
S3_BUCKET=${S3_BUCKET:-}
S3_REGION=${S3_REGION:-}

s3_access_key="$(urlencode "$S3_ACCESS_KEY_ID")"
s3_secret_key="$(urlencode "$S3_SECRET_ACCESS_KEY")"
s3_endpoint="$(urlencode "$S3_ENDPOINT")"
s3_bucket="$(urlencode "$S3_BUCKET")"
s3_region="$(urlencode "$S3_REGION")"
admin_user="$NTFY_ADMIN_USER"
admin_password="$NTFY_ADMIN_PASSWORD"

: "${PORT:=80}"
: "${NTFY_UPSTREAM_BASE_URL:=https://ntfy.sh}"

export NTFY_LISTEN_HTTP=":${PORT}"
export NTFY_BASE_URL="${NTFY_BASE_URL:-https://${RAILWAY_PUBLIC_DOMAIN}}"
export NTFY_BEHIND_PROXY=true
export NTFY_AUTH_FILE=/var/lib/ntfy/user.db
export NTFY_AUTH_DEFAULT_ACCESS=deny-all
export NTFY_CACHE_FILE=/var/lib/ntfy/cache.db
export NTFY_ATTACHMENT_CACHE_DIR="s3://${s3_access_key}:${s3_secret_key}@${s3_bucket}/attachments?region=${s3_region}&endpoint=${s3_endpoint}&disable_http2=true"
export NTFY_UPSTREAM_BASE_URL

umask 077
cat >/tmp/ntfy-server.yml <<'EOF'
auth-file: /var/lib/ntfy/user.db
auth-default-access: deny-all
EOF
export NTFY_CONFIG_FILE=/tmp/ntfy-server.yml

unset NTFY_ADMIN_PASSWORD S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY

if [ ! -f "$NTFY_AUTH_FILE" ]; then
  NTFY_LISTEN_HTTP=127.0.0.1:19080 ntfy serve >/tmp/ntfy-bootstrap.log 2>&1 &
  bootstrap_pid=$!
  attempt=1
  until ntfy user list >/dev/null 2>&1; do
    if ! kill -0 "$bootstrap_pid" 2>/dev/null || [ "$attempt" -ge 60 ]; then
      printf 'Could not create the ntfy user database.
' >&2
      kill -TERM "$bootstrap_pid" 2>/dev/null || true
      wait "$bootstrap_pid" 2>/dev/null || true
      exit 1
    fi
    attempt=$((attempt + 1))
    sleep 1
  done
  kill -TERM "$bootstrap_pid" 2>/dev/null || true
  wait "$bootstrap_pid" 2>/dev/null || true
fi

attempt=1
while ! users="$(ntfy user list 2>/tmp/ntfy-user-list.err)"; do
  if [ "$attempt" -ge 60 ]; then
    printf 'Could not initialize the ntfy user database after 120 seconds.\n' >&2
    exit 1
  fi
  attempt=$((attempt + 1))
  sleep 2
done

if ! printf '%s\n' "$users" | grep -Fq "user ${admin_user} ("; then
  if ! NTFY_PASSWORD="$admin_password" ntfy user add --role=admin "$admin_user" >/dev/null 2>&1; then
    printf 'Could not create the initial ntfy administrator.\n' >&2
    exit 1
  fi
  printf 'Created the initial ntfy administrator %s.\n' "$admin_user"
else
  printf 'The ntfy administrator %s already exists.\n' "$admin_user"
fi

unset admin_password NTFY_ADMIN_USER
exec ntfy serve
