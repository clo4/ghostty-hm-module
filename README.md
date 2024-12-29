# Ghostty Home Manager module

Until Ghostty is open source, the module can't be upstreamed to
nix-community/home-manager, and can't be in a private repository, so it's going
to live here until I can move it elsewhere.

## Installation

Use it as you would any other Nix flake input:

```nix
{
  inputs = {
    ghostty.url = "github:clo4/ghostty-hm-module";
  };

  outputs = { ghostty, home-manager, , ... }: {
    homeConfigurations.jdoe = {
      # ...
      modules = [
        ghostty.homeModules.default
      ];
    };
  };
}
```

If you're using home-manager as a NixOS or nix-darwin module, you can add this
module by:

- Import it in the place you're going to use it, by placing the module in the
  `imports` list
- Import the module for all Home Manager users by using
  [`home-manager.sharedModules`](https://nix-community.github.io/home-manager/nixos-options.xhtml#nixos-opt-home-manager.sharedModules)

## Documentation

### programs.ghostty.enable

Enables or disables the configuration.

Note that currently there is no Nix package for the terminal, so enabling this
will (by default) only affect whether the configuration file is generated or
not.

```nix
{
  programs.ghostty = {
    enable = true;
  };
}
```

### programs.ghostty.package

Set the package that will be installed.

This is nullable, and is set to null by default. When null, it's assumed that
the terminal is managed externally, and nothing will be installed or built. When
the terminal is publicly available and there is a package available for it, this
will be set to that package.

```nix
{
  programs.ghostty = {
    package = null;
  };
}
```

### programs.ghostty.shellIntegration

Controls whether the shell integration is managed by Nix.

To enable or disable the shell integration, use the `enable` setting. This is
true by default, so does not need to be specified. If you manage your shell
externally, you may want to disable the automatic shell integration.

```nix
{
  programs.ghostty = {
    shellIntegration.enable = false;
  };
}
```

You can also enable or disable this per-shell. The shell settings inherit from
`programs.ghostty.shellIntegration.enable`, so you can control them all with one
toggle or manage them individually.

```nix
{
  programs.ghostty = {
    shellIntegration.enable = false;
    shellIntegration.enableZshIntegration = true;
    # Bash and Fish are disabled, but Zsh is enabled.
  };
}
```

### programs.ghostty.settings

The `settings` setting is how you configure Ghostty.

[Here are the available settings.](https://github.com/mitchellh/ghostty/blob/main/src/config/Config.zig)

This takes an attribute set with a map of setting-name to value. You can use
strings, numbers, booleans, or a list of strings, numbers, and booleans.

```nix
{ pkgs, ... }:
{
  programs.ghostty = {
    settings = {
      font-size = 11;
      font-family = "JetBrainsMono Nerd Font";

      # The default is a bit intense for my liking
      # but it looks good with some themes
      unfocused-split-opacity = 0.96;

      # Some macOS settings
      window-theme = "dark";
      macos-option-as-alt = true;

      # Disables ligatures
      font-feature = ["-liga" "-dlig" "-calt"];
    };
  };
}
```

#### Color schemes

Note that you can reference external configuration files using the `config-file`
setting. This is useful for using predefined themes from the
[iTerm Color Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes) repo,
which recently landed support for Ghostty themes.

```nix
# flake.nix
{
  inputs = {
    color-schemes = {
      url = "github:mbadolato/iTerm2-Color-Schemes";
      flake = false;
    };
  };

  # Your outputs should pass the color-schemes input to the module
  # that defines your ghostty config, eg. by using `extraSpecialArgs`
  # https://nix-community.github.io/home-manager/nixos-options.html#nixos-opt-home-manager.extraSpecialArgs
  outputs = { color-schemes, ... }: { /* ... */ };
}
```

```nix
# In your Ghostty config:
{ color-schemes, ... }:
{
  programs.ghostty = {
    settings = {
      config-file = [
        (color-schemes + "/Ghostty/GruvboxDark")
      ];
    };
  };
}
```

### programs.ghostty.clearDefaultKeybindings

Clears the default keybindings. This is useful when you want to add entirely custom
keybindings without having to manually unbind everything yourself. This is a boolean
option that defaults to false.

```nix
{
  programs.ghostty = {
    clearDefaultKeybindings = true;
  }; 
}
```

### programs.ghostty.keybindings

Keybindings is a map of modifiers and key to action.

- Modifier names are `super`, `ctrl`, `shift`, `alt`, `caps_lock`, and
  `num_lock`
- Modifiers are optional and are always separated from each other and the key
  with `+`.
- Non-letter key names are always spelled out, such as `eight`, `plus`, `equal`,
  and `page_down`.
  - All valid names are located in the `Key` enum in
    [this file](https://github.com/mitchellh/ghostty/blob/main/src/input/key.zig)
- Actions are defined the `Action` enum in
  [this file](https://github.com/mitchellh/ghostty/blob/main/src/input/Binding.zig).
  - Actions that are non-void take their argument preceded by a colon, such as
    in the example below.

```nix
{
  programs.ghostty = {
    keybindings = {
      "super+c" = "copy_to_clipboard";
      
      "super+shift+h" = "goto_split:left";
      "super+shift+j" = "goto_split:bottom";
      "super+shift+k" = "goto_split:top";
      "super+shift+l" = "goto_split:right";

      "ctrl+page_up" = "jump_to_prompt:-1";
    };
  };
}
```

The default keybindings are defined programatically in
[this file](https://github.com/mitchellh/ghostty/blob/main/src/config/Config.zig).
Search for `pub fn default`.

### programs.ghostty.extraConfig

This is a string to allow you to define additional config if for some reason you
cannot with the settings provided.
