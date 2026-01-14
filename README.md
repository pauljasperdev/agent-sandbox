# Agent sandbox (Lima VM)

Isolated Ubuntu VM (Lima) for running agentic workflows (e.g. `opencode`) without mounting host directories.

## Prereqs
- macOS + Lima (`limactl`) installed

## Create + start
```bash
limactl start --name agent-sandbox ./lima.yaml
```

## Enter the VM
```bash
limactl shell agent-sandbox
```

If `brew`/`opencode` aren’t found in your shell:
```bash
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

## Stop / delete
```bash
limactl stop agent-sandbox
limactl delete agent-sandbox
```

## File exchange (copy in / copy out)

This VM intentionally has **no host mounts** and **no SSH keys**. Use `limactl copy` to move data in and out.

### Copy files into the VM
```bash
# From host
tar -czf input.tar.gz workdir
limactl copy input.tar.gz agent-sandbox:/tmp/input.tar.gz
limactl shell agent-sandbox -- mkdir -p /workspace/input
limactl shell agent-sandbox -- tar -xzf /tmp/input.tar.gz -C /workspace/input
```

### Copy Git identity (for correct commit author)
The VM does **not** inherit host Git config automatically. To ensure commits have the correct author, explicitly copy your Git config:

```bash
# From host
limactl shell agent-sandbox -- mkdir -p ~/.config/git
limactl copy ~/.config/git/config agent-sandbox:~/.config/git/config
```

Verify inside the VM:
```bash
git config --get user.name
git config --get user.email
```

### Run agent
```bash
limactl shell agent-sandbox -- opencode run
```

### Copy results out of the VM
```bash
limactl shell agent-sandbox -- tar -czf /tmp/output.tar.gz -C /workspace/output .
limactl copy agent-sandbox:/tmp/output.tar.gz .
```

## Notes
- No host mounts (`mounts: []`); all data transfer is explicit.
- Port forwarding is disabled for all ports except SSH.
- Updating `lima.yaml` does not change an existing instance config; recreate the instance to apply provisioning changes.

## License
MIT (see `LICENSE`).
