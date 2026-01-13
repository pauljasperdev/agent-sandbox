# opencode Lima VM

Isolated Ubuntu VM (Lima) for running `opencode` workflows without mounting host directories.

## Prereqs
- macOS + Lima (`limactl`) installed

## Create + start
```bash
limactl start --name opencode ./lima.yaml
```

## Enter the VM
```bash
limactl shell opencode
```

If `brew`/`opencode` aren’t found in your shell:
```bash
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

## Stop / delete
```bash
limactl stop opencode
limactl delete opencode
```

## Notes
- No host mounts (`mounts: []`); use GitHub for file exchange.
- Port forwarding is disabled for all ports except SSH.
- Updating `lima.yaml` does not change an existing instance config; recreate the instance to apply provisioning changes.
