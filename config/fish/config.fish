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

# function fish_prompt
#   set_color cyan; echo (pwd)
#   set_color green; echo '> '
# end

set -gx EDITOR nvim
