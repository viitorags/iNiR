{
  version ? "dirty",
  extraPackages ? [ ],
  lib,
  stdenvNoCC,
  qt6,
  quickshell,
  wayland-scanner,
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
  darkly,
  kdePackages,
  calendarSupport ? false,
}:
let
  qmlDeps = [
    qt6.qtwayland
    qt6.qtdeclarative
    qt6.qtsvg
    kdePackages.kirigami
    kdePackages.plasma-integration
    kdePackages.syntax-highlighting
    kdePackages.kitemmodels
    kdePackages.qqc2-desktop-style
    kdePackages.kirigami-addons
  ];

  runtimeBins = [
    brightnessctl
    cava
    cliphist
    ddcutil
    wlsunset
    wl-clipboard
    imagemagick
    wget
    (python3.withPackages (pp: lib.optional calendarSupport pp.pygobject3))
    pipewire
    grim
    slurp
    matugen
    darkly
  ]
  ++ extraPackages;

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
in
stdenvNoCC.mkDerivation {
  pname = "ii";
  inherit version src;

  dontPatchShebangs = true;

  nativeBuildInputs = [
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtmultimedia
  ]
  ++ qmlDeps;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/iNiR $out/bin
    cp -r . $out/share/iNiR

    cp ${quickshell}/bin/qs $out/bin/ii

    runHook postInstall
  '';

  preFixup = ''
    qtWrapperArgs+=(
      --prefix PATH : ${lib.makeBinPath runtimeBins}
      --prefix XDG_DATA_DIRS : ${wayland-scanner}/share
      --prefix QML2_IMPORT_PATH : "$out/share/iNiR"
      --add-flags "-p $out/share/iNiR"
      --set QT_QPA_PLATFORM "wayland"
      --set QT_QUICK_CONTROLS_STYLE "org.kde.desktop"
    )
  '';

  meta = {
    description = "A Niri shell illogical-impulse based";
    homepage = "https://github.com/snowarch/iNiR";
    license = lib.licenses.mit;
    mainProgram = "ii";
  };
}
