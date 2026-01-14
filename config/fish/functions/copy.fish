function copy --description "Copy stdin or arguments to system clipboard"
    if test (count $argv) -gt 0
        set input (string join " " $argv)
    else
        set input ""
    end

    set os (uname)

    switch $os
        case Darwin
            type -q pbcopy; or begin
                echo "copy: pbcopy not found" >&2
                return 1
            end
            printf "%s" "$input" | pbcopy

        case Linux
            if type -q wl-copy
                printf "%s" "$input" | wl-copy
            else if type -q xclip
                printf "%s" "$input" | xclip -selection clipboard
            else
                echo "copy: wl-copy or xclip not found" >&2
                return 1
            end

        case '*'
            echo "copy: unsupported OS ($os)" >&2
            return 1
    end
end
