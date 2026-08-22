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
      # Let focused applications receive physical Super+number combinations.
      # Graphical Emacs maps the physical Super key to Meta.
      hot-keys = false;
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

    # Avoid physical Super shortcuts that would prevent graphical Emacs from
    # receiving its remapped Meta combinations. Retain conventional non-Super
    # alternatives for desktop window management.
    "org/gnome/desktop/wm/keybindings" = {
      activate-window-menu = [ "<Shift><Alt>F10" ];
      close = [ "<Alt>F4" ];
      minimize = [ "<Alt>F9" ];
      # Keep physical Super+Space available as Emacs Meta+Space, and physical
      # Alt+Space available as the Emacs Super+Space leader.
      switch-input-source = [ "<Control><Alt>space" ];
      switch-input-source-backward = [ "<Shift><Control><Alt>space" ];
      switch-applications = [ "<Alt>Tab" ];
      switch-applications-backward = [ "<Shift><Alt>Tab" ];
      switch-group = [ "<Alt>grave" ];
      switch-group-backward = [ "<Shift><Alt>grave" ];
      toggle-fullscreen = [ "F11" ];
    };

    # GNOME/Ubuntu otherwise grabs these before a focused Emacs frame sees
    # them. Super alone still opens Activities, while physical Super+S and
    # Super+number combinations are available as Emacs Meta bindings.
    "org/gnome/shell/keybindings" = {
      toggle-overview = [ ];
      switch-to-application-1 = [ ];
      switch-to-application-2 = [ ];
      switch-to-application-3 = [ ];
      switch-to-application-4 = [ ];
      switch-to-application-5 = [ ];
      switch-to-application-6 = [ ];
      switch-to-application-7 = [ ];
      switch-to-application-8 = [ ];
      switch-to-application-9 = [ ];
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      area-screenshot = [ "<Shift>Print" ];
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/alacritty/"
      ];
      screenshot = [ "Print" ];
      screensaver = [ "<Control><Alt>Delete" ];
      # GNOME normally reserves physical Super+P, which graphical Emacs maps
      # to its Meta+P perspective prefix. Keep display switching elsewhere.
      video-out = [ "<Control><Alt>p" ];
      window-screenshot = [ "<Alt>Print" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/alacritty" = {
      binding = "<Control><Alt>Return";
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
