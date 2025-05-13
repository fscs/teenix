{
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /mnt/share         134.99.147.42(rw,root_squash,sync) 134.99.147.43(rw,root_squash,sync)
  '';

  networking.firewall.allowedTCPPorts = [ 2049 ];
}
