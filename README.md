# network-ansible

systemd-networkd で WireGuard mesh を構成する Ansible project です。

## Requirements

- Python 3.10
- Pipenv
- Ansible controller 側で使える以下の command
  - `sha256sum`
  - `awk`
  - `xxd`
  - `base64`

`wireguard.netdev.j2` は peer 間 PSK を controller 側で導出するため、上記 command が Ansible 実行端末に必要です。

## Setup

Python package は Pipenv で入れます。

```bash
pipenv install
```

Ansible collection は `requirements.txt` から入れます。

```bash
pipenv run ansible-galaxy collection install -r requirements.txt
```

`ansible.cfg` の `collections_path` は `.ansible/collections` です。install 済み collection は repository には含めません。

## Inventory

default inventory は `inventories/example/hosts.yml` です。

```yaml
all:
  children:
    network:
      vars:
        wireguard_interface: "wgmesh0"
        wireguard_description: "wgmesh0 managed by ansible"
        wireguard_mtu: 2840
        wireguard_subnet:
          ip: 172.16.42.0
          prefix: 24
```

host ごとに WireGuard endpoint、address、key seed を定義します。

```yaml
hnd01br01:
  ansible_host: "2400:abcd:900d:beef::1000"
  wireguard_endpoint: "2400:abcd:900d:beef::1000"
  wireguard_addresses:
    - ip: 172.16.42.1
      prefix: 32
  wireguard_port: 51820
  wireguard_persistent_keepalive: 1
  wireguard_private_key: "..."
  wireguard_public_key: "..."
  wireguard_psk_seed: "..."
```

## Create

exampleを例に作成します。
運用時はinventoryをansible-vaultで暗号化してください。

Dev Inventoryの例:

```bash
# 新規作成
pipenv run ansible-vault create inventories/dev/hosts.yml

# 既存変換
pipenv run ansible-vault encrypt inventories/dev/hosts.yml

# 編集
pipenv run ansible-vault edit inventories/dev/hosts.yml
```

実行時は以下のオプションのいずれかを付けてください。
- `--ask-vault-pass`
- `--vault-password-file <filename>`


## Execution

Dev Inventory の実行コマンド例:

```bash
# 確認
pipenv run ansible-playbook -i inventories/dev/hosts.yml playbooks/mesh.yml -CD --vault-password-file .vault-pass

# 実行
pipenv run ansible-playbook -i inventories/dev/hosts.yml playbooks/mesh.yml -D --vault-password-file .vault-pass
```

## WireGuard

### Role

`roles/wireguard` は以下を配置します。

- `/etc/systemd/network/{{ wireguard_interface }}.key`
- `/etc/systemd/network/{{ wireguard_interface }}.pub`
- `/etc/systemd/network/{{ wireguard_interface }}.psk.seed`
- `/etc/systemd/network/10-{{ wireguard_interface }}.netdev`
- `/etc/systemd/network/10-{{ wireguard_interface }}.network`

template 配置後、`networkctl reload` と `networkctl up {{ wireguard_interface }}` を実行します。

### PSK

peer 間 PSK は、各 host の `wireguard_psk_seed` を host 名の辞書順で結合して生成します。

```bash
{
  printf '%s' "$PSK_A" | base64 -d
  printf '%s' "$PSK_B" | base64 -d
} | sha256sum | awk '{print $1}' | xxd -r -p | base64
```

host 名が小さい方の seed を左辺、大きい方の seed を右辺として扱うため、両 peer で同じ PSK になります。
