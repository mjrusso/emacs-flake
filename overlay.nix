# Custom Emacs overlay with platform-specific optimizations.
#
# Uses emacs-plus [0] patches on macOS.
#
# [0]: https://github.com/d12frosted/homebrew-emacs-plus/tree/master/patches/emacs-31
final: prev:
let
  inherit (prev) lib stdenv;
  isDarwin = stdenv.isDarwin;

  custom-mac-emacs-icon = ./icons/emacs-icon-1.0-dh.icns;

  darwinPatches = [
    # Round undecorated frame corners on macOS
    (prev.fetchpatch {
      name = "round-undecorated-frame.patch";
      url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-31/round-undecorated-frame.patch";
      hash = "sha256-WWLg7xUqSa656JnzyUJTfxqyYB/4MCAiiiZUjMOqjuY";
    })
    # Automatic system appearance detection (light/dark mode)
    (prev.fetchpatch {
      name = "system-appearance.patch";
      url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-31/system-appearance.patch";
      hash = "sha256-4+2U+4+2tpuaThNJfZOjy1JPnneGcsoge9r+WpgNDko=";
    })
    # Fix scrolling lag and input handling issues on MacOS 26 (Tahoe)
    (prev.fetchpatch {
      name = "fix-macos-tahoe-scrolling.patch";
      url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-31/fix-macos-tahoe-scrolling.patch";
      hash = "sha256-pI9ylwn+UmSgmfDr4RZ6zynt5bAqF36FY/rH3fYOqZw=";
    })
  ];

  my-emacs-base = prev.emacs-git.override {
    withSQLite3 = true;
    withWebP = true;
    withImageMagick = true;
    withTreeSitter = true;
  };

  my-emacs =
    if isDarwin
    then
      my-emacs-base.overrideAttrs (old: {
        patches =
          (old.patches or [])
          ++ darwinPatches;
        postFixup = old.postFixup + ''
          rm $out/Applications/Emacs.app/Contents/Resources/Emacs.icns
          cp ${custom-mac-emacs-icon} $out/Applications/Emacs.app/Contents/Resources/Emacs.icns
        '';
      })
    else
      (my-emacs-base.override {
        withX = true;
        withGTK3 = true;
        withXinput2 = true;
      }).overrideAttrs(_: {
        configureFlags = [
          "--disable-build-details"
          "--with-modules"
          "--with-x-toolkit=gtk3"
          "--with-xft"
          "--with-cairo"
          "--with-xaw3d"
          "--with-native-compilation"
          "--with-imagemagick"
          "--with-xinput2"
        ];
      });

in
{
  inherit my-emacs-base my-emacs;

  my-emacs-with-packages =
    ((prev.emacsPackagesFor my-emacs).emacsWithPackages (epkgs: [
      epkgs.vterm
      epkgs.treesit-grammars.with-all-grammars
      epkgs.jinx
    ]));
}
