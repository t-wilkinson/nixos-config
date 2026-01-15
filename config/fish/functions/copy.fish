function copy --description "Copy stdin or arguments to system clipboard"
    set os (uname)

    if test (count $argv) -gt 0
        set input (string join " " $argv)
    else
        # Read stdin line-by-line AFTER pipe is attached
        set input ""
        while read -l line
            set input "$input$line\n"
        end
    end

    switch $os
        case Darwin
            if not type -q pbcopy
                echo "copy: pbcopy not found" >&2
                return 1
            end
            printf "%s" "$input" | pbcopy

        case Linux
            if type -q wl-copy
                printf "%s" "$input" | wl-copy --foreground
            else if type -q xclip
                if not set -q DISPLAY
                    echo "copy: DISPLAY not set (xclip requires X11)" >&2
                    return 1
                end
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
