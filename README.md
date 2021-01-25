# ubuntu-cloud-init-kvm

shell script to deploy a new Ubuntu (Focal) cloud image on KVM.

## scripts

- `update-ubuntu-cloud-img.sh` will download the ubuntu focal cloud image and place the image where the deployment ecript expects it to be. This is intended to be run on the KVM host.

- `new-ubuntu-vm.sh` will deploy the cloud image as per questions asked.

## To do

- Make the script more configurable. For example my internal DNS server and search domains are currently hard coded.
- Maybe document the KVM setup.
