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
# English UI, UTC, and the default site name. The admin account itself comes
# from ATK_ADMIN_USERS_0_* service variables (the password is a generated
# secret — see template-vars.json). The site URL is derived at boot from the
# live RAILWAY_PUBLIC_DOMAIN by the entrypoint (never bake a
# ${{RAILWAY_PUBLIC_DOMAIN}} template expression — it resolves to a bare
# https:// on first deploy, before any domain exists).
ENV TZ=UTC \
    ATK_LOCALE=en \
    ATK_TIMEZONE=UTC \
    ATK_SITE_DEFAULT="Artalk Blog"

COPY entrypoint.sh /railway-entrypoint.sh
RUN chmod +x /railway-entrypoint.sh

# Config (artalk.yml), SQLite database (artalk.db) and uploads all live under
# /data; the stock image already declares VOLUME ["/data"].
VOLUME ["/data"]

EXPOSE 23366

# No CMD: the entrypoint execs the stock entrypoint with
# `server --host 0.0.0.0 --port $PORT`. The stock CMD hardcodes --port 23366,
# which is exactly the bug that leaves the other Artalk template at 0% health
# (Railway routes to its injected PORT, not 23366).
ENTRYPOINT ["/railway-entrypoint.sh"]

LABEL org.opencontainers.image.source="https://github.com/INAPP-Mobile/artalk"
