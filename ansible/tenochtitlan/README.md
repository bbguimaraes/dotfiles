tenochtitlan
============

A relatively complex sequence of steps to configure a Raspberry Pi:

- `vars.yaml` contains default values for most configuration variables
- `pre.yaml` populates the SD card and configures external storage
- with the π booted, these manual steps must be executed:
  - configure mirrors
  - `# pacman-key --init`
  - `# pacman-key --populate archlinuxarm`
  - `# pacman --noconfirm -Syy python`
  - `# usermod --login bbguimaraes --home /home/bbguimaraes alarm`
  - `# mv /home/alarm ~bbguimaraes`
- `../base/base.yaml` applies the configuration common to all machines
- `tenochtitlan.yaml` performs configuration that must be done on the host
  system
- `post.yaml` moves dynamic directories (`/home`, `/var`, etc.) to external
  storage based on LVM
