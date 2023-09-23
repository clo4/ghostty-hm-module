# This file has been adapted from the Kitty home-manager module but has
# been changed significantly. This should be upstreamed to home-manager
# when the project is out of beta.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.ghostty;

  eitherStrBoolNum = with types; either str (either bool number);

  # Either a (str | bool | number) or a list of (str | bool | number)
  anyConfigType = with types;
    either (listOf eitherStrBoolNum) eitherStrBoolNum;

  toGhosttyConfig = generators.toKeyValue {
    listsAsDuplicateKeys = true;
    mkKeyValue = key: value: let
      value' =
        (
          if isBool value
          then boolToString
          else toString
        )
        value;
      # TODO(clo4): trim off trailing zeroes for floats?
    in "${key} = ${value'}";
  };

  toGhosttyKeybindings = generators.toKeyValue {
    listsAsDuplicateKeys = true;
    mkKeyValue = key: value: "keybind = ${key}=${value}";
  };

  shellIntegrationInit = {
    bash = ''
      if test -n "$GHOSTTY_RESOURCES_DIR"; then
        source "$GHOSTTY_RESOURCES_DIR/shell-integration/bash/ghostty.bash"
      fi
    '';
    fish = ''
      if set -q GHOSTTY_RESOURCES_DIR
        source "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
        set --prepend fish_complete_path "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_completions.d"
      end
    '';
    zsh = ''
      if test -n "$GHOSTTY_RESOURCES_DIR"; then
        autoload -Uz -- "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
        ghostty-integration
        unfunction ghostty-integration
      fi
    '';
  };
in {
  options.programs.ghostty = {
    enable = mkEnableOption "Ghostty terminal emulator";

    settings = mkOption {
      type = types.attrsOf anyConfigType;
      default = {};
      example = literalExpression ''
        {
          cursor-style-blink = false;
          font-family = "Roboto Mono";
          font-size = 14;
          window-theme = "dark";
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/ghostty/config`. The full list of settings is
        available in this file:
        <https://github.com/mitchellh/ghostty/blob/main/src/config/Config.zig>

        To configure the shell integration, see the documentation for
        `programs.ghostty.shellIntegration.enable`.

        The acceptable values are numbers, booleans, strings, or a list of
        these types. Lists will be turned

        This configuration can also include external configuration files
      '';
    };

    shellIntegration = let
      defaultShellIntegration = {
        default = cfg.shellIntegration.enable;
        defaultText =
          literalExpression "config.programs.ghostty.shellIntegration.enable";
      };
    in {
      enable = mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = ''
          Whether to enable the managed Ghostty shell integration.

          With this option enabled, the `shell-integration` directive is
          set to `none`. The shell integration is added to Fish, Bash, and
          Zsh through their initialization scripts as opposed to being detected
          and managed by the terminal itself.

          The integration can be disabled per shell using the
          `programs.ghostty.shellIntegration.enableXyzIntegration` settings.

          If *this* setting is disabled, it is not added to any shell, and
          the responsibility of enabling the shell integration must be handled
          by the terminal and your own config.
        '';
      };

      enableBashIntegration =
        mkEnableOption "Ghostty Bash integration"
        // defaultShellIntegration;

      enableZshIntegration =
        mkEnableOption "Ghostty Zsh integration"
        // defaultShellIntegration;

      enableFishIntegration =
        mkEnableOption "Ghostty Fish integration"
        // defaultShellIntegration;
    };

    keybindings = mkOption {
      type = with types; attrsOf str;
      default = {};
      description = ''
        Set custom Ghostty keybindings.

        Keybindings consist of a key, optionally preceded by modifiers, and
        separated by the + symbol.
        Keys are spelled in English, such as 'minus' for the '-' character,
        or 'left' for the left arrow.

        The following key names can be used as modifiers:
        'ctrl', 'super', 'shift', 'alt', 'caps_lock', 'num_lock'

        The list of available actions that can be bound is located in the Action
        enum in this file:
        <https://github.com/mitchellh/ghostty/blob/main/src/input/Binding.zig>
      '';
      example = literalExpression ''
        {
          "super+shift+d" = "unbind";
          "super+shift+h" = "goto_split:left";
          "super+shift+j" = "goto_split:bottom";
          "super+shift+k" = "goto_split:top";
          "super+shift+l" = "goto_split:right";
        }
      '';
    };

    package = mkPackageOption pkgs "Ghostty" {
      # making it nullable allows you to skip building/installing
      # it if you're managing it externally, e.g. using the signed
      # macOS builds.
      nullable = true;
      default = null;
    };

    extraConfig = mkOption {
      default = "";
      type = types.lines;
      description = "Additional configuration to add.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [cfg.package];

    xdg.configFile."ghostty/config" = {
      text = concatStringsSep "\n" [
        ''
          # Generated by Home Manager.
          # See https://github.com/mitchellh/ghostty
        ''

        (optionalString cfg.shellIntegration.enable ''
          # Shell integration is sourced and configured manually
          shell-integration = none
        '')

        (toGhosttyConfig cfg.settings)

        (toGhosttyKeybindings cfg.keybindings)

        (optionalString (cfg.extraConfig != "") ''
          # Extra config
          ${cfg.extraConfig}
        '')
      ];
    };

    programs.bash.initExtra =
      mkIf cfg.shellIntegration.enableBashIntegration shellIntegrationInit.bash;

    programs.zsh.initExtra =
      mkIf cfg.shellIntegration.enableZshIntegration shellIntegrationInit.zsh;

    programs.fish.interactiveShellInit =
      mkIf cfg.shellIntegration.enableFishIntegration shellIntegrationInit.fish;
  };
}
