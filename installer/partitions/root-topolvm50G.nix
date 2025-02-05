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
          secondary = {
            size = "50G";
            content = {
              type = "lvm_pv";
              vg = "kubernetes";
            };
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
      kubernetes = {
        type = "lvm_vg";
      };
      vg1 = {
        type = "lvm_vg";
        lvs = {
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
