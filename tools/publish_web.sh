#!/bin/bash
# Publishes the web client to the visor_isomer_releases GitHub Pages repo. NOT run
# automatically — publish deliberately.
#
#   tools/publish_web.sh <checkout of AttilaTheFun/visor_isomer_releases>
#
# Builds the site with -c opt (a fastbuild wasm overflows Safari's JS stack),
# copies it to the checkout's root beside the tiny shell (index.html), commits
# and pushes. Pages serves https://attilathefun.github.io/visor_isomer_releases/.
set -euo pipefail
CHECKOUT="${1:?visor_isomer_releases checkout}"
cd "$(dirname "$0")/.."
bazel build -c opt //applications/visor_web:visor_web_site
SITE="$(bazel cquery -c opt --output=files //applications/visor_web:visor_web_site 2>/dev/null | head -1)"
# preview/ holds a branch's build published beside the release (kept).
find "$CHECKOUT" -mindepth 1 -maxdepth 1 ! -name .git ! -name README.md ! -name preview -exec rm -rf {} +
cp -RL "$SITE"/. "$CHECKOUT"/
chmod -R u+w "$CHECKOUT"
touch "$CHECKOUT/.nojekyll"
cd "$CHECKOUT"
git add -A
git commit -qm "Publish web client $(date -u +%Y-%m-%dT%H:%M:%SZ) from visor $(git -C "$OLDPWD" rev-parse --short HEAD)"
git push
echo "pushed to $(git remote get-url origin)"
