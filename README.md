# dotfile

Cross platform dotfile manager supporting Linux and Windows (msys2)

# Features
- Sync config to home dir and /root home dir (optional)
- Cross platform system links; "mklink [/D]" on Windows, "ln -s" on Linux
- Import existing home file(s) into config
- Auto backup existing files before linking
- Share between systems or override files with groups (shared/windows/linux/root)
- Preview without making changes using "-p, --preview"

# Install
```
$ bash <(curl -s https://raw.githubusercontent.com/lachlankrautz/dotfile/master/install.sh)
```

# Setup
- Confirm config in ~/config/dotfile/config.ini
- Run "dotfile --preview sync" to see what repo files will get linked
- Run "dotfile sync" to link config files to home

# Usage

```
$ dotfile
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
  -p, --preview                Preview changes

Commands:
  sync                         Sync repo groups to home
  import [<pattern>] [<group>] Import home to repo group (default "shared")
  clean                        Remove broken repo links

```

# Example

```
$ dotfile sync
     _______  ______  _____
    / ___/ / / / __ \/ ___/
   (__  ) /_/ / / / / /__
  /____/\__, /_/ /_/\___/
       /____/

:: Filesystem
==> Confirmed config dir ~/config
==> Confirmed backup dir ~/config/backup_home

:: Config repo
==> Confirmed config repo ~/config/my-config
==> Confirmed group ~/config/my-config/shared
==> Confirmed group ~/config/my-config/windows
==> Confirmed nesting file ~/config/my-config/nesting_list.txt

:: Sync /home/lach
==> Dir summary
           Home: /home/lach
    Config repo: /home/lach/config/my-config/(windows|shared)
         Backup: /home/lach/config/backup_home
==> File summary
         Linked: .bashrc (windows)
         Linked: .bash_profile (windows)
         Linked: .minttyrc (windows)
         Linked: .aws
         Linked: .dir_colors
         Linked: .emacs.d/conf
         Linked: .emacs.d/init.el
         Linked: .gitconfig
         Linked: .gitignore_global
         Linked: .m2/archetype-catalog.xml
         Linked: .m2/settings.xml
         Linked: .ssh/config

```
