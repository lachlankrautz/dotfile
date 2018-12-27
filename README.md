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
         __      __  _____ __
    ____/ /___  / /_/ __(_) /__
   / __  / __ \/ __/ /_/ / / _ \
  / /_/ / /_/ / /_/ __/ / /  __/
  \__,_/\____/\__/_/ /_/_/\___/

Usage:
  dotfile [options] <command> <args>

Options:
  -h, --help               Display usage
  -v, --version            Display version
  -p, --preview            Preview changes

Commands:
  sync                     Sync repo groups to home
  import <pattern> <group> Import home to repo group (default "shared")
  push   <user@host>       Push config to remote host and sync
  clean                    Remove broken repo links
```

# Example

```
$ dotfile sync
     _______  ______  _____
    / ___/ / / / __ \/ ___/
   (__  ) /_/ / / / / /__
  /____/\__, /_/ /_/\___/
       /____/

:: Dotfiles git@notime.co:config
==> Found config ~/config
==> Found backup ~/.config/dotfile/backup_home
==> Found shared group ~/config/shared
==> Found windows group ~/config/windows
==> Found nesting file ~/config/nesting_list.txt

:: Sync ~
==> Summary:
           Home: ~
         Config: ~/config/(windows|shared)
         Backup: ~/.config/dotfile/backup_home
==> Links:
         Linked: .bashrc (windows)
         Linked: .bash_profile (windows)
         Linked: .docker/config.json (windows)
         Linked: .minttyrc (windows)
         Linked: .aws
         Linked: .composer/auth.json
         Linked: .conan/registry.txt
         Linked: .dir_colors
         Linked: .emacs.d/conf
         Linked: .emacs.d/init.el
         Linked: .gitconfig
         Linked: .gitignore_global
         Linked: .httpie/config.json
         Linked: .m2/archetype-catalog.xml
         Linked: .m2/settings.xml
         Linked: .npmrc
         Linked: .purple
         Linked: .ssh/config
         Linked: .tmux.conf
```
