#!/usr/bin/env bash
# Time "fresh clone -> contributor ready" for this environment (option 3).
#
#   .flox/bench/contrib-ready.sh <label> [--wipe-gems] [--wipe-yarn-cache]
#
# Run from the checkout root. It resets the checkout to fresh-clone state
# (Nix packages stay in the store), then, in ONE activation (services stop
# when the activation that started them exits), times:
#   first activation (forem-bootstrap) -> services up and GET / == 200 -> one model spec
#
# It deletes .flox/cache, node_modules and .env in this checkout.
#   --wipe-gems        also empties the shared compiled-gem dir for this Ruby
#                      (~/.cache/forem-flox/gems/<ruby>), i.e. a first-ever checkout
#   --wipe-yarn-cache  uses an empty, isolated Yarn global folder instead of ~/.yarn
# Logs go to $BENCH_LOGDIR (default: a new temp dir).
set -u
label=${1:?label}; shift
logdir=${BENCH_LOGDIR:-$(mktemp -d)}; mkdir -p "$logdir"; log="$logdir/$label.log"
wipe_gems=0 wipe_yarn=0
for a in "$@"; do case $a in --wipe-gems) wipe_gems=1;; --wipe-yarn-cache) wipe_yarn=1;; esac; done
[ -f .flox/env/manifest.toml ] || { echo "run from the checkout root" >&2; exit 1; }
now() { perl -MTime::HiRes=time -e 'printf "%.1f", time'; }

FOREM_BOOTSTRAP=0 flox activate -c 'flox services stop' >/dev/null 2>&1
find .flox/cache -mindepth 1 -delete 2>/dev/null
find node_modules -delete 2>/dev/null
rm -f .env
if [ $wipe_gems = 1 ]; then
  g=$(FOREM_BOOTSTRAP=0 flox activate -c 'printf %s "$GEM_HOME"' 2>/dev/null)
  case "$g" in */forem-flox/gems/*) find "$g" -delete 2>/dev/null;; esac
fi
if [ $wipe_yarn = 1 ]; then
  export YARN_GLOBAL_FOLDER="$logdir/yarn-global-$label"
  find "$YARN_GLOBAL_FOLDER" -delete 2>/dev/null; mkdir -p "$YARN_GLOBAL_FOLDER"
fi

t0=$(now)
flox activate -c '
  now() { perl -MTime::HiRes=time -e "printf q(%.1f), time"; }
  echo "T_ACTIVATED $(now)"
  if [ ! -f "$FLOX_ENV_CACHE/bootstrap/ready" ]; then
    echo "bootstrap did not finish; logs in $FLOX_ENV_CACHE/bootstrap/"; exit 1
  fi
  flox services start >/dev/null 2>&1
  for i in $(seq 1 360); do
    c=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$PORT/" 2>/dev/null)
    [ "$c" = 200 ] && break; sleep 0.5
  done
  echo "http=$c"; echo "T_SERVED $(now)"
  bin/rspec spec/models/tag_spec.rb 2>&1 | grep -E "examples?, "
  echo "T_SPEC $(now)"
  flox services stop >/dev/null 2>&1
' > "$log" 2>&1; rc=$?
t1=$(awk '/^T_ACTIVATED/{print $2}' "$log"); t2=$(awk '/^T_SERVED/{print $2}' "$log"); t3=$(awk '/^T_SPEC/{print $2}' "$log")
if [ -z "$t2" ] || [ -z "$t3" ]; then
  printf '%-20s rc=%s FAILED after %.1f s (bootstrap did not finish)\n' "$label" "$rc" "$(echo "${t1:-$(now)}-$t0"|bc)"
  grep -E 'forem-bootstrap|failed' "$log" | tail -5; echo "log: $log"; exit 1
fi
printf '%-20s rc=%s bootstrap %6.1f s | services + GET / %5.1f s (%s) | first spec %5.1f s | total %6.1f s\n' \
  "$label" "$rc" "$(echo "$t1-$t0"|bc)" "$(echo "$t2-$t1"|bc)" "$(grep -o 'http=[0-9]*' "$log" | tail -1)" \
  "$(echo "$t3-$t2"|bc)" "$(echo "$t3-$t0"|bc)"
grep -E 'examples?, ' "$log" | tail -1
echo "log: $log"
