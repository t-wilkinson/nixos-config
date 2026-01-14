function paste --description "Paste from system clipboard (wl-paste / pbpaste)"
    set os (uname)

    switch $os
        case Darwin
            if not type -q pbpaste
                echo "paste: pbpaste not found" >&2
                return 1
            end
            pbpaste

        case Linux
            if type -q wl-paste
                # --no-newline avoids wl-paste appending a newline
                wl-paste --no-newline
            else if type -q xclip
                xclip -selection clipboard -o
            else
                echo "paste: wl-paste or xclip not found" >&2
                return 1
            end

        case '*'
            echo "paste: unsupported OS ($os)" >&2
            return 1
    end
end
