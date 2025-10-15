{ pkgs, inputs, ... }:
let
  gtk-theme = "adw-gtk3-dark";

  moreWaita = pkgs.stdenv.mkDerivation {
    name = "MoreWaita";
    src = inputs.more-waita;
    installPhase = ''
      mkdir -p $out/share/icons
      mv * $out/share/icons
    '';
  };

  nerdfonts = with pkgs.nerd-fonts; [
    ubuntu
    ubuntu-mono
    caskaydia-cove
    fantasque-sans-mono
    jetbrains-mono
    fira-code
    mononoki
    space-mono
  ];

  google-fonts = (
    pkgs.google-fonts.override {
      fonts = [
        # Sans
        "Gabarito"
        "Lexend"
        # Serif
        "Chakra Petch"
        "Crimson Text"
      ];
    }
  );

  cursor-theme = "Bibata-Modern-Classic";
  cursor-package = pkgs.bibata-cursors;
in
{
  fonts.fontconfig.enable = true;
  home = {
    packages =
      with pkgs;
      [
        # themes
        adwaita-qt6
        adw-gtk3
        material-symbols
        noto-fonts
        noto-fonts-cjk-sans
        google-fonts
        moreWaita
        bibata-cursors
        # morewaita-icon-theme
        # papirus-icon-theme
        # qogir-icon-theme
        # whitesur-icon-theme
        # colloid-icon-theme
        # qogir-theme
        # yaru-theme
        # whitesur-gtk-theme
        # orchis-theme
      ]
      ++ nerdfonts;
    sessionVariables = {
      XCURSOR_THEME = cursor-theme;
      XCURSOR_SIZE = "24";
    };
    pointerCursor = {
      package = cursor-package;
      name = cursor-theme;
      size = 24;
      gtk.enable = true;
    };
    file = {
      # ".local/share/fonts" = {
      #   recursive = true;
      #   source = "${nerdfonts}/share/fonts/truetype/NerdFonts";
      # };
      # ".fonts" = {
      #   recursive = true;
      #   source = "${nerdfonts}/share/fonts/truetype/NerdFonts";
      # };
      # ".config/gtk-4.0/gtk.css" = {
      #   text = ''
      #     window.messagedialog .response-area > button,
      #     window.dialog.message .dialog-action-area > button,
      #     .background.csd{
      #       border-radius: 0;
      #     }
      #   '';
      # };
      ".local/share/icons/MoreWaita" = {
        source = "${moreWaita}/share/icons";
      };
    };
  };

  gtk = {
    enable = true;
    font.name = "Rubik";
    theme.name = gtk-theme;
    cursorTheme = {
      name = cursor-theme;
      package = cursor-package;
    };
    iconTheme.name = moreWaita.name;
    gtk3.extraCss = ''
      headerbar, .titlebar,
      .csd:not(.popup):not(tooltip):not(messagedialog) decoration{
        border-radius: 0;
      }
    '';
  };

  qt = {
    enable = true;
    platformTheme.name = "kde";
  };
}
