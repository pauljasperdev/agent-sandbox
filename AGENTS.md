# Agent sandbox repo notes

This repo provisions an isolated Lima VM intended for agentic workflows.

## Principles

- Prefer provisioning via `pauljasperdev/dotfiles`.
- Keep `lima.yaml` system provisioning minimal (only bootstrapping prerequisites).
- Avoid copying host config into the VM (no host mounts, no host git config, no SSH keys).

## Dotfiles provisioning

- `lima.yaml` user provisioning clones `https://github.com/pauljasperdev/dotfiles` to `~/.dotfiles`.
- Dotfiles are applied via `~/.dotfiles/.bootstrap.move.sh` then bootstrapped via `~/.bootstrap.debian.sh`.
- The dotfiles repo is converted into a git-dir-only setup after move; use the dotfiles alias pattern:

```sh
alias dotfiles='git --git-dir="$HOME/.dotfiles/.git" --work-tree="$HOME"'
```

## Applying changes

- Provisioning changes in `lima.yaml` require recreating the VM:

```sh
limactl delete agent-sandbox
limactl start --name agent-sandbox ./lima.yaml
```
