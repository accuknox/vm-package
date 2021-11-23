#!/bin/bash

function help {
	echo "Usage: $(basename ${0}) "
	echo "  -n | --cluster_name <value> -tid | --tenant_id <value>  -hs | --host <value> "
	exit 1
}
#main
set -e
##Checking of help tag
while [[ ${#} -lt 2 ]]
do
key="${1}"

case ${key} in
	-h|--help)
		help
		exit 1
		;;
	*)
esac
shift
done
a=61
while [[ ${#} -gt 0 ]]
do
key="${1}"
case ${key} in
	-n|--help)
		cname="${2}"
		#echo $cname
		shift
		;;
	-tid|--tenant_id)
		wid=${2}
		#echo $wid
	     	shift
		;;
	-hs| --host_name)
		host=${2}
		#echo $host
	     	shift
		;;
	*)
	;;
esac
shift
done
mysql -u accuknox_user -p'EAy5Kq4uhc5Gkws' -h 127.0.0.1 -P 3307 << EOF
use accuknox;
#insert into clusters (cluster_name,location,workspace_id,ca_data,host,status,last_updated_time) values("$cname","",$wid,"","$host",0,Now());
select * from clusters;
EOF
echo "success"


