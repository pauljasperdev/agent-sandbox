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

`start.sh` drops you into the copied repo automatically. If you want to skip that (e.g. for CI), pass `--no-enter`.

Manual entry:

```bash
limactl shell agent-sandbox
```

If you need Homebrew tools on `PATH` in a plain bash shell:

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
/home/lima/repo
```

The copy:

- Includes `.git/` so you can commit inside the VM
- Includes uncommitted files
- Copies everything by default
- Optionally excludes files via `--ignore-file`

### Ignore file (optional)

By default, the repo copy includes everything. To exclude files, pass an explicit ignore file (syntax matches `.gitignore`):

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

Git identity and shell tooling are provisioned inside the VM via your dotfiles bootstrap (runs from `lima.yaml`).

Verify inside the VM:

```bash
git config --get user.name
git config --get user.email
```

### Run agent

```bash
limactl shell agent-sandbox -- opencode run
```

### Copy repo out of the VM

Use `./copy-out.sh` to extract the VM repo onto the host (defaults to `~/dev/lima-repo`, replacing any existing folder):

```bash
./copy-out.sh --name agent-sandbox
```

Override destination and output folder name:

```bash
./copy-out.sh --dest-dir ~/dev --out-name gemhog-repo
```

## Notes

- No host mounts (`mounts: []`); all data transfer is explicit.
- Port forwarding is disabled for all ports except SSH.
- Updating `lima.yaml` does not change an existing instance config; recreate the instance to apply provisioning changes.

## License

MIT (see `LICENSE`).
