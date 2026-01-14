if test (uname) = Darwin
    set -x TMPDIR (getconf DARWIN_USER_TEMP_DIR)
end

# function fish_prompt -d "Write out the prompt"
#     # USER@HOST /home/user/ >
#     printf '%s@%s %s%s%s > ' $USER $hostname \
#         (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
# end

if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting

    starship init fish | source
    if test -f ~/.cache/ags/user/generated/terminal/sequences.txt
        cat ~/.cache/ags/user/generated/terminal/sequences.txt
    end

    function starship_transient_prompt_func
        # tput cuu1 # Move cursor up one line to remove newline after transient prompt
        set_color 8BE9FD
        echo "❯ "
    end

    function starship_transient_rprompt_func
        # starship module time
    end

    enable_transience

end

zoxide init fish | source

# normal file complete on zoxide with no space
function __my_zoxide_z_complete
    set -l tokens (commandline --current-process --tokenize)
    set -l curr_tokens (commandline --cut-at-cursor --current-process --tokenize)

    if test (count $tokens) -le 2 -a (count $curr_tokens) -eq 1
        set -l query $tokens[2..-1]
        zoxide query --exclude (__zoxide_pwd) --list -- $query
    else
        __zoxide_z_complete
    end
end
complete --erase --command __zoxide_z
complete --command __zoxide_z --no-files --arguments '(__my_zoxide_z_complete)'

fzf --fish | source

# function prompt_newline --on-event fish_postexec
# 	echo
# end

function ssh --wraps ssh
    TERM=xterm-256color command ssh $argv
end

function set_zellij_tab_title --on-variable PWD
    if test -n "$ZELLIJ"
        set -l git_dir (git rev-parse --show-toplevel 2>/dev/null)
        if test -n "$git_dir"
            set -l dir_name (basename "$git_dir")
            zellij action rename-tab "$dir_name"
        else
            # set -l short_path (fish_short_pwd)
            # zellij action rename-tab "$short_path"
        end
    end
end

function hgrep
    # Grep, highlighting the matches, keep the same output
    grep --color=always -z $argv
end

function prjcd
    cd $(prj cd "$argv")
end

alias pamcan=pacman
alias v=nvim
alias vim=nvim
alias fv="nvim \$(fzf)"
alias gp="git add -A && git commit -m 'made changes' && git push"

alias ls="eza --icons=always --grid"
# alias ls='eza'
# alias l='eza -lbF --git'
# alias ll='eza -lbGF --git'
# alias la='eza -lbhHigUmuSa --git --color-scale'
alias lt='eza --tree --level=2'

set -gx EDITOR nvim
set -gx PAGER less
set -gx PAGER "bat --paging=always"
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
set -gx MANROFFOPT -c

set -gx LESS -SXIRFs
# -S: chop lines, side scroll with left/right arrow keys
# -X: leave contents on screen when less exits
# -I: ignore case when searching with / or ?
# -F: quit immediately when the entire file fits in one screen
# -R: enable colored output
# -s: squeeze blank lines into a single blank line

# rose-pine-dawn fzf theme
# set -Ux FZF_DEFAULT_OPTS "
# 	--color=fg:#797593,bg:#faf4ed,hl:#d7827e
# 	--color=fg+:#575279,bg+:#f2e9e1,hl+:#d7827e
# 	--color=border:#dfdad9,header:#286983,gutter:#faf4ed
# 	--color=spinner:#ea9d34,info:#56949f
# 	--color=pointer:#907aa9,marker:#b4637a,prompt:#797593"
# rose-pine-moon fzf theme
set -Ux FZF_DEFAULT_OPTS "
	--color=fg:#908caa,bg:#232136,hl:#ea9a97
	--color=fg+:#e0def4,bg+:#393552,hl+:#ea9a97
	--color=border:#44415a,header:#3e8fb0,gutter:#232136
	--color=spinner:#f6c177,info:#9ccfd8
	--color=pointer:#c4a7e7,marker:#eb6f92,prompt:#908caa"
# rose-pine fzf theme
# set -Ux FZF_DEFAULT_OPTS "
# 	--color=fg:#908caa,bg:#191724,hl:#ebbcba
# 	--color=fg+:#e0def4,bg+:#26233a,hl+:#ebbcba
# 	--color=border:#403d52,header:#31748f,gutter:#191724
# 	--color=spinner:#f6c177,info:#9ccfd8
# 	--color=pointer:#c4a7e7,marker:#eb6f92,prompt:#908caa"

fish_add_path "$HOME/dev/t-wilkinson/projects/scripts"
