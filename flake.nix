{
  description = "Zelda 64";

  inputs.nixpkgs.url = "nixos-unstable";

  outputs = {self, nixpkgs}:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      stormlib = pkgs.pkgsi686Linux.stdenv.mkDerivation rec {
        pname = "stormlib";
        version = "git";

        nativeBuildInputs = with pkgs; [ cmake ];

        src = pkgs.fetchFromGitHub {
          owner = "ladislav-zezula";
          repo = "StormLib";
          rev = "8f3f327697b392014cc084f4f3a3547ddb3a1b89";
          hash = "sha256-ZCC7tqPQ02mxl1K+AEc52A5JWHLudb+0tSt0ur3N6Qg=";
        };
      };

      zelda_rom = pkgs.fetchurl {
        url = "https://ia902906.us.archive.org/22/items/ZELOOTD/ZELOOTD.zip";
        hash = "sha256-uWDI3aYH0NCbN7chdT3YqYhyrUrxDuwAkffymAvkqB4=";
        name = "zelda.zip";
      };

      zelda = pkgs.pkgsi686Linux.stdenv.mkDerivation rec {
          pname = "zelda";
          version = "git";

          buildInputs = with pkgs.pkgsi686Linux; [
            #audiofile
            SDL2
            libusb1
            #glfw3
            #libgcc
            xorg.libX11
            xorg.libXrandr
            libpulseaudio
            #alsaLib
            #glfw
            glew
            #libGL
            #glibc_multi
            libpng
            bzip2
            stormlib
          ];

          nativeBuildInputs = with pkgs; [
            #copyDesktopItems
            #unixtools.hexdump
            pkg-config
            gnumake
            python3
            p7zip
            #unzip
            #which
            llvmPackages.bintools # don't use lld!!! it doesn't have the proper wrapper

            (pkgs.writeShellApplication {name = "git"; text = "echo 0000000";}) # HACK: the makefile tries to extract the version using git, but the .git folder is not available
          ];

          src = pkgs.fetchFromGitHub {
            owner = "HarbourMasters";
            repo = "Shipwright";
            rev = "076887e71f52d4258aa8fc77d3efeafe09d234d8";
            hash = "sha256-LCKpRqeHDupHl4KN4TZeQkbbyvkLzWgETrShFscO8p4=";
          };

          hardeningDisable = [ "all" ];

          patches = [
            ./0001-fix-libultraship-compilation.patch
          ];

          preBuild = ''
            7z x ${zelda_rom} -aoa # fails without the overriding flag, probably because of some special mount options in the sandbox
            mv ZELOOTD.z64 OTRExporter/
            cd soh
            make setup -j$NIX_BUILD_CORES OPTFLAGS=-O2 DEBUG=0
            make -j$NIX_BUILD_CORES OPTFLAGS=-O2 DEBUG=0
          '';

          installPhase = ''
            mkdir -p $out/bin
            mv soh.elf oot.otr $out/bin
          '';

        };
    in {
      packages.x86_64-linux.zelda = zelda;
      packages.x86_64-linux.stormlib = stormlib;
      packages.x86_64-linux.default = zelda;
    };
}
