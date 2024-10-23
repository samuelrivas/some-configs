{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # nix.url = "github:NixOS/nix/2.20.6";
    sams-monorepo.url = "github:samuelrivas/monorepo";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix, sams-monorepo }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ # Some are commented out as I installed them with brew isntead
          # pkgs.vim
          # pkgs.alacritty
          # pkgs.skhd # just to debug in the command line
          # sams-monorepo.outputs.packages.aarch64-darwin.my-emacs
        ];

      services = {
        # Auto upgrade nix package and the daemon service.
        nix-daemon.enable = true;

        # I didn't get this to work from nix, brew does work
        # karabiner-elements.enable = true;
      };
      # nix = {
      #   # Workaround as the installer installs nix 2.20 withs suports profile
      #   # version 3, but it is not available in nixpkgs at this moment
      #   package = nix.outputs.packages.aarch64-darwin.nix;
      # };

      nix.package = pkgs.nix;

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

      # XXX: Sandbox hits a limit in macos: https://github.com/NixOS/nix/issues/4119
      nix.settings.sandbox = false;

      nixpkgs.config = {
        allowUnfree = true;
      };
      services = {
        yabai = {
          enable = true;
          config = {
            layout = "bsp";
            mouse_follows_focus = "off";
            window_placement = "second_child";
            mouse_drop_action = "swap";
            mouse_modifier = "alt";
            mouse_action1 = "move";
          };
          extraConfig = ''
            yabai -m rule --add app="^System Settings$" manage=off
          '';
        };
        skhd = {
          enable = true;
          skhdConfig = ''
            # Valid modifier names: fn, cmd, ctrl, alt (option), shift

            ## Yabai keys
            alt - j : yabai -m window --focus west
            alt - k : yabai -m window --focus south
            alt - l : yabai -m window --focus north
            alt - b : yabai -m window --focus recent
            alt - 0x29 : yabai -m window --focus east

            shift + alt - j : yabai -m window --warp west
            shift + alt - k : yabai -m window --warp south
            shift + alt - l : yabai -m window --warp north
            shift + alt - 0x29 : yabai -m window --warp east

            shift + alt - 1 : yabai -m window --space 1
            shift + alt - 2 : yabai -m window --space 2
            shift + alt - 3 : yabai -m window --space 3
            shift + alt - 4 : yabai -m window --space 4
            shift + alt - 5 : yabai -m window --space 5
            shift + alt - 6 : yabai -m window --space 6
            shift + alt - 7 : yabai -m window --space 7
            shift + alt - 8 : yabai -m window --space 8
            shift + alt - 9 : yabai -m window --space 9
            shift + alt - 0 : yabai -m window --space 10

            alt - p : yabai -m display --focus next
            alt - o : yabai -m display --focus prev
            shift + alt - p : yabai -m window --display next
            shift + alt - o : yabai -m window --display prev

            alt - f : yabai -m window --toggle zoom-fullscreen

            shift + alt - space : yabai -m window --toggle float --grid 4:4:1:1:2:2

            ## Quick launch a terminal
            alt - return : alacritty
          '';
        };
      };
      system = {
        defaults = {
          NSGlobalDomain = {
            AppleInterfaceStyle = "Dark";
            InitialKeyRepeat = 15;
            KeyRepeat = 2;
            "com.apple.swipescrolldirection" = false;
          };
          dock.autohide = true;
        };
        keyboard = {
          enableKeyMapping = true;
          swapLeftCommandAndLeftAlt = false;
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
