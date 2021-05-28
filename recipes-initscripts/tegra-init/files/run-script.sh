mkdir -p /data/
mount /dev/mmcblk1p1 /data/
mount -t tmpfs -o size=256m tmpfs /tmp

for suffix in conf sig cert; do
        if [ ! -f "/data/cml/containers/00000000-0000-0000-0000-000000000000.$suffix" ]; then
                cp /data/cml/containers_templates/00000000-0000-0000-0000-000000000000.$suffix /data/cml/containers/00000000-0000-0000-0000-000000000000.$suffix
        fi
done

scd&
