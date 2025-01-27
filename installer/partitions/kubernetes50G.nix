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
            size = "20G";
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
          tmp = {
            size = "2G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/tmp";
              mountOptions = [
                "noatime"
              ];
              extraArgs = [
                "-L"
                "TMP"
              ];
            };
          };
          var = {
            size = "5G";
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
          varlibcontainerd = {
            size = "20G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/var/lib/containerd";
              mountOptions = [
                "noatime"
              ];
              extraArgs = [
                "-L"
                "VARLIBCONTAINERD"
              ];
            };
          };
          root = {
            size = "5G";
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
