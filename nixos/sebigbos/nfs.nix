{
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /mnt/share         134.99.147.42(rw,sync,no_root_squash) 134.99.147.43(rw,sync,no_root_squash)
  '';

  networking.firewall.allowedTCPPorts = [ 2049 ];
}
