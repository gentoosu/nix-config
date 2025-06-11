{
  assistant.enabled = true;
  assistant.version = "2";
  assistant.default_model = {
    provider = "anthropic";
    model = "claude-3-5-sonnet";
  };
  hour_format = "hour24";
  vim_mode = false;
  load_direnv = "shell_hook";
  base_keymap = "VSCode";
  show_whitespaces = "trailing";
  ui_font_size = 14;
  buffer_font_size = 12;
  "languages": {
    "Python": {
      "language_servers": ["ruff"]
      // Or, if there are other language servers you want to use with Python
      // "language_servers": ["pyright", "ruff"]
    }
  }
}