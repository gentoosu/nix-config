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
  show_whitespaces = "all";
  ui_font_size = 14;
  buffer_font_size = 12;
  theme = "Solarized Dark";
  context_servers = {
    mcp-server-context7 = {
      settings = {
        default_minimum_tokens = "10000";
      };
    };
  };
#   languages = {
#     Python = {
#       language_server = ["ruff"];
#       format_on_save = "on"
#       // "language_servers": {
#         "name": "ruff"
#       }
#     }
#   }
}