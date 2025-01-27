{
  disk ? "/dev/nvme0n1",
}:
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = disk;
      content = {
        type = "gpt";
        partitions = {
          MBR = {
            size = "1M";
            type = "EF02";
            priority = 1;
          };
          primary = {
            size = "100%";
            content = {
              type = "lvm_pv";
              vg = "vg1";
            };
          };
        };
      };
    };
    lvm_vg = {
      vg1 = {
        type = "lvm_vg";
        lvs = {
          nix = {
            size = "40G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix";
              mountOptions = [
                "noatime"
              ];
              extraArgs = [
                "-L"
                "NIX"
              ];
            };
          };
          var = {
            size = "20G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/var";
              mountOptions = [
                "noatime"
              ];
              extraArgs = [
                "-L"
                "VAR"
              ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              extraArgs = [
                "-L"
                "ROOT"
              ];
            };
          };
        };
      };
    };
  };
}
