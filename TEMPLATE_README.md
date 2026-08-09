# Deploy and Host ntfy on Railway

## About Hosting ntfy

ntfy is an HTTP-based pub/sub notification service with web, desktop, Android, and iOS clients. This template deploys a private-by-default ntfy `v2.27.0` server with persistent users, cached messages, and S3-compatible attachments.

## Common Use Cases

- Send deployment, monitoring, and automation alerts
- Run private notification topics for a team
- Integrate scripts with a simple HTTP publish API
- Self-host notification history and attachments

## Dependencies for ntfy Hosting

### Deployment Dependencies

The template creates the public **ntfy** service, one Railway Volume mounted at `/var/lib/ntfy`, and one private Railway Bucket. Bucket endpoint and credentials are cross-service references; do not replace them manually.

### Implementation Details

The ntfy service owns the public domain and exposes `/v1/health`. On first boot, the wrapper initializes ntfy's SQLite auth database on loopback, creates `NTFY_ADMIN_USER` with the generated `NTFY_ADMIN_PASSWORD`, and applies `deny-all` as the default policy. Subsequent boots detect the existing administrator. Attachments use the Bucket, while auth and cached messages use the volume.

There is no separate setup wizard. Sign in with the generated administrator variables, then create users and topic grants as needed. Mobile push uses `NTFY_UPSTREAM_BASE_URL`, which defaults to `https://ntfy.sh`; SMTP and Web Push remain optional post-deploy configuration.

### Why Deploy ntfy on Railway?

Railway provides HTTPS routing, persistent disk, private object storage, generated secrets, health checks, and source-based rebuilds in one deploy. The template keeps upstream ntfy pinned so upgrades remain deliberate and testable.
