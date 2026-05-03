# network-ansible

Ansible project for managing network infrastructure.

## Layout

- `ansible.cfg`: local Ansible defaults
- `inventories/dev/hosts.yml`: inventory that reads connection values from `.env`
- `group_vars/`: shared variables by group
- `playbooks/`: executable playbooks
- `roles/`: reusable role implementations

## Setup

```sh
cp .env.example .env
pipenv install
```

## Commands

Check inventory:

```sh
pipenv run inventory
```

Run a connectivity check:

```sh
pipenv run ping
```

Run the main playbook:

```sh
pipenv run site
```

`pipenv run` loads `.env` into the environment. The inventory reads those values with Ansible's built-in `env` lookup. Set the two SSH targets there:

```sh
HOST_A_USER=root
HOST_A_IPV6=2600:3c18::2000:4dff:fe9b:3360
HOST_A_WG_INTERFACE=wgs2smesh0
HOST_A_GRE_INTERFACE=gre2hnd1pve1

HOST_B_USER=ubuntu
HOST_B_IPV6=240b:10:9f6e:b600:be24:11ff:fe18:6597
HOST_B_WG_INTERFACE=wgs2smesh0
HOST_B_GRE_INTERFACE=gre2tyo3br001
```

The main playbook writes systemd-networkd files like:

- `/etc/systemd/network/10-<wg-interface>.netdev`
- `/etc/systemd/network/10-<wg-interface>.network`
- `/etc/systemd/network/20-<gre-interface>.netdev`
- `/etc/systemd/network/20-<gre-interface>.network`

For production or secret values, use Ansible Vault instead of committing raw credentials.
