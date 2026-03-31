{
  version ? "dirty",
  lib,
  stdenvNoCC,
  makeWrapper,
  # build
  qt6,
  quickshell,
  wayland-scanner,
  # runtime deps
  coreutils,
  procps,
  systemd,
  glib,
  bash,
  brightnessctl,
  cava,
  cliphist,
  ddcutil,
  wlsunset,
  wl-clipboard,
  imagemagick,
  wget,
  python3,
  pipewire,
  grim,
  slurp,
  matugen,
  gobject-introspection,
  playerctl,
  wireplumber,
  pavucontrol,
  pamixer,
  # foot,
  # dolphin,
  gnome-keyring,
  mpv,
  yt-dlp,
  socat,
  wf-recorder,
  swappy,
  tesseract,
  ffmpeg,
  tesseract-data-eng ? tesseract,
  tesseract-data-spa2 ? tesseract,
  upower,
  wtype,
  ydotool,
  geoclue2,
  swayidle,
  swaylock,
  blueman,
  fprintd,
  libqalculate,
  # KDE/QML and Extra Packages
  material-symbols,
  fontconfig,
  dejavu_fonts,
  liberation_ttf,
  fuzzel,
  translate-shell,
  kdePackages,
  kvantum ? kdePackages.qtstyleplugin-kvantum,
  extraPackages ? [
    fontconfig
    dejavu_fonts
    liberation_ttf
    fuzzel
    translate-shell
    kvantum
    material-symbols
  ],
  calendarSupport ? true,
  darkly ? null,
}:
let
  giTypelibPath = lib.makeSearchPath "lib/girepository-1.0" [
    glib.out
    gobject-introspection
    upower
    playerctl
  ];

  pythonEnv = python3.withPackages (
    pp:
    [
      pp.pygobject3
      pp.evdev
      pp.pillow
    ]
    ++ lib.optional calendarSupport pp.pygobject3
  );

  runtimeDeps = [
    brightnessctl
    cava
    cliphist
    ddcutil
    wlsunset
    wl-clipboard
    imagemagick
    wget
    pipewire
    grim
    slurp
    matugen
    playerctl
    wireplumber
    pavucontrol
    pamixer
    mpv
    yt-dlp
    socat
    wf-recorder
    swappy
    ffmpeg
    tesseract
    tesseract-data-eng
    tesseract-data-spa2
    upower
    wtype
    ydotool
    geoclue2
    swayidle
    swaylock
    blueman
    fprintd
    libqalculate
    # foot
    # dolphin
    kdePackages.kdialog
    gnome-keyring
    kdePackages.polkit-kde-agent-1
    pythonEnv
    coreutils
    procps
    systemd
    glib
    kdePackages.kconfig
    bash
  ]
  ++ lib.optional (darkly != null) darkly;

  src = lib.cleanSourceWith {
    src = ../.;
    filter =
      path: type:
      !(builtins.any (prefix: lib.path.hasPrefix (../. + prefix) (/. + path)) [
        /.github
        /.gitignore
        /Assets/Screenshots
        /Scripts/dev
        /nix
        /LICENSE
        /README.md
        /flake.nix
        /flake.lock
        /shell.nix
        /lefthook.yml
        /CLAUDE.md
        /CREDITS.md
        /result
      ]);
  };

  qmlInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtmultimedia
    qt6.qtwayland
    qt6.qt5compat
    qt6.qtsvg
    qt6.qtimageformats
    qt6.qtpositioning
    qt6.qtquicktimeline
    qt6.qtsensors
    qt6.qtvirtualkeyboard
    kdePackages.kirigami
    kdePackages.kirigami-addons
    kdePackages.qqc2-desktop-style
    kdePackages.plasma-integration
    kdePackages.syntax-highlighting
    kdePackages.breeze-icons
  ];
in
stdenvNoCC.mkDerivation {
  pname = "ii";
  inherit version src;

  nativeBuildInputs = [
    qt6.wrapQtAppsHook
    makeWrapper
  ];

  buildInputs = qmlInputs;

  postPatch = ''
    find . -type f -exec sed -i '1s|^#!.*/bin/activate.*python.*|#!/usr/bin/env python3|' {} +
    find . -type f -exec sed -i '1s|^#!.*/bin/activate.*sh.*|#!/usr/bin/env bash|' {} +
    find . -type f -exec sed -i '1s|^#!/usr/bin/env -S.*|#!/usr/bin/env bash|' {} +

    find . -type f \( -name "*.qml" -o -name "*.js" -o -name "*.sh" \) -exec sed -i -E 's|"/usr/bin/([^"]+)"|"\1"|g' {} +
    find . -type f \( -name "*.qml" -o -name "*.js" -o -name "*.sh" \) -exec sed -i -E 's|"/bin/([^"]+)"|"\1"|g' {} +
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/iNiR $out/bin
    cp -r . $out/share/iNiR

    cat > $out/bin/ii <<EOF
    #!/usr/bin/env bash

    mkdir -p ~/.config/illogical-impulse
    mkdir -p ~/.local/state/quickshell/user/generated

    for dir in scripts assets defaults translations modules services sdata docs; do
      if [ -d "$out/share/iNiR/\$dir" ]; then
        ln -sfn "$out/share/iNiR/\$dir" ~/.config/illogical-impulse/\$dir
      fi
    done

    if [ ! -f ~/.config/illogical-impulse/config.json ]; then
      cp "$out/share/iNiR/defaults/config.json" ~/.config/illogical-impulse/config.json
      chmod 644 ~/.config/illogical-impulse/config.json
    fi

    if [ ! -f ~/.local/state/quickshell/states.json ]; then
      echo "{}" > ~/.local/state/quickshell/states.json
    fi
    if [ ! -f ~/.local/state/quickshell/user/notifications.json ]; then
      echo "[]" > ~/.local/state/quickshell/user/notifications.json
    fi

    if [ ! -f ~/.local/state/quickshell/user/generated/colors.json ]; then
      ${lib.getExe matugen} image "$out/share/iNiR/assets/images/default_wallpaper.png" || echo "{}" > ~/.local/state/quickshell/user/generated/colors.json
    fi

    if [ ! -f ~/.local/state/quickshell/user/gamemode_active ]; then
      echo "false" > ~/.local/state/quickshell/user/gamemode_active
    fi
    if [ ! -f ~/.local/state/quickshell/user/notepad.txt ]; then
      touch ~/.local/state/quickshell/user/notepad.txt
    fi

    exec ${lib.getExe quickshell} -p "$out/share/iNiR" "\$@"
    EOF

    chmod +x $out/bin/ii

    runHook postInstall
  '';

  preFixup = ''
    qtWrapperArgs+=(
      --set QT_PLUGIN_PATH "${lib.makeSearchPath "lib/qt-6/plugins" qmlInputs}"
      --set QML2_IMPORT_PATH "${lib.makeSearchPath "lib/qt-6/qml" qmlInputs}"
      
      --prefix PATH : ${lib.makeBinPath (runtimeDeps ++ extraPackages)}
      --prefix XDG_DATA_DIRS : ${wayland-scanner}/share
      --prefix XDG_DATA_DIRS : ${kdePackages.breeze-icons}/share
      ${lib.optionalString calendarSupport "--prefix GI_TYPELIB_PATH : ${giTypelibPath}"}
      --set QT_QUICK_CONTROLS_STYLE "org.kde.desktop"
    )

    wrapQtApp $out/bin/ii
  '';

  meta = {
    description = "A Niri shell based on illogical-impulse";
    homepage = "https://github.com/snowarch/iNiR";
    license = lib.licenses.mit;
    mainProgram = "ii";
  };
}
