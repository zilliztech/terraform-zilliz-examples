#!/bin/bash
set -euo pipefail

# Instance-store contents are lost on stop/start. Discover and mount the disk
# before checking the marker, which must live on the instance store itself.
disk=$(lsblk -J -o NAME,MODEL | jq -er '
    [.blockdevices[] | select(.model != null and (.model | test("Amazon EC2 NVMe Instance Storage")))]
    | if length == 1 then .[0].name else error("Expected exactly one NVMe instance-store disk") end')
device="/dev/$disk"
filesystem=$(blkid -s TYPE -o value "$device") || {
    status=$?
    # blkid returns 2 when no filesystem signature is found.
    [ "$status" -eq 2 ] || exit "$status"
}
if [ -z "$filesystem" ]; then
    mkfs.xfs "$device"
elif [ "$filesystem" != xfs ]; then
    echo "Unexpected filesystem $filesystem on $device" >&2
    exit 1
fi

mkdir -p /mnt/data
if ! mountpoint -q /mnt/data; then
    mount "$device" /mnt/data
fi
if [ "$(findmnt -n -o SOURCE --mountpoint /mnt/data)" != "$device" ]; then
    echo "/mnt/data is not mounted from $device" >&2
    exit 1
fi
if [ -f /mnt/data/.initialized ]; then
    exit 0
fi

chmod 0755 /mnt/data
for directory in kubelet docker; do
    source="/var/lib/$directory"
    target="/mnt/data/$directory"
    if [ -L "$source" ]; then
        [ "$(readlink "$source")" = "$target" ] || exit 1
    elif [ -e "$source" ]; then
        # Do not overwrite an existing destination when retrying a failed boot.
        [ ! -e "$target" ] || exit 1
        mv "$source" "$target"
    fi
    mkdir -p "$target"
    if [ ! -L "$source" ]; then
        ln -s "$target" "$source"
    fi
done
# Only a fully initialized mounted disk can bypass setup on a later boot.
touch /mnt/data/.initialized
