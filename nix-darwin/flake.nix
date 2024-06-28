{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix.url = "github:NixOS/nix/2.20.6";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ pkgs.vim
          pkgs.alacritty
          pkgs.skhd # just to debug in the command line
        ];

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 4;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # Extra config by sam
      # -------------------
      security.pam.enableSudoTouchIdAuth = true;
      environment = {
        shells = [ pkgs.zsh pkgs.fish pkgs.bashInteractive ];
        loginShell = pkgs.fish;
        variables = {
          EDITOR = "emacs -nw";
        };
      };
      nix = {
        # Workaround as the installer installs nix 2.20 withs suports profile
        # version 3, but it is not available in nixpkgs at this moment
        package = nix.outputs.packages.aarch64-darwin.nix;
      };
      nix.settings.sandbox = "relaxed";
      nixpkgs.config = {
        allowUnfree = true;
      };
      services = {
        yabai = {
          enable = true;
          config = {
            layout = "bsp";
            mouse_follows_focus = "on";
            window_placement = "second_child";
            mouse_drop_action = "swap";
          };
          extraConfig = ''
            yabai -m rule --add app="^System Settings$" manage=off
          '';
        };
        skhd = {
          enable = true;
          skhdConfig = ''
            # Valid modifier names: fn, cmd, ctrl, alt (option), shift
            # I have cmd and alt swapped in the os

            ## Yabai keys
            cmd - j : yabai -m window --focus west
            cmd - k : yabai -m window --focus south
            cmd - l : yabai -m window --focus north
            cmd - 0x29 : yabai -m window --focus east

            shift + cmd - j : yabai -m window --warp west
            shift + cmd - k : yabai -m window --warp south
            shift + cmd - l : yabai -m window --warp north
            shift + cmd - 0x29 : yabai -m window --warp east

            shift + cmd - space : yabai -m window --toggle float --grid 4:4:1:1:2:2
          '';
        };
      };
      system = {
        defaults = {
          NSGlobalDomain = {
            InitialKeyRepeat = 15;
            KeyRepeat = 2;
            "com.apple.swipescrolldirection" = false;
          };
          dock.autohide = true;
        };
        keyboard = {
          enableKeyMapping = true;
          swapLeftCommandAndLeftAlt = true;
        };
      };
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#KLF9314XML
    darwinConfigurations."KLF9314XML" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."KLF9314XML".pkgs;
  };
}
