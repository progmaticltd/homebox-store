#!/bin/sh

# This simple script comment out public keys that have expired from the authorized_keys file, using a date in unixtime

# Each key is associated with a UUID, specified as a comment on the previous line, for instance:
# --
# 895ca4fa-8b63-11e9-8609-3ba52727fc8d:postmaster@homebox.space:1640908800:present
# command="borg serve --restrict-to-path /home/userbackups/895ca4fa-8b63-11e9-8609-3ba52727fc8d",restrict ecdsa-sha2-nistp384 AAAAE2V[...]DQfPDH6LT5H6og== SSH key for homebox backup
# --
# For the expired keys, the word ‘present’ will be replaced by ‘expired’,
# and each line that contains this key will be commented out.

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
