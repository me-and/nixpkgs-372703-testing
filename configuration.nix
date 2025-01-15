{
  pkgs,
  modulesPath,
  ...
}: {
  imports = ["${modulesPath}/profiles/minimal.nix"];

  users.users.root.password = "";
  users.users.adam = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    password = "";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  virtualisation.diskSize = 1024 * 20;

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.excludePackages = [pkgs.xterm];

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";
  services.xserver.xkb.layout = "gb";
  services.xserver.xkb.variant = "dvorak";
  console.useXkbConfig = true;

  programs.vim.enable = true;
  programs.vim.defaultEditor = true;

  system.stateVersion = "24.11";
}
