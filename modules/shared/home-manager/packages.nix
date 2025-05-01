{ pkgs, ... }: 
with pkgs; [
  # GAMES
  # minecraft
  # unstable.lunar-client
  # steam

  # DESIGN
  # blender
  # figma-linux
  gimp
  inkscape
  # kolourpaint
  # pinta
  # krinta

  # GUI
  vlc
  # vscode
  # okular
  # reaper

  # PHP
  php82
  php82Packages.composer
  php82Packages.php-cs-fixer
  php82Extensions.xdebug
  php82Packages.deployer
  phpunit

  # NODE.JS DEVELOPMENT TOOLS
  fzf
  nodePackages.live-server
  nodePackages.nodemon
  nodePackages.prettier
  nodePackages.npm
  nodejs

  # PYTHON PACKAGES
  black
  python3
  virtualenv

  # CLOUD/DEVOPS
  # docker
  # docker-compose
  # awscli2 - marked broken Mar 22
  flyctl
  google-cloud-sdk
  go
  gopls
  ngrok
  ssm-session-manager-plugin
  terraform
  terraform-ls
  tflint

];
