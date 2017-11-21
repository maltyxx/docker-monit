#!/bin/bash

########### Check that Auth variables are defined
if [ -z "$USERNAME" ]; then
    echo "You must define USERNAME"
    exit 1
fi

if [ -z "$PASSWORD" ]; then
    echo "You must define PASSWORD"
    exit 1
fi

########### Login Configuration
cat << EOF > /usr/local/etc/monitrc/monit.d/setting.cfg
# Generated by docker-entrypoint.sh
set httpd port 2812 and
    use address 0.0.0.0
    allow ${USERNAME:-admin}:${PASSWORD} readonly
EOF

########### Add system
echo "# Generated by docker-entrypoint.sh" > /usr/local/etc/monitrc/monit.d/system.cfg

cat << EOF >> /usr/local/etc/monitrc/monit.d/system.cfg
check system cpu
    if cpu usage (user) > 80% for 2 cycles then alert
    if cpu usage (system) > 20% for 2 cycles then alert
    if cpu usage (wait) > 80% for 2 cycles then alert
EOF

cat << EOF >> /usr/local/etc/monitrc/monit.d/system.cfg
#check system loadavg
#    if loadavg (1min) > 3 then alert
#    if loadavg (5min) > 2 then alert
#    if loadavg (15min) > 1 then alert
EOF

cat << EOF >> /usr/local/etc/monitrc/monit.d/system.cfg
check system memory
    if memory usage > 90% for 4 cycles then alert
EOF

cat << EOF >> /usr/local/etc/monitrc/monit.d/system.cfg
check system swap
    if swap usage > 20% for 4 cycles then alert
EOF

########### Add all filesystems mounted
MOUNTS=$(findmnt -n -lo target -t btrfs,ext4,nfs,xfs | egrep '^/host' | egrep -v '^/host/var/lib/docker/devicemapper' || true)
echo "# Generated by docker-entrypoint.sh" > /usr/local/etc/monitrc/monit.d/filesystem.cfg

for M in $MOUNTS; do
    NAME=$(basename $M)
	
	if [ $NAME = "/" ]; then
        NAME="rootfs"
    fi

cat << EOF >> /usr/local/etc/monitrc/monit.d/filesystem.cfg
check filesystem ${NAME} with path ${M}
  if space usage > 90% for 5 times within 15 cycles then alert
EOF
done

########### Add all interface network
INTERFACES=$(ifconfig | cut -c 1-8 | sort | uniq -u | grep -v 'veth')
echo "# Generated by docker-entrypoint.sh" > /usr/local/etc/monitrc/monit.d/network.cfg

for I in $INTERFACES; do
    NAME=$(basename $I)
cat << EOF >> /usr/local/etc/monitrc/monit.d/network.cfg
check network ${NAME} with interface ${I}
  if saturation > 90% then alert
EOF
done

########### Add docker

if [ -z "$LABEL" ]; then
    LABEL=io.rancher.container.name
fi

CONTAINERS=$(docker ps --format "{{.Label \"$LABEL\"}}")
echo "# Generated by docker-entrypoint.sh" > /usr/local/etc/monitrc/monit.d/docker.cfg

# On boucle dessus pour créer les fichiers de checkservices par conteneur
for C in $CONTAINERS; do
cat << EOF >> /usr/local/etc/monitrc/monit.d/docker.cfg
check program ${C} with path "/usr/local/etc/monitrc/script.d/docker.sh ${C}"
   if status > 0 for 2 cycles then alert
EOF
done

########### Add all script
if [ -d /docker-entrypoint.d ]; then
	for f in /docker-entrypoint.d/*; do
		[ -x "$f" ] && . "$f"
	done
	unset f
fi

echo "Running $@"
exec "$@"
