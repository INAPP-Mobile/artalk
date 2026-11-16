# Artalk v2.10.1 — self-hosted comment system (ArtalkJS/Artalk, MIT).
#
# Upstream image pinned by manifest-list digest, WITHOUT a tag: Railpack
# 0.43.0 fails to detect a Dockerfile whose FROM carries both a tag and a
# digest, so redeploys die in the plan phase while the first deploy succeeds.
# The digest-only form builds under both builders. Version lives here in the
# comment: artalk/artalk-go:2.10.1, manifest list
# sha256:5616037f7b273b65cb583bedba1d7b5ec7c313828403daccf5849c36f70bf52c
# (amd64 sha256:377a17cfe431ba1f7c001b90795b82c0065458b7532b7887b60305e70aa1152c).
FROM artalk/artalk-go@sha256:5616037f7b273b65cb583bedba1d7b5ec7c313828403daccf5849c36f70bf52c

# The stock image carries no USER directive (it runs as root) — state it
# explicitly: Railway mounts persistent volumes root-owned, and a non-root
# user would crash-loop on EACCES writing /data.
USER root

# Baked defaults. These literals never appear on the one-click deploy form:
# English UI, UTC, the default site name, and the admin account identity
# (username admin, email admin@example.com). The admin PASSWORD is a generated
# secret — see template-vars.json. All three admin fields must be present
# together: with only the password set, Artalk silently creates no admin user
# (proven by the first template-path install, whose admin login 401'd with
# "User not found"). The site URL is derived at boot from the live
# RAILWAY_PUBLIC_DOMAIN by the entrypoint (never bake a
# ${{RAILWAY_PUBLIC_DOMAIN}} template expression — it resolves to a bare
# https:// on first deploy, before any domain exists).
ENV TZ=UTC \
    ATK_LOCALE=en \
    ATK_TIMEZONE=UTC \
    ATK_SITE_DEFAULT="Artalk Blog" \
    ATK_ADMIN_USERS_0_NAME=admin \
    ATK_ADMIN_USERS_0_EMAIL=admin@example.com

COPY entrypoint.sh /railway-entrypoint.sh
RUN chmod +x /railway-entrypoint.sh

# Config (artalk.yml), SQLite database (artalk.db) and uploads all live under
# /data, mounted as a Railway volume (do NOT add a Dockerfile VOLUME
# instruction — Railway's builder rejects it: "docker VOLUME ... is not
# supported, use Railway Volumes").

# The stock image CMD hardcodes --port 23366, which is exactly the bug that
# leaves the other Artalk template at 0% health (Railway routes to its
# injected PORT, not 23366). The entrypoint maps $PORT onto the server via
# ATK_PORT — NOT via the --port CLI flag, which is a dead flag in Artalk v2
# (registered in cmd/server.go, never read; the server listens on the config
# file's `port:` or ATK_PORT). When PORT is unset (a template install sets no
# PORT variable), it defaults to 8080 — Railway's healthcheck prober targets
# its default service port, and an app listening on Artalk's own 23366 default
# fails the probe with "service unavailable" until the 5-minute retry window
# expires (proven by the first two template-path installs: both bound 23366
# while the flag said 8080, both deployments FAILED; setting PORT=23366 on the
# first install made the prober target 23366 and the redeploy went Online).
EXPOSE 8080

# No CMD: the entrypoint execs the stock entrypoint with
# `server --host 0.0.0.0 --port $PORT` and exports ATK_PORT=$PORT (the
# --port flag is dead in Artalk v2; ATK_PORT is what moves the listen port).
ENTRYPOINT ["/railway-entrypoint.sh"]

LABEL org.opencontainers.image.source="https://github.com/INAPP-Mobile/artalk"
