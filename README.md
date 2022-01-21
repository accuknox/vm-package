# vm-package


Steps:

The VM package consists of a bash script that checks the os type and creates a file (instance.yaml) consists of necessary fields like internal-IP,external-IP,instance-name, labels, etc.

Using that data, the agent creates an instance,labels and get the k-armor script by hitting VM-management APIs.

Then, the onboarding process completes by listing instances in the workspace.

 
Source for the VM-Agent package:

https://github.com/accuknox/vm-package/raw/dev-non-gke/vm-package.tar.xz


Commands to run and install vm-agent,kube-armor in vms.

1.wget https://github.com/accuknox/vm-package/raw/dev-non-gke/vm-package.tar.xz

2.tar xf vm-package.tar.xz 

3.Use sudo bash vm-onboard.sh -h  for help.

4.sudo bash vm-onboard.sh  -n <instance-name> -t <key> <value> -ig <instance_group_id> -tid <workspace_id> -hd <host-domain>
