# dotfile

Cross platform dotfile manager supporting Linux and Windows (msys2)

# Features
- Sync dotfiles to home dir and /root home dir (optional)
- Uses "mklink [/D]" on Windows or "ln -s" on Linux
- Automatically creates backups of existing files before replacing with links
- Import file (pattern) from home into git repo
- Share files across platforms or override specific files using groups (shared/windows/linux/root)
- Display status of all linked files
- Clone git config repo (optional)

# Setup
- Clone dotfile
```
$ git clone git@github.com:lachlankrautz/dotfile

```
- Add bin/dotfile to path (optional)
```
$ ln -s $(pwd)/bin/dotfile /usr/local/bin

```
- Run "dotfile" to generate config file
```
$ dotfile
                      _____
    _________  ____  / __(_)___ _
   / ___/ __ \/ __ \/ /_/ / __ `/
  / /__/ /_/ / / / / __/ / /_/ /
  \___/\____/_/ /_/_/ /_/\__, /
                        /____/

WARNING: Config incomplete - local
==> Edit your local config file: ~/dev/bash/dotfile/config/local.ini
==> Mark "local_config_loaded=1" when finished

```
- Set "git_repo" in config/local.ini (optional)
- Set "local_config_loaded=1" to confirm current config
- Run "dotfile status" to see what repo files will get linked on sync
- Run "dotfile sync" to link config files to home

# Usage

```
         __      __  _____ __
    ____/ /___  / /_/ __(_) /__
   / __  / __ \/ __/ /_/ / / _ \ 
  / /_/ / /_/ / /_/ __/ / /  __/
  \__,_/\____/\__/_/ /_/_/\___/

Usage:
  dotfile [options] [command] [args]

Options:
  -h, --help                   Display usage
  -v, --version                Display version

Commands:
  sync                         Sync repo groups to home
  status                       Demo sync without making changes
  import [<pattern>] [<group>] Import home to repo group (default "shared")
```

# Example

```
$ dotfile status
           __        __
     _____/ /_____ _/ /___  _______
    / ___/ __/ __ `/ __/ / / / ___/
   (__  ) /_/ /_/ / /_/ /_/ (__  )
  /____/\__/\__,_/\__/\__,_/____/

:: Filesystem
==> Confirmed home dir ~
==> Confirmed config dir ~/config
==> Confirmed backup dir ~/config/backup_home

:: Config repo
==> Confirmed config repo ~/config/my-config
==> Confirmed group ~/config/my-config/shared
==> Confirmed group ~/config/my-config/windows

:: Sync ~
==> Dir summary
           Home: ~
    Config repo: ~/config/my-config/(windows|shared)
         Backup: ~/config/backup_home
==> File summary
         Linked: .bashrc (windows)
         Linked: .bash_profile (windows)
         Linked: .minttyrc (windows)
         Linked: .aws
         Linked: .dir_colors
         Linked: .emacs.d
         Linked: .gitconfig
         Linked: .gitignore_global
         Linked: .m2


```
