# dotfile

Cross platform dotfile manager supporting Linux and Windows (msys2)

# Features
- Clone git repo holding dotfiles
- Sync dotfiles to home dir and /root home dir (optional)
- Use mklink [/D] on windows or ln -s on linux
- Display status of all linked files
- Import files (pattern) from home into git repo
- Share files accross platforms or override specific files using groups (shared/windows/root)

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
