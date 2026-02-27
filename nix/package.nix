{
  version ? "dirty",
  lib,
  stdenvNoCC,
  # build
  qt6,
  quickshell,
  wayland-scanner,
  # runtime deps
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
  glib,
  gobject-introspection,
  playerctl,
  wireplumber,
  pavucontrol,
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
  ],
  calendarSupport ? true,
  darkly ? null,
}:
let
  giTypelibPath = lib.makeSearchPath "lib/girepository-1.0" [
    glib.out
    gobject-introspection
  ];

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
    (python3.withPackages (pp: [
      pp.pygobject3
      pp.evdev
      pp.pillow
    ]))
    (python3.withPackages (pp: lib.optional calendarSupport pp.pygobject3))
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

  nativeBuildInputs = [ qt6.wrapQtAppsHook ];

  buildInputs = [
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

  postPatch = ''
    find . -type f -exec sed -i '1s|^#!.*/bin/activate.*python.*|#!/usr/bin/env python3|' {} +
    find . -type f -exec sed -i '1s|^#!.*/bin/activate.*sh.*|#!/usr/bin/env bash|' {} +
    find . -type f -exec sed -i '1s|^#!/usr/bin/env -S.*|#!/usr/bin/env bash|' {} +
  '';

  installPhase = ''
    runHook preInstall
        mkdir -p $out/share/iNiR $out/bin
        cp -r . $out/share/iNiR
        makeWrapper ${quickshell}/bin/qs $out/bin/ii
        runHook postInstall
  '';

  preFixup = ''
    qtWrapperArgs+=(
      --prefix PATH : ${lib.makeBinPath (runtimeDeps ++ extraPackages)}
      --prefix QML2_IMPORT_PATH : "${lib.makeSearchPath "lib/qt-6/qml" qmlInputs}"
      --prefix XDG_DATA_DIRS : ${wayland-scanner}/share
      --prefix XDG_DATA_DIRS : ${kdePackages.breeze-icons}/share
      --add-flags "-p $out/share/iNiR"
      ${lib.optionalString calendarSupport "--prefix GI_TYPELIB_PATH : ${giTypelibPath}"}
      --set QT_QUICK_CONTROLS_STYLE "org.kde.desktop"
    )
  '';

  meta = {
    description = "A Niri shell based on illogical-impulse";
    homepage = "https://github.com/snowarch/iNiR";
    license = lib.licenses.mit;
    mainProgram = "ii";
  };
}
