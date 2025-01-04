{
  disk ? "/dev/nvme0n1",
}:
{
  disko.devices.disk.main = {
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
}
