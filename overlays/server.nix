# Server-friendly variants of packages pulled in by shared (nixbook) modules.
_final: prev: {
  # nixbook's fastfetchConfig installs pkgs.fastfetch, whose image/GUI
  # backends (EFL, icon themes, SDL, flite...) bring its closure to ~1.6 GiB.
  # Same switches as nixpkgs' fastfetch.minimal (~0.2 GiB), applied to prev:
  # `minimal` itself refers back to `fastfetch` and would recurse here.
  fastfetch = prev.fastfetch.override {
    audioSupport = false;
    brightnessSupport = false;
    dbusSupport = false;
    enlightenmentSupport = false;
    flashfetchSupport = false;
    gnomeSupport = false;
    imageSupport = false;
    openclSupport = false;
    openglSupport = false;
    rpmSupport = false;
    sqliteSupport = false;
    terminalSupport = false;
    vulkanSupport = false;
    waylandSupport = false;
    x11Support = false;
    xfceSupport = false;
  };
}
