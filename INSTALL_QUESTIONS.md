=== Questions for Grilling Skill ===

Q1: Which tools should be REQUIRED vs OPTIONAL in each scenario?
- REQUIRED: git, bash, coreutils, curl, unzip, zip, jq, file, rsync
- OPTIONAL_DEV: neovim, ripgrep, fd, bat, zoxide, fzf, tree, htop, eza, delta
- ANACRON_DEPENDS: anacron, cronie

Q2: What file structure exists in repo to install/link?
- Current state: install.sh, install_anacron.sh, README.md
- Need to define what configs to create: bashrc, zshenv, gitconfig, etc.

Q3: Flakes or classic Nix?
- Support flakes if flake.nix exists
- Support classic nix config if nix.conf exists
- Auto-detect from /nix/store and $HOME/.nix-profile

Q4: Bash, zsh, or auto-detect?
- Detect $SHELL env var
- If bash: configure ~/.bashrc
- If zsh: configure ~/.zshenv + ~/.zprofile
- If unknown: install zsh or auto-detect

Q5: Git integration on config dir?
- Create ~/.config/.gitignore
- enable git restore on pull
- Respect .gitignore patterns
- Add git aliases: gp=git push, gp=git pull

Q6: Anacron required or optional per scenario?
- Nix: optional (nix-init.sh handles services)
- Devcontainer: skip (systemd-run or crontab)
- Standard Linux: optional with --skip-anacron flag
- Default: install-anacron unless --skip-anacron

Q7: Auto-detect vs interactive?
- Default: interactive prompts
- --quiet: auto-detect, install required, warn skipped optional
- --skip-optional: skip all optional packages
- --skip-anacron: skip anacron installation
