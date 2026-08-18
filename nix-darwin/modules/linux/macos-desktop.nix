{ config, pkgs, ... }:

let
  # Build only the dark, non-solid variant used by this profile instead of all
  # WhiteSur combinations.
  whiteSurGtk = pkgs.whitesur-gtk-theme.override {
    colorVariants = [ "dark" ];
    opacityVariants = [ "normal" ];
  };
in
{
  home.packages = with pkgs; [
    dconf-editor
    gnome-tweaks
  ];

  fonts.fontconfig = {
    antialiasing = true;
    defaultFonts = {
      emoji = [ "Noto Color Emoji" ];
      monospace = [ "MesloLGS NF" ];
      sansSerif = [ "Inter" ];
      serif = [ "Noto Serif" ];
    };
    hinting = "slight";
  };

  # WhiteSur supplies macOS-inspired controls, icons, and pointers. Inter is a
  # redistributable system font with similar proportions to San Francisco.
  gtk = {
    enable = true;
    colorScheme = "dark";
    font = {
      name = "Inter";
      package = pkgs.inter;
      size = 11;
    };
    cursorTheme = {
      name = "WhiteSur-cursors";
      package = pkgs.whitesur-cursors;
      size = 24;
    };
    iconTheme = {
      name = "WhiteSur-dark";
      package = pkgs.whitesur-icon-theme;
    };
    theme = {
      name = "WhiteSur-Dark";
      package = whiteSurGtk;
    };
    gtk4.theme = config.gtk.theme;
  };

  # Keep Qt applications visually consistent with the GTK/GNOME session.
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    x11.enable = true;
    name = "WhiteSur-cursors";
    package = pkgs.whitesur-cursors;
    size = 24;
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      enable-animations = true;
      enable-hot-corners = true;
      clock-show-weekday = true;
      document-font-name = "Inter 11";
      monospace-font-name = "MesloLGS NF 11";
      show-battery-percentage = true;
    };

    # Put the traffic-light-style controls on the left and retain familiar
    # maximize behavior when double-clicking a title bar.
    "org/gnome/desktop/wm/preferences" = {
      action-double-click-titlebar = "toggle-maximize";
      button-layout = "close,minimize,maximize:";
      focus-mode = "click";
      resize-with-right-button = true;
      titlebar-font = "Inter Bold 11";
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      click-method = "fingers";
      disable-while-typing = true;
      natural-scroll = true;
      speed = 0.2;
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
    };

    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "adaptive";
      natural-scroll = true;
      speed = 0.0;
    };

    "org/gnome/mutter" = {
      center-new-windows = true;
      dynamic-workspaces = true;
      edge-tiling = true;
      workspaces-only-on-primary = true;
    };

    # Ubuntu Dock is based on Dash to Dock and uses the same settings. Keep the
    # compact, centered bottom dock visible like the default macOS Dock.
    "org/gnome/shell/extensions/dash-to-dock" = {
      autohide = false;
      background-opacity = 0.8;
      click-action = "minimize-or-previews";
      custom-theme-shrink = true;
      dash-max-icon-size = 48;
      dock-fixed = true;
      dock-position = "BOTTOM";
      extend-height = false;
      intellihide = false;
      intellihide-mode = "ALL_WINDOWS";
      multi-monitor = true;
      running-indicator-style = "DOTS";
      scroll-action = "cycle-windows";
      show-apps-at-top = false;
      show-favorites = true;
      show-mounts = true;
      show-running = true;
      show-trash = true;
      transparency-mode = "DYNAMIC";
    };

    # Super acts as the closest GNOME equivalent to Command for window
    # management. Existing Alt shortcuts remain available during migration.
    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Super>w" "<Alt>F4" ];
      minimize = [ "<Super>m" ];
      switch-applications = [ "<Super>Tab" "<Alt>Tab" ];
      switch-applications-backward = [ "<Shift><Super>Tab" "<Shift><Alt>Tab" ];
      switch-group = [ "<Super>grave" "<Alt>grave" ];
      switch-group-backward = [ "<Shift><Super>grave" "<Shift><Alt>grave" ];
      toggle-fullscreen = [ "<Control><Super>f" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      area-screenshot = [ "<Shift>Print" "<Shift><Super>4" ];
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/alacritty/"
      ];
      screenshot = [ "Print" "<Shift><Super>3" ];
      screensaver = [ "<Super>l" "<Control><Super>q" ];
      window-screenshot = [ "<Alt>Print" "<Shift><Super>5" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/alacritty" = {
      binding = "<Super>Return";
      command = "${pkgs.alacritty}/bin/alacritty";
      name = "Open Terminal";
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "icon-view";
      show-create-link = true;
      show-delete-permanently = false;
    };

    "org/gnome/nautilus/icon-view" = {
      default-zoom-level = "medium";
    };

    "org/gtk/settings/file-chooser" = {
      show-hidden = false;
      sort-directories-first = true;
    };
  };
}
