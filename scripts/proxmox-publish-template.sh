#!/usr/bin/env bash
# Publish a KaaS worker qcow2 as a Proxmox VM template (Proxmox >= 8.4 API,
# no SSH). Used by .github/workflows/kaas-templates.yaml.
#
#   proxmox-publish-template.sh <image.qcow2> <k8s-version e.g. 1.36.3>
#
# The template copies the hardware of REFERENCE_VMID (an existing KaaS
# template: cores, memory, cpu, machine, bios, net, scsihw, serial, agent...)
# with a fresh MAC, imports the image as its boot disk on each of TEMPLATE_STORAGES, and
# gets the tags CAPMOX selects on (flux-mgmt ClusterClass templateSelector,
# matchPolicy uniqueSubset):
#   kaassopeia  k8s-v<version>  img-<nix store hash>  storage-<proxmox storage>
# One template per storage in TEMPLATE_STORAGES (from one image download).
# Publishing the same image again is a no-op. A new image for a version that
# already has a template on that storage takes the k8s-v<version> tag; the
# previous one there is retagged superseded-k8s-v<version> (kept for rollback; existing VMs are full
# clones and don't depend on it).
#
# Image transfer: with IMAGE_URL (+ IMAGE_SHA256) Proxmox downloads the image
# itself (download-url, checksum verified; needs Sys.AccessNetwork), otherwise
# the image is uploaded through the API (slow over a long tailnet path).
#
# Env: PVE_URL (https://proxmox.bealv.lan:8006), PVE_TOKEN_ID (user@realm!name),
#      PVE_TOKEN_SECRET, PVE_NODE (proxmox-alv), REFERENCE_VMID (997),
#      TEMPLATE_DISK_SIZE (70G; smaller existing templates get replaced),
#      TEMPLATE_STORAGES (space-separated Proxmox storage IDs; default: the one
#      of REFERENCE_VMID's disk), IMPORT_STORAGE (local; needs the "Import"
#      content type). TLS, first match wins:
#        PVE_PINNED_PUBKEY  sha256//<base64> of the API certificate's public key
#                           (Proxmox's own self-signed CA, CN=proxmox-alv: pin it)
#        PVE_CACERT         CA file for the API certificate
#        PVE_INSECURE=1     no verification at all
set -euo pipefail

image="$1"
version="${2#v}"
: "${PVE_URL:?}" "${PVE_TOKEN_ID:?}" "${PVE_TOKEN_SECRET:?}"
node="${PVE_NODE:-proxmox-alv}"
ref="${REFERENCE_VMID:-997}"
# Proxmox storage IDs to create a template on (space separated); default: the
# storage of the reference template's disk. One template per storage.
storages_in="${TEMPLATE_STORAGES:-${TEMPLATE_STORAGE:-}}"
istore="${IMPORT_STORAGE:-local}"
# Boot disk size of the templates (clones inherit it; the image grows its
# partition and filesystem on boot). The qcow2 itself is only ~10G.
dsize="${TEMPLATE_DISK_SIZE:-70G}"
imghash="$(basename "$(dirname "$(readlink -f "$image")")" | cut -c1-12)"
vtag="k8s-v${version}"
itag="img-${imghash}"
file="kaassopeia-${version}-${imghash}.qcow2"

# --fail-with-body: on HTTP errors curl still exits non-zero, but Proxmox's
# error message (JSON "message"/"errors") is printed instead of swallowed.
curl_opts=(-sS --fail-with-body --retry 3 -H "Authorization: PVEAPIToken=${PVE_TOKEN_ID}=${PVE_TOKEN_SECRET}")
if [ -n "${PVE_PINNED_PUBKEY:-}" ]; then
  # -k skips CA/hostname checks; --pinnedpubkey still rejects any other key.
  curl_opts+=(-k --pinnedpubkey "$PVE_PINNED_PUBKEY")
elif [ -n "${PVE_CACERT:-}" ]; then
  curl_opts+=(--cacert "$PVE_CACERT")
elif [ "${PVE_INSECURE:-}" = 1 ]; then
  curl_opts+=(-k)
fi
api() { # api METHOD PATH [curl args...] -> .data (exits on any error)
  local m="$1" p="$2" out
  shift 2
  if ! out="$(curl "${curl_opts[@]}" --max-time 300 -X "$m" "${PVE_URL%/}/api2/json${p}" "$@")"; then
    echo "Proxmox API ${m} ${p} failed: ${out}" >&2
    exit 1
  fi
  jq -c '.data' <<<"$out"
}
wait_task() {
  local upid="$1" st
  case "$upid" in
  UPID:*) ;;
  *)
    echo "expected a task id, got '${upid}'" >&2
    exit 1
    ;;
  esac
  while :; do
    st="$(api GET "/nodes/${node}/tasks/$(jq -rn --arg u "$upid" '$u|@uri')/status")"
    if [ "$(jq -r .status <<<"$st")" = "stopped" ]; then
      [ "$(jq -r .exitstatus <<<"$st")" = "OK" ] || {
        echo "task $upid failed: $(jq -r .exitstatus <<<"$st")" >&2
        exit 1
      }
      return
    fi
    sleep 3
  done
}
templates() { # all KaaS templates on the node: vmid tags
  api GET "/nodes/${node}/qemu" | jq -r '.[] | select(.template == 1) | select((.tags // "") | split(";") | index("kaassopeia")) | "\(.vmid) \(.tags)"'
}

boot_disk_key() { # first non-cloud-init disk key of a VM config (json on stdin)
  jq -r 'to_entries[] | select(.key|test("^(scsi|virtio|sata|ide)[0-9]+$")) | select(.value|test("cloudinit|media=cdrom")|not) | .key' | head -1
}
template_disk() { # boot disk of a VM: "<storage> <size in bytes>"
  local cfg key
  cfg="$(api GET "/nodes/${node}/qemu/$1/config")"
  key="$(boot_disk_key <<<"$cfg")"
  jq -r --arg k "${key:-scsi0}" '.[$k] // ""' <<<"$cfg" | {
    IFS= read -r d
    echo "${d%%:*} $(to_bytes "$(sed -n 's/.*size=\([0-9]*[KMGT]\?\).*/\1/p' <<<"$d")")"
  }
}
template_storage() { template_disk "$1" | cut -d' ' -f1; }
to_bytes() { # 70G -> bytes (Proxmox size suffixes are binary)
  numfmt --from=iec "${1:-0}"
}

# Fail here (TLS, token, routing) rather than inside a condition below.
echo "Proxmox API: $(api GET /version | jq -r '"version \(.version)"')"

refcfg="$(api GET "/nodes/${node}/qemu/${ref}/config")"
disk_key="$(boot_disk_key <<<"$refcfg")"
ci_key="$(jq -r 'to_entries[] | select(.value|tostring|test("cloudinit")) | .key' <<<"$refcfg" | head -1)"
if [ -z "$storages_in" ]; then
  # Proxmox storage ID (not the Kubernetes StorageClass name) of the reference
  # template's boot disk, e.g. "disk_hdd:base-997-disk-0" -> "disk_hdd".
  storages_in="$(jq -r --arg k "${disk_key:-scsi0}" '.[$k] // ""' <<<"$refcfg" | cut -d: -f1)"
  [ -n "$storages_in" ] || {
    echo "cannot find the storage of ${ref}'s disk; set TEMPLATE_STORAGES" >&2
    exit 1
  }
fi
known="$(api GET "/nodes/${node}/storage" | jq -r '.[].storage')"
read -ra storages <<<"$storages_in"
for st in "${storages[@]}"; do
  grep -qx "$st" <<<"$known" || {
    echo "Proxmox storage '${st}' does not exist on ${node}; available: $(paste -sd' ' <<<"$known")" >&2
    exit 1
  }
done

# Storages that don't have a template of this image yet.
todo=()
for st in "${storages[@]}"; do
  found=""
  while read -r id tags; do
    [ -n "$id" ] || continue
    tr ';' '\n' <<<"$tags" | grep -qx "$itag" || continue
    read -r tst tsz < <(template_disk "$id")
    [ "$tst" = "$st" ] || continue
    if [ "$tsz" -ge "$(to_bytes "$dsize")" ]; then
      found="$id"
    else
      echo "template ${id} on ${st} has this image but a $(numfmt --to=iec "$tsz") disk (< ${dsize}), replacing it"
    fi
  done < <(templates)
  if [ -n "$found" ]; then
    echo "image ${imghash} already published on ${st} (template ${found})"
  else
    todo+=("$st")
  fi
done
if [ "${#todo[@]}" -eq 0 ]; then
  echo "nothing to do"
  exit 0
fi

volid="${istore}:import/${file}"
size="$(stat -Lc %s "$image")"
have="$(api GET "/nodes/${node}/storage/${istore}/content?content=import" | jq -r --arg v "$volid" '.[] | select(.volid == $v) | .size')"
if [ "$have" = "$size" ]; then
  echo "${volid} already uploaded (${size} bytes), reusing it"
elif [ -n "${IMAGE_URL:-}" ]; then
  echo "Proxmox downloads ${file} into ${istore} (sha256 ${IMAGE_SHA256:?})..."
  upid="$(api POST "/nodes/${node}/storage/${istore}/download-url" \
    -d content=import --data-urlencode "filename=${file}" \
    --data-urlencode "url=${IMAGE_URL}" \
    -d checksum-algorithm=sha256 -d "checksum=${IMAGE_SHA256}" | jq -r .)"
  wait_task "$upid"
else
  echo "uploading ${file} to ${istore}..."
  echo "image size: $(stat -Lc %s "$image") bytes"
  # --speed-limit/--speed-time: abort a stalled transfer after 2 min instead of
  # waiting for pveproxy's own timeout; -w reports how far it got.
  upid="$(curl "${curl_opts[@]}" --speed-limit 1024 --speed-time 120 \
    -w '\n%{stderr}upload: %{size_upload} bytes in %{time_total}s (%{speed_upload} B/s), http %{http_code}\n' \
    -X POST "${PVE_URL%/}/api2/json/nodes/${node}/storage/${istore}/upload" \
    -F content=import -F "filename=@${image};filename=${file}" | jq -r '.data')"
  wait_task "$upid"
fi

for tstore in "${todo[@]}"; do
  vmid="$(api GET /cluster/nextid | jq -r .)"
  tags_new="kaassopeia;${vtag};${itag};storage-${tstore}"
  args=(
    -d "vmid=${vmid}"
    --data-urlencode "name=kaassopeia-${version//./-}-${tstore//_/-}"
    --data-urlencode "tags=${tags_new}"
    --data-urlencode "${disk_key:-scsi0}=${tstore}:0,import-from=${volid}"
    --data-urlencode "boot=order=${disk_key:-scsi0}"
  )
  [ -n "$ci_key" ] && args+=(--data-urlencode "${ci_key}=${tstore}:cloudinit")
  # Hardware copied from the reference template. MAC addresses are dropped
  # (model=MAC -> model) so every template, and every clone, gets its own.
  while IFS=$'\t' read -r k v; do
    args+=(--data-urlencode "${k}=${v}")
  done < <(jq -r 'to_entries[]
  | select(.key|test("^(cores|sockets|memory|balloon|cpu|machine|bios|ostype|scsihw|vga|agent|numa|hotplug|serial[0-9]+|net[0-9]+|efidisk0)$"))
  | select(.key != "efidisk0")
  | [.key, (if (.key|test("^net")) then (.value|sub("^(?<m>[a-z0-9]+)=[0-9A-Fa-f:]{17}"; "\(.m)")) else (.value|tostring) end)]
  | @tsv' <<<"$refcfg")

  # Don't leave a half-made VM behind if a step below fails.
  trap 'echo "removing unfinished VM ${vmid}" >&2; curl "${curl_opts[@]}" --max-time 120 -X DELETE "${PVE_URL%/}/api2/json/nodes/${node}/qemu/${vmid}?purge=1&destroy-unreferenced-disks=1" >/dev/null || true' EXIT
  echo "creating VM ${vmid} (hardware from ${ref}, disk on ${tstore})..."
  printf '  %s\n' "${args[@]}" | grep -v '^  -' | grep -v '^  --' || true
  upid="$(api POST "/nodes/${node}/qemu" "${args[@]}" | jq -r .)"
  wait_task "$upid"
  # CI stages an image already grown to TEMPLATE_DISK_SIZE (qemu-img resize on
  # Proxmox's HDD storage times out); grow it here only when it is smaller.
  read -r _ cur < <(template_disk "$vmid")
  if [ "$cur" -lt "$(to_bytes "$dsize")" ]; then
    echo "growing ${vmid}'s ${disk_key:-scsi0} to ${dsize}..."
    upid="$(api PUT "/nodes/${node}/qemu/${vmid}/resize" -d "disk=${disk_key:-scsi0}" -d "size=${dsize}" | jq -r .)"
    # Proxmox >= 8 runs the resize as a task; older versions answer null.
    [ "$upid" = null ] || wait_task "$upid"
  fi
  echo "converting ${vmid} to a template..."
  upid="$(api POST "/nodes/${node}/qemu/${vmid}/template" | jq -r .)"
  wait_task "$upid"
  trap - EXIT
  # On this storage, only the new template keeps the version tag.
  templates | while read -r id tags; do
    [ "$id" = "$vmid" ] && continue
    tr ';' '\n' <<<"$tags" | grep -qx "$vtag" || continue
    [ "$(template_storage "$id")" = "$tstore" ] || continue
    newtags="$(tr ';' '\n' <<<"$tags" | sed "s/^${vtag}\$/superseded-${vtag}/" | paste -sd';')"
    echo "template ${id}: ${tags} -> ${newtags}"
    api PUT "/nodes/${node}/qemu/${id}/config" --data-urlencode "tags=${newtags}" >/dev/null
  done
  echo "published template ${vmid}: ${tags_new}"
done

api DELETE "/nodes/${node}/storage/${istore}/content/$(jq -rn --arg v "$volid" '$v|@uri')" >/dev/null || echo "warning: could not delete ${volid}" >&2
