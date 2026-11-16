#!/bin/bash
# Artalk on Railway.
#
# - Maps Railway's injected PORT onto the server. The stock image CMD hardcodes
#   `--port 23366`, which Railway never routes to — pass $PORT explicitly.
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
# healthcheck with "service unavailable"; proven by the first template-path
# install.)
PORT="${PORT:-8080}"

if [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
  export ATK_SITE_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
fi

exec /entrypoint.sh server --host 0.0.0.0 --port "$PORT"
