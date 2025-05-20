function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting

end

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

# function prompt_newline --on-event fish_postexec
# 	echo
# end

function ssh --wraps ssh
    TERM=xterm-256color command ssh $argv
end

alias pamcan=pacman
alias v=nvim
alias vim=nvim
alias ls="eza --icons=always"
alias z=zoxide

# function fish_prompt
#   set_color cyan; echo (pwd)
#   set_color green; echo '> '
# end

set -gx EDITOR nvim

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
zoxide init fish | source
