# Scripts
Some scripts I find useful.

## prj
My favorite is `prj`. This is a simple (for now), high-level CLI that manages your git repositories.

It enables downloading them, and searching existing repositories. If you have `fzf`, you can run `prj fzf` which pipes results into `fzf`. This allows you, for example, to run `cd $(prj fzf)` which allows you to fuzzy search your repositories, then cd to it.

## browser-profiles
This allows you to run multiple browser profiles with the same utiliy. It uses a config file with lines formated as `<profile>=<browser>`.

It is called as `browser-profiles <profile>` then runs its associated browser in `~/.local/share/browser-profiles/<profile>`.

## Notes
This is free to use.
