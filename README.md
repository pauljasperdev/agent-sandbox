# Agent sandbox (Lima VM)

Isolated Ubuntu VM (Lima) for running agentic workflows (e.g. `opencode`) without mounting host directories.

## Prereqs

- macOS + Lima (`limactl`) installed

## Create + start (recommended)

Use `start.sh` to create (or reuse) the VM and copy a repo into it:

```bash
./start.sh --lima-file ./lima.yaml --src-dir .
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

## Repo sync into the VM

This VM intentionally has **no host mounts** and **no SSH keys**. All data transfer is explicit.

`start.sh` packages a repo on the host and copies it into the VM at:

```text
/workspace/repo
```

The copy:

- Includes `.git/` so you can commit inside the VM
- Includes uncommitted files
- Respects `.limaignore` (or falls back to `.gitignore`)

### `.limaignore`

Create a `.limaignore` file at the repo root to control what is copied into the VM (syntax matches `.gitignore`).

You can also override this explicitly:

```bash
./start.sh --lima-file ./lima.yaml --src-dir . --ignore-file path/to/ignore
```

```gitignore
node_modules/
dist/
.env
*.log
```

### Git identity (commits inside VM)

The VM does **not** inherit host Git config automatically.

`start.sh` will automatically copy your Git identity if it exists at:

```text
~/.config/git/confi
```

You can also copy it manually:

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
