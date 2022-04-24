beaglebone black
================

https://archlinuxarm.org/platforms/armv7/ti/beaglebone-black

Start by adapting `vars.yaml` to the particular setup.

Execute `sd.yaml` to install and setup SD card as boot device.

    $ ansible-playbook \
        --inventory localhost, --connection local \
        --extra-vars @ansible/bbb/vars.yaml \
        --become \
        ansible/bbb/sd.yaml

The initial setup has to be done on the device, unless another ARM computer is
available.  Transfer the SD card to the device, initialize it, and update
packages:

    # pacman-key --init
    # pacman-key --populate archlinuxarm
    # pacman -Syyu

Install the LVM package so the VG can be mounted during initialization and the
Ansible pre-requisites:

    # pacman -Su lvm2 python sudo

Repurpose the `alarm` user:

    # usermod --gid users alarm
    # groupdel alarm
    # groupmod --gid 1000 users
    # usermod --login bbguimaraes --home /home/bbguimaraes alarm
    # mv /home/alarm ~bbguimaraes

Power off, transfer the card back, make sure the disks are plugged in, and
execute the playbook to to set up RAID as external storage and move dynamic
directories (`/home`, `/var`) to it.

    $ ansible-playbook \
        --inventory localhost, --connection local \
        --extra-vars @ansible/bbb/vars.yaml \
        --become \
        ansible/bbb/disk.yaml

Transfer everything to the device and finish the installation:

    $ ansible-playbook \
        --inventory ansible/hosts --limit bbb \
        --become --become-method su --ask-become-pass \
        --extra-vars sudo_wheel_nopasswd=true \
        ansible/install/base.yaml
    $ ansible-playbook \
        --inventory ansible/hosts --limit bbb \
        --user root \
        ansible/install/install.yaml
    $ ansible-playbook \
        --inventory ansible/hosts --limit bbb \
        ansible/install/base_user.yaml
