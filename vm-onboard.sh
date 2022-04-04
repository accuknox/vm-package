#!/bin/bash

function unsupported {
	echo "Unsupported operating system."
	exit 1	
}
function install_rpm {
	echo "* Installing vm agent-rpm"
}
function file_check {
	echo "* Getting Kubearmor and Cilium script"
	if [ -s /opt/vm-agent/k-script.sh ]
	then
		cd /opt/vm-agent/
		echo "* installing kube-armor"
		sudo bash ./k-script.sh
		echo "success"
		exit 0
	else
		sleep 3
		file_check
	fi
}
function install_deb {
	if [[ $(which docker) && $(docker --version) ]]; then
	    echo "Docker is installed!!!"
	else
	  echo "Failed: Docker is not installed!!!"
	  exit 1
	fi
	a=$(wget -qO- ifconfig.me/ip)
	echo "external_ip : $a" >> /opt/vm-agent/instance.yaml
	b=$(hostname -I | awk '{print $1}')
	echo "internal_ip : $b" >> /opt/vm-agent/instance.yaml
	export DEBIAN_FRONTEND=noninteractive
	FILE=/lib/systemd/system/vm-agent.service
	if [ -f "$FILE" ]; then
		echo "test"
		sudo rm -f  /lib/systemd/system/vm-agent.service
	fi
	sudo touch /lib/systemd/system/vm-agent.service
	#chmod 777 /lib/systemd/system/vm-agent.service
	sudo ./vm-agent onboard
	echo "* Executing  Vm-Agent"
	echo "[Unit]
Description=vm-agent
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=5s
WorkingDirectory=/opt/vm-agent
ExecStart=/opt/vm-agent/vm-agent

[Install]
WantedBy=multi-user.target" | sudo tee -a  /lib/systemd/system/vm-agent.service >> /dev/null
	sudo systemctl unmask vm-agent.service
	sudo systemctl enable vm-agent
	chmod 777 vm-agent
	sudo service vm-agent start
	#sudo setsid ./vm-agent >log/service.log 2>&1 < log/service.log &
	##./vm-agent&
	#sudo screen -d -m vm-agent
        #./vm-agent
        file_check

}
function is_valid_value {
	if [[ ${1} == -* ]] || [[ ${1} == --* ]] || [[ -z ${1} ]]; then
		return 1
	else
		return 0
	fi
}
function is_int {
	if ! [[ "${1}" =~ ^[0-9]+$ ]]; then
            	echo "Sorry instance group accepts integers only"
            	exit 1
        else
		return 0
	fi
}
function help {
	echo "  Usage: sudo bash ./$(basename "${0}") [Options] values "
	echo ''
	echo "        Options                   Values                             Description"
	echo ''
	echo "      -n   | --vm_name           <value>               A user input for instance name "
	echo "      -t   | --tags              <key>  <value>        labels that user want to add while onboarding"       
    echo "      -ig  | --instance_group_id <value>               Instance_group_id generated from ui"
	echo "      -hd  | --host_domain       <value>               Domain address of vm(control plane)"              
	echo "      -tid | --tenant_id         <value>               Workspace_id generated from ui"
	echo "      -vpc | --vpc               <value> (Optional)"
    echo "      -h   | --help "
	echo " "
    echo "  NOTE: Vm_name,Tags,Instance_group_id,Tenant_id and Host_Domain are mandatory"
	exit 1
}
#main
set -e

#Checking Mandatory Arguments
echo "* Checking Mandatory Arguments"
declare -a pages
pages[0]='-tid;--tenant_id'
pages[1]='-ig;--instance_group_id'
pages[2]='-n;--vm_name'
pages[3]='-t;--tags'
pages[4]='-hd;--host_domain'
for i  in "${pages[@]}"
do
   k=0
   for j in $(seq 1 $#)
   do
     IFS=";" read -r -a arr <<< "${i}"
     if [ "${!j}"  = "-h" ] || [ "${!j}"  = "--help" ]; then
       	help
		    exit 1
     fi
     #echo  "${!j}" and "${arr[0]}" and "${arr[1]}"
     if [ "${!j}" = "${arr[0]}" ] || [ "${!j}" = "${arr[1]}" ]; then
       k=1
     fi
   done
   if [ $k -eq 0 ] ; then 
      echo "Error: Bad Input"
      help
      exit 1
   fi
done
echo "done"
#Creating necessary files
FILE=/opt/vm-agent
if [ -d "$FILE" ]; then
	sudo rm -rd  /opt/vm-agent
fi
sudo mkdir /opt/vm-agent
sudo touch /opt/vm-agent/instance.yaml
chmod 777 /opt/vm-agent/instance.yaml
sudo touch /opt/vm-agent/k-script.sh
chmod 777 /opt/vm-agent/k-script.sh
#moving files to opt folder
cp vm-agent /opt/vm-agent/
cp -R conf /opt/vm-agent/
cp -R log  /opt/vm-agent/
a=${#}
#Check for mandatory field values
while [[ ${#} -gt 0 ]]
do
key="${1}"

case ${key} in
	-n|--vm_name)
		if is_valid_value "${2}"; then
			VM_NAME="${2}"
			echo "instance_name: "$VM_NAME > /opt/vm-agent/instance.yaml
			
		else
			echo "ERROR: no value provided for VM_NAME option, use -h | --help for $(basename ${0}) Usage"
			exit 1
		fi
		shift
		;;
	-t|--tags)
		echo "labels: " >> /opt/vm-agent/instance.yaml
		while [[ ${2} != -* ]]
		do
			if [[ ${2} != -* ]]; then
				if [[ ${3} != -* ]]; then
					echo "- key: ${2}" >> /opt/vm-agent/instance.yaml
					echo "  value: ${3}" >> /opt/vm-agent/instance.yaml
					shift
					shift
				else
					shift
					continue
				fi
			else
				echo "ERROR: no value provided for tags option, use -h | --help for $(basename ${0}) Usage"
				continue
				#exit 1
			fi
		done
		#shift
		;;
	-hd|--host_domain)
		if is_valid_value "${2}"; then
			IP="${2}"
			echo "host: $IP" >> /opt/vm-agent/instance.yaml
		else
			echo "ERROR: no value provided for instance_group option, use -h | --help for $(basename ${0}) Usage"
			exit 1
		fi
		shift
		;;
	-ig|--instance_group_id)
		if is_valid_value "${2}"; then
			INSTANCE_GROUP="${2}"
			echo "group_id : $INSTANCE_GROUP" >> /opt/vm-agent/instance.yaml
		else
			echo "ERROR: no value provided for instance_group option, use -h | --help for $(basename ${0}) Usage"
			exit 1
		fi
		shift
		;;
	-tid|--tenant_id)
		if is_int "${2}"; then
			INSTANCE_GROUP="${2}"
			echo "workspace_id : $INSTANCE_GROUP" >> /opt/vm-agent/instance.yaml
		else
			echo "ERROR: no value provided for instance_group option, use -h | --help for $(basename ${0}) Usage"
			exit 1
		fi
		shift
		;;
	-vpc|--vpc)
		if [[ a -lt 10 ]];  then
			echo "ERROR:  vm_name ,tags,vm_group,ip 2 is mandatory, use -h | --help for $(basename ${0}) Usage"
			exit 1
		fi
		if is_valid_value "${2}"; then
			VPC="${2}"
			echo "vpc: "$VPC >> /opt/vm-agent/instance.yaml
		else
			echo "ERROR: no value provided for -vpc option, use -h | --help for $(basename ${0}) Usage"
			exit 1
		fi
		shift
		;;

	*)
		echo "ERROR: Invalid option: ${1}, use -h | --help for $(basename ${0}) Usage"
		exit 1
		;;
esac
shift
done
echo "* Detecting operating system"

ARCH=$(uname -m)
if [[ ! $ARCH = *86 ]] && [ ! $ARCH = "x86_64" ] && [ ! $ARCH = "s390x" ]; then
	unsupported
fi

if [ $ARCH = "s390x" ]; then
	echo "------------"
	echo "WARNING: A Docker container is the only officially supported platform on s390x"
	echo "------------"
fi

if [ -f /etc/debian_version ]; then
	if [ -f /etc/lsb-release ]; then
		. /etc/lsb-release
		DISTRO=$DISTRIB_ID
		VERSION=${DISTRIB_RELEASE%%.*}
	else
		DISTRO="Debian"
		VERSION=$(cat /etc/debian_version | cut -d'.' -f1)
	fi

	case "$DISTRO" in

		"Ubuntu")
			if [ $VERSION -ge 10 ]; then
				echo "operating_system : ubuntu" >> /opt/vm-agent/instance.yaml
				install_deb
			else
				unsupported
			fi
			;;

		"LinuxMint")
			if [ $VERSION -ge 9 ]; then
				echo "operating_system : LinuxMint"$os >> /opt/vm-agent/instance.yaml
				install_deb
			else
				unsupported
			fi
			;;

		"Debian")
			if [ $VERSION -ge 6 ]; then
				echo "operating_system : Debian">> /opt/vm-agent/instance.yaml
				install_deb
			elif [[ $VERSION == *sid* ]]; then
				install_deb
			else
				unsupported
			fi
			;;

		*)
			unsupported
			;;

	esac


elif [ -f /etc/system-release-cpe ]; then
	DISTRO=$(cat /etc/system-release-cpe | cut -d':' -f3)

	# New Amazon Linux 2 distro
	if [[ -f /etc/image-id ]]; then
		AMZ_AMI_VERSION=$(cat /etc/image-id | grep 'image_name' | cut -d"=" -f2 | tr -d "\"")
	fi

	if [[ "${DISTRO}" == "o" ]] && [[ ${AMZ_AMI_VERSION} = *"amzn2"* ]]; then
		DISTRO=$(cat /etc/system-release-cpe | cut -d':' -f4)
	fi

	VERSION=$(cat /etc/system-release-cpe | cut -d':' -f5 | cut -d'.' -f1 | sed 's/[^0-9]*//g')

	case "$DISTRO" in

		"oracle" | "centos" | "redhat")
			if [ $VERSION -ge 6 ]; then
				install_rpm
			else
				unsupported
			fi
			;;

		"amazon")
			install_rpm
			;;

		"fedoraproject")
			if [ $VERSION -ge 13 ]; then
				install_rpm
			else
				unsupported
			fi
			;;

		*)
			unsupported
			;;

	esac

else
	unsupported
fi