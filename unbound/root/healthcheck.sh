#!/bin/sh

### Environment variables

HEALTHCHECK_PORT="${HEALTHCHECK_PORT:-5335}"
EXTENDED_HEALTHCHECK="${EXTENDED_HEALTHCHECK:-false}"
EXTENDED_HEALTHCHECK_DOMAIN="${EXTENDED_HEALTHCHECK_DOMAIN:-nlnetlabs.nl}"
ENABLE_STATS="${ENABLE_STATS:-false}"

### Unbound Statistics

if [ "$ENABLE_STATS" = "true" ]; then
    unbound_root="/usr/local/unbound"

    rawfile="$unbound_root/log.d/unbound_stats"
    tmpfile="$unbound_root/log.d/unbound_stats.tmp"
    logfile="$unbound_root/log.d/unbound-stats.log"

    # Run unbound-control and create file with statistics
    "$unbound_root/unbound.d/sbin/unbound-control" stats_noreset > "$rawfile" 2>/dev/null

    sed -E '/(histogram|thread)/d' "$rawfile" > "$tmpfile"

    # Convert multiline to single line, comma-separated
    awk -v RS="" -v OFS="," '{$1=$1}1' "$tmpfile" > "$logfile"
fi

### Healthcheck

# Count open TCP/UDP ports
check_port="$(netstat -ln 2>/dev/null | grep -c ":$HEALTHCHECK_PORT")"

if [ "$check_port" -eq 0 ]; then
    echo "⚠️ Port $HEALTHCHECK_PORT not open"
    exit 1
else
    echo "✅ Port $HEALTHCHECK_PORT open"
fi

# Exit early if extended check disabled
if [ "$EXTENDED_HEALTHCHECK" != "true" ]; then
    exit 0
fi

### Extended healthcheck

ip="$(drill -Q -p "$HEALTHCHECK_PORT" "$EXTENDED_HEALTHCHECK_DOMAIN" @127.0.0.1 2>/dev/null)"

# Check exit code AND empty output
if [ $? -ne 0 ] || [ -z "$ip" ]; then
    echo "⚠️ Domain '$EXTENDED_HEALTHCHECK_DOMAIN' not resolved"
    exit 1
else
    echo "✅️ Domain '$EXTENDED_HEALTHCHECK_DOMAIN' resolved to '$ip'"
    exit 0
fi
