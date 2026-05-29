#!/bin/sh

# Usage:
#   patch-unbound-conf.sh /usr/local/unbound/unbound.conf /tmp/unbound.conf.override

vanilla="$1"
override="$2"

tmp="/tmp/unbound.conf.tmp"
tmp2="/tmp/unbound.conf.tmp2"

cp "$vanilla" "$tmp"

current_section=""

while IFS= read -r line; do
    # Skip empty lines
    [ -z "$line" ] && continue

    case "$line" in
        

\[*\]

)
            # Section header like [server], [auth-zone], [global]
            current_section=$(printf "%s" "$line" | tr -d '[]')
            continue
            ;;
    esac

    # Parse key/value
    key=$(printf "%s" "$line" | cut -d':' -f1 | sed 's/^[ \t]*//')
    value=$(printf "%s" "$line" | cut -d':' -f2- | sed 's/^[ \t]*//')

    # GLOBAL SECTION → append at end
    if [ "$current_section" = "global" ]; then
        printf "%s: %s\n" "$key" "$value" >> "$tmp"
        continue
    fi

    # SECTION-AWARE PATCHING
    awk -v section="$current_section" \
        -v key="$key" \
        -v value="$value" \
        '
        BEGIN { in_section=0; replaced=0 }

        {
            # Detect section start
            if ($0 ~ "^"section":") {
                in_section=1
            } else if ($0 ~ "^[a-zA-Z0-9_-]+:") {
                in_section=0
            }

            # Replace key inside section
            if (in_section && $0 ~ "^[ \t]*"key":") {
                print "    " key ": " value
                replaced=1
                next
            }

            print
        }

        END {
            # Append missing key inside section
            if (replaced == 0 && section != "") {
                print section ":"
                print "    " key ": " value
            }
        }
        ' "$tmp" > "$tmp2"

    mv "$tmp2" "$tmp"

done < "$override"

mv "$tmp" "$vanilla"
