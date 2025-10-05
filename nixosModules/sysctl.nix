{ _, ... }:
{
  boot.kernel.sysctl = {
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.pid_max" = 65536;
    "kernel.perf_cpu_time_max_percent" = 1;
    "kernel.perf_event_max_sample_rate" = 1;
    "kernel.perf_event_paranoid" = 2;
    "kernel.unprivileged_bpf_disabled" = 1;
    "kernel.panic_on_oops" = 1;
    "net.core.bpf_jit_harden" = 2;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.shared_media" = 0;
    "net.ipv4.conf.default.shared_media" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.conf.all.arp_filter" = 1;
    "net.ipv4.conf.all.arp_ignore" = 2;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.tcp_rfc1337" = 1;
    "fs.suid_dumpable" = 0;
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
    "net.ipv6.conf.all.disable_ipv6" = 1;
  };
}
