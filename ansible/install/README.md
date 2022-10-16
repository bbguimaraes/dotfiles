install
=======

Arch Linux installation
-----------------------

Make sure to start the system in UEFI mode, which may need changes in the BIOS
setup.  Check with `dmesg | grep 'EFI v'`.  On the live installation
environment, on the target machine, set up root password for SSH access and
create a file with the LUKS encryption key (_with no trailing space_):

    # yes root | passwd
    # cat > /tmp/luks.key
    <password>

To make things easier, install an SSH public key on the target from the machine
which will execute Ansible commands:

    $ ip=…
    $ ssh-copy-id root@$ip

Execute the installation playbook:

    $ ansible-playbook \
        --inventory $ip, \
        --user root \
        --extra-vars hostname=… \
        --extra-vars disk_device=nvme0n1 \
        --extra-vars lvm_vg=vg0 \
        ansible/install/arch.yaml

Basic configuration
-------------------

When the new system is restarted into the new installation:

    $ ansible-playbook \
        --extra-vars sudo_wheel_nopasswd=true \
        ansible/install/base.yaml

Desktop configuration
---------------------

For desktop systems:

    $ ansible-playbook ansible/install/desktop.yaml

Enable Kerberos in Firefox, if necessary:

https://wiki.archlinux.org/title/Kerberos#Firefox

Conclusion
----------

Set a user password:

    # passwd bbguimaraes

Require password for `sudo`:

    $ ansible-playbook \
        --become --extra-vars sudo_wheel_nopasswd=false \
        ansible/install/base.yaml

Disable root's password and remove the authorized SSH key:

    # passwd --lock root
    # rm ~/.ssh/authorized_keys
