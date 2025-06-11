{
  alternate_scroll = "off";
  blinking = "on";
  copy_on_select = true;
  dock = "bottom";
  detect_venv = {
    on = {
      directories = [".env" "env" ".venv" "venv"];
      activate_script = "default";
    };
  };
  env = {
    TERM = "alacritty";
  };
  font_family = "0xProto Nerd Font Mono";
  working_directory = "current_project_directory";
}