[
  # These replace matching macOS casks on Ubuntu. `systems` defaults to every
  # supported Linux architecture, `channel` defaults to latest/stable, and
  # strict confinement is used unless `classic` is true.
  {
    name = "brave";
    cask = "brave-browser";
  }
  {
    name = "code";
    cask = "visual-studio-code";
    classic = true;
  }
  {
    name = "firefox";
    cask = "firefox";
  }
  {
    name = "flutter";
    cask = "flutter";
    classic = true;
  }
  {
    name = "gimp";
    cask = "gimp";
  }
  {
    name = "opera";
    cask = "opera";
    systems = [ "x86_64-linux" ];
  }
  {
    name = "slack";
    cask = "slack";
    systems = [ "x86_64-linux" ];
  }
  {
    name = "telegram-desktop";
    cask = "telegram";
  }
  {
    name = "chatgpt-desktop";
    cask = "chatgpt";
  }
  {
    name = "chromium";
    cask = "chromium";
  }

  # Community or unofficial repacks are intentionally not installed
  # unattended. Add them here only after reviewing their current publisher.
]
