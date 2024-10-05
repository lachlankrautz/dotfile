# dotfile

Cross-platform dotfile manager - Linux, macOS and Windows (msys2|wsl)

# Features

- Sync config to home dir and /root home dir (optional)
- Cross-platform links; `mklink [/D]` for windows, `ln -s` everywhere else
- Import existing dotfile(s) into config dir
- Backup existing files before replacing with links
- Sync different files for different systems using repo groups (shared|msys|wsl|macos|linux|root)
- Preview without making changes using `-p`, `--preview`

# Install

Link the script into the PATH.

```shell
sudo make install
```

# Setup

- Edit config ~/.config/dotfile/config.ini
- Import dotfiles into config repo 

```shell
dotfile import .emacs.d/init.el
```

# Usage

Run `import` to move a local dotfile into the config dir and create
a link so that the local dotfile now points to the synced config.

```shell
dotfile import .emacs.d/init.el
```

Preview sync dotfiles (no writes).

```shell
dotfile -p sync
```

Sync dotfiles.

```shell
dotfile sync
```
