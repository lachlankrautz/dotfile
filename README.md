# dotfile

Cross platform dotfile manager - Linux, OSX and Windows (msys2)

# Features
- Sync config to home dir and /root home dir (optional)
- Cross platform system links; `mklink [/D]` or `ln -s`
- Import existing dotfile(s) into config dir
- Backup existing files before replacing with links
- Sync different files for different systems using repo groups (shared/windows/osx/linux/root)
- Preview without making changes using `-p`, `--preview`
- Clean broken links on out of date system
- Push config to remote host and sync

# Install
```
$ bash <(curl -s https://raw.githubusercontent.com/lachlankrautz/dotfile/master/bin/install)
```

# Setup
- Edit config ~/.config/dotfile/config.ini
- Import dotfiles into config repo "dotfile import .emacs.d/init.el"
- Preview sync action "dotfile --preview sync"
- Run sync "dotfile sync"

# Usage

```
$ dotfile

```

# Example

```
$ dotfile sync

```
