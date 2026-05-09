# network-ansible

systemd-networkd で WireGuard mesh を構成する Ansible project です。

## Requirements

- `python` - 3.10
- `pipenv`
- `sha256sum`
- `awk`
- `xxd`
- `base64`

`wireguard.netdev.j2` は peer 間 PSK を controller 側で導出するため、上記 command が Ansible 実行端末に必要です。

## Setup

```bash
pipenv shell
pipenv install
pipenv run ansible-galaxy collection install -r requirements.txt
```

## Inventory

[`inventories/example/hosts.yml`](inventories/example/hosts.yml) は例です。  
複数メッシュを作成する場合は以下のようなディレクトリ構造にすることを推奨します。

```text
inventories/
├── example/
│   └── hosts.yml
├── production/
│   ├── hnd3/
│   │   └── hosts.yml
│   ├── nrt1/
│   │   └── hosts.yml
│   └── kix2/
│       └── hosts.yml
└── dev/
    ├── hnd3/
    │   └── hosts.yml
    ├── nrt1/
    │   └── hosts.yml
    └── kix2/
        └── hosts.yml
```

## Create

運用時はinventoryを **ansible-vault** で暗号化します。

Dev Inventoryの例:

```bash
# 新規作成
pipenv run ansible-vault create inventories/dev/hosts.yml

# 編集
pipenv run ansible-vault edit inventories/dev/hosts.yml
```

## Exec

実行ディレクトリにパスワードを記載した `.vault-pass` を配置してください。

Dev Inventory の実行コマンド例:

```bash
# 確認
pipenv run ansible-playbook playbooks/mesh.yml \
  -i inventories/dev/hosts.yml -CD --vault-password-file .vault-pass

# 実行
pipenv run ansible-playbook playbooks/mesh.yml \
  -i inventories/dev/hosts.yml -D --vault-password-file .vault-pass
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
