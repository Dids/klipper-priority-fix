# klipper-priority-fix

A simple but hacky workaround for raising Klipper service priorities on lower end SBCs like BTT-CB1, to avoid timeouts and failed prints.

## Installation

Start by checking out the repository to your home directory.

```bash
git clone https://github.com/Dids/klipper-priority-fix.git ~/klipper-priority-fix
```

Now you can run the install script, which should automatically setup everything for you.

```bash
~/klipper-priority-fix/scripts/install.sh
```

While optional, it is highly recommended that you also setup automatic updates, simply by adding the following `update_manager` entry to your `moonraker.conf` (or to the file where you configure Moonraker's update manager).

```yaml
# Update manager entry for klipper-priority-fix
[update_manager klipper-priority-fix]
type: git_repo
channel: dev
path: ~/klipper-priority-fix
origin: https://github.com/Dids/klipper-priority-fix.git
primary_branch: master
install_script: scripts/install.sh
managed_services: klipper-priority-fix
```

Ensure that you also add `klipper-priority-fix` to the bottom of your `~/printer_data/moonraker.asvc` file, so that Moonraker can control the klipper-priority-fix service.

If you setup the automatic updates above, you may additionally need to restart Moonraker.

```bash
systemctl restart moonraker
```

Now klipper-priority-fix be installed, running and kept up-to-date automatically.

## License

See [LICENSE](LICENSE).
