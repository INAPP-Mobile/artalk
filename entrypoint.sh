#!/bin/bash
# Artalk on Railway.
#
# - Maps Railway's injected PORT onto the server via ATK_PORT. The stock image
#   CMD hardcodes `--port 23366`, which Railway never routes to — and the
#   `--port` CLI flag is a DEAD flag in Artalk v2: cmd/server.go registers it
#   but nothing ever reads it; the server listens on app.Conf().Port, which
#   comes only from the config file (`port: 23366` in the generated
#   /data/artalk.yml) or the ATK_PORT env var (koanf loads env after the file,
#   so env wins). Passing --port alone changes nothing — proven by two
#   template-path installs that kept binding 23366 while the flag said 8080.
#   Exporting ATK_PORT is the only mechanism that moves the listen port.
# - Derives the default site's URL from the live RAILWAY_PUBLIC_DOMAIN. This is
#   only a placeholder: the site URL is the blog being commented on, and the
#   deployer replaces it with their real blog URL in the admin sidebar. It also
#   makes the Railway origin a trusted origin, so the admin sidebar (served
#   from this same domain) passes the server's CORS origin check.
# - Delegates to the stock entrypoint (/entrypoint.sh), which generates
#   /data/artalk.yml on first boot (including a random app_key, stable per
#   volume) and then runs `/artalk -w / -c /data/artalk.yml "$@"`.
set -e

# 8080 is Railway's default service port: a template install sets no PORT
# variable, and the healthcheck prober targets the default port. (Artalk's own
# default is 23366 — listening there while the prober targets 8080 fails the
# healthcheck with "service unavailable"; proven by the first two
# template-path installs, whose deployments FAILED after 11 failed attempts.)
PORT="${PORT:-8080}"
export ATK_PORT="$PORT"

if [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
  export ATK_SITE_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
fi

# --port is a dead flag (see above) but harmless to keep; ATK_PORT does the work.
exec /entrypoint.sh server --host 0.0.0.0 --port "$PORT"
