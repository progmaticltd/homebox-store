#!/bin/sh

# Get today's unixtime
now=$(date +%s)
keyFile=~/.ssh/authorized_keys

# Get all expired keys
expired=$(sed -n 's/^# //p' "$keyFile" | awk -F : '$3 <= '"$now"' { print $1 }')

# Remove the expired keys from the authorized_keys file
# And mark them as expired
for e in $expired; do
    sed -i -r "s|^command=\"borg serve --restrict-to-path /home/[^/]+/$e\",.*|# \\0|" "$keyFile"
    sed -i -r "s|^(# $e.*):present|\\1:expired|" "$keyFile"
done
