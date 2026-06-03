#!/bin/sh
set -euo pipefail

unbound_root="/usr/local/unbound"

bi_white="$(printf '\033[1;97m')"
bi_blue="$(printf '\033[1;94m')"
bi_red="$(printf '\033[1;91m')"
bi_green="$(printf '\033[1;92m')"
bi_yellow="$(printf '\033[1;93m')"
color_default="$(printf '\033[0m')"

printf "╔═════════════════════════════════════════════════════╗\n"
printf "║                                                     ║\n"
printf "║                  %sMΛDИVTTΛH Unbound%s                  ║\n" "$bi_white" "$color_default"
printf "║                                                     ║\n"
printf "║     https://github.com/madnuttah/unbound-docker     ║\n"
printf "║     https://hub.docker.com/r/madnuttah/unbound      ║\n"
printf "║                                                     ║\n"
printf "╚═════════════════════════════════════════════════════╝\n\n"

disable_set_perms="${1:-false}"

if [ "$disable_set_perms" = "true" ]; then
    user_color="$bi_green"
    group_color="$bi_green"

    # UID check
    if [ "$(id -u)" = "0" ]; then
        user_color="$bi_red"
    fi

    # GID check
    if [ "$(id -g)" = "0" ]; then
        group_color="$bi_red"
    fi

    printf "User: %s%s%s\n" "$user_color" "$(id -un)" "$color_default"
    printf "Group: %s%s%s\n\n" "$group_color" "$(id -gn)" "$color_default"

else
    # Show UID/GID of _unbound
    uid="$(id -u _unbound 2>/dev/null)" || uid="unknown"
    gid="$(id -g _unbound 2>/dev/null)" || gid="unknown"

    printf "UNBOUND_UID: %s%s%s\n" "$bi_blue" "$uid" "$color_default"
    printf "UNBOUND_GID: %s%s%s\n\n" "$bi_blue" "$gid" "$color_default"
fi

printf "DISABLE_SET_PERMS: %s%s%s\n\n" "$bi_yellow" "$disable_set_perms" "$color_default"

# Anchor root key
"$unbound_root/unbound.d/sbin/unbound-anchor" -a "$unbound_root/iana.d/root.key"

# Exec unbound
exec "$unbound_root/unbound.d/sbin/unbound" -d -c "$unbound_root/unbound.conf"
