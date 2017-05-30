# dotfile

Cross platform dotfile manager supporting Linux and Windows (msys2)

# Features
- Sync config to home dir and /root home dir (optional)
- Cross platform system links; "mklink [/D]" on Windows, "ln -s" on Linux
- Import existing home file(s) into config
- Auto backup existing files before linking
- Share between systems or override files with groups (shared/windows/linux/root)
- Demo sync without making changes using "status"
- Clone git config repo (optional)

# Setup
- Clone dotfile
```
$ git clone git@github.com:lachlankrautz/dotfile

```
- Add bin/dotfile to path (optional)
```
$ ln -s $(pwd)/dotfile/bin/dotfile /usr/local/bin

```
- Run "dotfile" to generate config file
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
