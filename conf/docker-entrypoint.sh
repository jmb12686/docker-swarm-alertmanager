#!/bin/sh -e

## Get the IP address for the eth1 interface.  
## Set the --cluster.advertise-address to this IP to support Docker Swarm networking overlay
## See following issues on GitHub:
##      https://github.com/prometheus/alertmanager/issues/1909
##      https://github.com/prometheus/alertmanager/issues/1550
##      
##      Proposed Solution implemented: https://github.com/prometheus/alertmanager/issues/1550#issuecomment-508904438

ADVERTISE_IP=$(ifconfig eth1 | grep 'inet' | cut -d: -f2 | awk '{ print $1}')
echo "ADVERTISE_IP="$ADVERTISE_IP

set -- /bin/alertmanager "$@" --cluster.advertise-address="$ADVERTISE_IP":8001
exec "$@"