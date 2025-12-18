# INSTALL script to run after fresh linux install
# NOTE:
#   run everything in subshell to prevent unwanted effects

set -e

# Primary install function
I() {
    yay -S --quiet --noconfirm "$@"
}

install_core() (
    pacman -S base base-devel linux linux-headers linux-firmware bash-completion man-pages texinfo vi git wget networkmanager dkms
)

install_useradd() (
    user=$1
    if [[ -z $user ]]; then
        echo -n 'username: '
        read user
    fi

    useradd -m $user
    passwd $user
)

install_usermod() (
    user=$1
    if [[ -z $user ]]; then
        echo -n 'username: '
        read user
    fi

    usermod -aG systemd-journal,audio,video,wheel,network $user
)

# at this point user should login
install_yay() (
    (cd /tmp && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si)
)

install_nix() (
    curl -L https://nixos.org/nix/install | sh
)

install_mirrors() (
    echo speed up mirrors
    I pacman-contrib
    country=${1:-US}
    curl -s "https://www.archlinux.org/mirrorlist/?country=${country}&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - > /etc/pacmand.d/mirrorlist
)

install_packages() (
    while [[ $# > 0 ]]; do
        case $1 in
           graphics)     I xorg xorg-server xorg-xinit intel-ucode xf86-video-intel nvidia nvidia-utils nvidia-dkms
        ;; system)       I acpi parted lsof lshw dmidecode
        ;; admin)        I cronie
        ;; debugging)    I openssh usbutils htop strace rsync tree inxi
        ;; network)      I iperf3 arp-scan iw bind bind-tools nmap tcpdump ufw inetutils
        ;; terminal)     I fd ripgrep fzf zsh neovim openssh bat tmux neofetch
        ;; fonts)        I ttf-fira-code ttf-meslo-nerd-font-powerlevel10k
        ;; security)     I pass gnupg
        ;; gui)          I xclip xsel xcape xbanish notification-daemon rofi picom
        ;; graphics)     I inkscape gimp feh qimgv
        ;; pdf)          I zathura zathura-pdf-mupdf zathura-ps zathura-cb zathura-djvu
        ;; latex)        I texlive-bin texlive-core texlive-most
        ;; web-server)   I nginx ngrok certbot
        ;; audio)        I alsa-utils pulseaudio pulseaudio-alsa pulseaudio-jack ponymix && pulseaudio --start
        ;; misc)         I mpv youtube-dl zip unzip brotli inotify-tools
        ;; virtualbox)   I virtualbox virtualbox-host-dkms-arch xf86-video-vmware
        ;; cuda)         I cuda cuda-tools # python-pytorch-cuda might be necessary to install as well
        ;; arduino)      I arduino arduino-cli arduino-docs arduino-avr-core && arduino-cli core install arduino:avr
        ;; samsung)      I android-file-transfer
        ;; calc)         I calc clac
        ;; pandoc)       I pandoc pandoc-crossref
        ;; recomendations) cat<<EOF
https://github.com/tmux-plugins/tpm
https://github.com/sorin-ionescu/prezto
https://github.com/junegunn/vim-plug
https://imagemagick.org/index.php
EOF
        ;; *) ;;
        esac
    done

)

install_color() {
    sed -i 's/^#Color$/Color/' /etc/pacman.conf
}

install_kitty() (
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
)

install_xmonad() (
    I xmonad xmonad-contrib
    xmonad --recompile
)

install_nvidia() (
    cat << EOF > /etc/X11/xorg.conf.d/10-nvidia-drm-outputclass.conf
Section "OutputClass"
    Identifier "intel"
    MatchDriver "i915"
    Driver "modesetting"
EndSection

Section "OutputClass"
    Identifier "nvidia"
    MatchDriver "nvidia-drm"
    Driver "nvidia"
    Option "AllowEmptyInitialConfiguration"
    Option "PrimaryGPU" "yes"
    ModulePath "/usr/lib/nvidia/xorg"
    ModulePath "/usr/lib/xorg/modules"
EndSection
EOF
)

install_nvimplug() (
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
          https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
)

install_zprezto() (
    zsh << EOF
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do # syntax error at (
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done
chsh -s /bin/zsh
EOF
)

install_dotfiles() (
    mkdir -p $HOME/dev
    git clone https://github.com/t-wilkinson/dotfiles $HOME/dev
    $HOME/dev/scripts/link.sh
)

#install_cron() (
#    echo CRON.D - BACKUP

#    mkdir -p /etc/cron.d
#    sudo tee /etc/cron.d/backup << EOF > /dev/null
##!/bin/sh
#DAY=$(date +%A)
#if [ -e /mnt/backup/incr/$DAY ] ; then
#    rm -rf /mnt/backup/incr/$DAY
#fi
#h="/home/trey"
#rsync -aAXv --delete --quiet --inplace --exclude={"/nix/*","/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found","$h/.cache","$h/.npm","$h/.stack","$h/.mu","$h/.mail","$h/.cabal"} --backup --backup-dir=/mnt/backup/incr/$DAY / /mnt/backup/full/
#EOF
#    sudo chmod +x /etc/cron.d/backup
#)

while [[ $# > 0 ]]; do
    case $1 in
        -h)
            echo -n 'OPTIONS: '
            for func in $(declare -F | grep install_ | tac | sed -e 's/^.*install_\(\w*\)$/\1/'); do
                echo -n "$func, "
            done
            echo $'\b\b'"   "
            exit
            ;;
        all)
            for func in $(declare -F | grep install_ | tac | sed -e 's/^.*install_\(\w*\)$/\1/'); do
                echo $func
                install_$func
            done
            exit
            ;;
        packages)
            shift
            install_packages "$@"
            exit
            ;;
        *) install_$1;;
    esac
    shift
done

