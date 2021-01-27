# ubuntu-cloud-init-kvm

shell script to deploy a new Ubuntu (Focal) cloud image on KVM. Once the guest tools have established the new IP, a message is sent to Telegram with the new VMs IP address.

## scripts

- `update-ubuntu-cloud-img.sh` will download the ubuntu focal cloud image and place the image where the deployment ecript expects it to be. This is intended to be run on the KVM host.
- `new-ubuntu-vm.sh` will deploy the cloud image as per questions asked.
- `delete-vm.sh` will delete a vm by name and remove all associated VM storage.

## To do

- Make the script more configurable. For example my internal DNS server and search domains are currently hard coded.
- Maybe document the KVM setup.
- Dependency check for `telegram-send`
