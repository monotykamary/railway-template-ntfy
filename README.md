# ntfy on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/ntfy-private-railway)

A secure, persistent [ntfy](https://ntfy.sh/) push-notification server for Railway. The wrapper pins ntfy `v2.27.0`, creates one administrator idempotently, denies anonymous topic access, stores auth and cached messages on a volume, and stores attachments in a Railway Bucket.

## Architecture

- **ntfy**: public web app and API; source-built from this repository.
- **Railway Volume** at `/var/lib/ntfy`: SQLite auth state and cached messages.
- **Railway Bucket**: S3-compatible attachment storage.

The ntfy service owns the public domain. The bucket is private and referenced through service variables; do not replace those references with copied validation credentials.

## After deployment

1. Open the generated ntfy domain.
2. Sign in with `NTFY_ADMIN_USER` and `NTFY_ADMIN_PASSWORD` from the ntfy service variables.
3. Create topic permissions for additional users with the ntfy access-control commands or API.
4. Point ntfy clients at the generated HTTPS domain.

Anonymous publish and subscribe are disabled by `deny-all`. The default `NTFY_UPSTREAM_BASE_URL=https://ntfy.sh` enables mobile push forwarding without embedding Firebase credentials in this template.

## Important limitations

- Mobile instant delivery depends on the configured upstream relay. Self-hosted Firebase/APNs credentials are not included.
- SMTP, Web Push VAPID keys, and custom TLS termination are optional upstream features and are not preconfigured.
- Bucket attachments and the local message cache have independent retention behavior; review ntfy retention settings before production use.
- Keep the volume mounted at `/var/lib/ntfy`; moving it loses users and cached messages.

## Updating

Update the ntfy tag and immutable digest in `Dockerfile`, rebuild, then test health, authenticated publish/poll, attachment upload/download, and a restart with the existing volume. GitHub-source auto-deploys update this wrapper only; the pinned upstream image never changes implicitly.

## Upstream

- Source: https://github.com/binwiederhier/ntfy
- Documentation: https://docs.ntfy.sh/
- Release: https://github.com/binwiederhier/ntfy/releases/tag/v2.27.0
- License: [Apache License 2.0](LICENSE)
