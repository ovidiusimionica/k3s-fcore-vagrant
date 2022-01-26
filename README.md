# K3S cluster on Fedora CoreOS VMs

This repo provides a Vagrantfile to create a Rancher Kubernetes Cluster based on Fedora CoreOS virtual machines using one of: VirtualBox software/ KVM / VMware hypervisor.

After setup is complete you will have a K3S cluster featuring one master node and 1..n worker nodes running on your local machine.

## Current status:
* **only KVM works**
* *for VirtualBox/VMware and Windows support feel free to contribute*


## Streamlined setup

1) Install dependencies

* [KVM & libvirt & virtsh][kvm] -> for Linux KVM setup or
* [VirtualBox][virtualbox] -> for Windows VirtualBox setup
* [Vagrant][vagrant] 1.6.3 or greater

2) Clone this project to get it running!


3) Configuration

Copy ``config.rb.template`` as ``config.rb``. Open the new file and you can customize:

* *num_instances* 
    * -> minimum value 1: will create one master node only
    * -> n>1: will create one master node and n-1 worker nodes
* *ip_base* -> virtual network ip specification
* *vm_memory* -> RAM for VMs
* *vm_cpus* -> CPU for VMs 

Please observe the setting *instance_name_prefix*


4) Startup and SSH

``vagrant up`` triggers vagrant to automatically download the latest Fedora CoreOS image (if necessary) and launch the instance
I use  Fedora CoreOS Configuration files to provision the vms therefor the fcct transpiler to ignition format is required and automatically downloaded. 


There are three "providers" for Vagrant with slightly different instructions.
Follow one of the following two options:

**KVM / VirtualBox Provider (!!! only KVM is currently working !!!)**

The KVM / VirtualBox provider is the default Vagrant provider. Use this if you are unsure.
If you have both installed then use/ set the environment variable e.g.:
```
export VAGRANT_DEFAULT_PROVIDER=libvirt 
```


```
vagrant up
vagrant ssh <instance_name_prefix>-01
```

**VMware Provider**

The VMware provider is a commercial addon from Hashicorp that offers better stability and speed.
If you use this provider follow these instructions.

VMware Fusion:
```
vagrant up --provider vmware_fusion
vagrant ssh <instance_name_prefix>-01
```

VMware Workstation:
```
vagrant up --provider vmware_workstation
vagrant ssh <instance_name_prefix>-01
```



5) Get started [using K3S][using-k3s]


ssh to master node 
```
vagrant ssh <instance_name_prefix>-01
kubectl get nodes
```

[kvm]: https://help.ubuntu.com/community/KVM/Virsh
[virtualbox]: https://www.virtualbox.org/
[vagrant]: https://www.vagrantup.com/downloads.html
[using-k3s]: https://rancher.com/docs/k3s/latest/en/cluster-access/

## Troubleshooting
If vagrant fails to run successfully, first make sure that the latest version of the project has been downloaded, then run

```
vagrant destroy -f 
rm -f .build/fedora-coreos
./build_box.sh fedora-coreos
```
