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

When the new system is restarted into the new installation, copy the SSH key
again, and:

    $ ansible-playbook \
        --user root --extra-vars sudo_wheel_nopasswd=true \
        ansible/install/base.yaml

For servers:

    $ ansible-playbook --user root ansible/install/swap.yaml

User base setup:

    $ ansible-playbook ansible/install/base_user.yaml

Desktop configuration
---------------------

For desktop systems:

    $ ansible-playbook --user root ansible/install/desktop.yaml
    $ ansible-playbook --user root ansible/install/backlight.yaml
    $ ansible-playbook ansible/install/keys.yaml
    $ ansible-playbook ansible/install/desktop_user.yaml

Start XOrg, configure Nextcloud, synchronize files, then:

    $ ansible-playbook ansible/install/user.yaml
    $ ansible-playbook \
        --extra-vars nixpkgs=https://nixos.org/channels/nix-22.05 \
        ansible/install/nix.yaml
    $ ansible-playbook --user root ansible/install/gpg_pam.yaml
    $ ansible-playbook ansible/install/gpg_pam_user.yaml

For personal systems:

    $ ansible-playbook ansible/install/personal.yaml

For work:

    $ ansible-playbook --user root ansible/install/work.yaml
    $ ansible-playbook ansible/install/work_user.yaml

Enable Kerberos in Firefox: https://wiki.archlinux.org/title/Kerberos#Firefox.

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
