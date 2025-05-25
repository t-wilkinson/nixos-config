function __prj_complete_commands
    echo 'init install uninstall ls status pull push cd tree alias unalias tag untag export import search-remote sync fzf completion'
end

complete -c prj -n "__fish_is_first_arg" -a "(__prj_complete_commands)" -d "prj subcommands"
# complete -c prj -n "not __fish_is_first_arg; and contains -- (commandline -opc)[1] status pull push cd alias unalias tag untag" -a "(__prj_complete_projects)" -d "Project/Alias/Author"
# Add more specific completions below
complete -c prj -s h -l help -d "Show help"
# Example for 'status' options:
complete -c prj -A -x -c status -s a -l all -d "Show status for all projects, even clean"
complete -c prj -A -x -c push -s m -l message -r -d "Commit message before pushing"

# To use, save the above to ~/.config/fish/completions/prj.fish
