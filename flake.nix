{
  description = "Home Manager module for Ghostty";

  outputs = {...}: {
    # Name is consistent with both `nixosModules` and `homeConfigurations`
    homeModules.default = import ./module.nix;
  };
}
