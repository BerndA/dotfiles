{ config, lib, ... }:

let
  cfg = config.dotfiles;
in
{
  options.dotfiles.repoDir = lib.mkOption {
    type = lib.types.path; # ensures it’s a path
    example = "/home/BerndA/src/dotfiles";
    description = "Local path to the dotfiles repository.";
  };

  # Optional: enforce it exists at eval time (can be annoying if repo isn't present yet)
  # assertions = [
  #   { assertion = builtins.pathExists cfg.repoDir;
  #     message = "dotfiles.repoDir does not exist: ${toString cfg.repoDir}";
  #   }
  # ];
}
