#!/usr/bin/env bash
# Publish a KaaS worker qcow2 as a Proxmox VM template (Proxmox >= 8.4 API,
# no SSH). Used by .github/workflows/kaas-templates.yaml.
#
#   proxmox-publish-template.sh <image.qcow2> <k8s-version e.g. 1.36.3>
#
# The template copies the hardware of REFERENCE_VMID (an existing KaaS
# template: cores, memory, cpu, machine, bios, net, scsihw, serial, agent...)
# with a fresh MAC, imports the image as its boot disk on TEMPLATE_STORAGE, and
# gets the tags CAPMOX selects on (flux-mgmt ClusterClass templateSelector,
# matchPolicy uniqueSubset):
#   kaassopeia  k8s-v<version>  img-<nix store hash>
# Publishing the same image again is a no-op. A new image for a version that
# already has a template takes the k8s-v<version> tag; the previous template is
# retagged superseded-k8s-v<version> (kept for rollback; existing VMs are full
# clones and don't depend on it).
#
# Env: PVE_URL (https://proxmox.bealv.lan:8006), PVE_TOKEN_ID (user@realm!name),
#      PVE_TOKEN_SECRET, PVE_NODE (proxmox-alv), REFERENCE_VMID (997),
#      TEMPLATE_STORAGE (disk-hdd), IMPORT_STORAGE (local; needs the "Import"
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
tstore="${TEMPLATE_STORAGE:-disk-hdd}"
istore="${IMPORT_STORAGE:-local}"
imghash="$(basename "$(dirname "$(readlink -f "$image")")" | cut -c1-12)"
vtag="k8s-v${version}"
itag="img-${imghash}"
tags_new="kaassopeia;${vtag};${itag}"
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

# Fail here (TLS, token, routing) rather than inside a condition below.
echo "Proxmox API: $(api GET /version | jq -r '"version \(.version)"')"

if templates | awk '{print $2}' | tr ';' '\n' | grep -qx "$itag"; then
  echo "image ${imghash} already published for ${vtag}, nothing to do"
  exit 0
fi

volid="${istore}:import/${file}"
size="$(stat -Lc %s "$image")"
have="$(api GET "/nodes/${node}/storage/${istore}/content?content=import" | jq -r --arg v "$volid" '.[] | select(.volid == $v) | .size')"
if [ "$have" = "$size" ]; then
  echo "${volid} already uploaded (${size} bytes), reusing it"
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

refcfg="$(api GET "/nodes/${node}/qemu/${ref}/config")"
disk_key="$(jq -r 'to_entries[] | select(.key|test("^(scsi|virtio|sata|ide)[0-9]+$")) | select(.value|test("cloudinit|media=cdrom")|not) | .key' <<<"$refcfg" | head -1)"
ci_key="$(jq -r 'to_entries[] | select(.value|tostring|test("cloudinit")) | .key' <<<"$refcfg" | head -1)"
vmid="$(api GET /cluster/nextid | jq -r .)"
args=(
  -d "vmid=${vmid}"
  --data-urlencode "name=kaassopeia-${version//./-}"
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

echo "creating VM ${vmid} (hardware from ${ref}, disk on ${tstore})..."
printf '  %s\n' "${args[@]}" | grep -v '^  -' | grep -v '^  --' || true
upid="$(api POST "/nodes/${node}/qemu" "${args[@]}" | jq -r .)"
wait_task "$upid"
echo "converting ${vmid} to a template..."
upid="$(api POST "/nodes/${node}/qemu/${vmid}/template" | jq -r .)"
wait_task "$upid"
api DELETE "/nodes/${node}/storage/${istore}/content/$(jq -rn --arg v "$volid" '$v|@uri')" >/dev/null || echo "warning: could not delete ${volid}" >&2

# Only the new template keeps the version tag.
templates | while read -r id tags; do
  [ "$id" = "$vmid" ] && continue
  if tr ';' '\n' <<<"$tags" | grep -qx "$vtag"; then
    newtags="$(tr ';' '\n' <<<"$tags" | sed "s/^${vtag}\$/superseded-${vtag}/" | paste -sd';')"
    echo "template ${id}: ${tags} -> ${newtags}"
    api PUT "/nodes/${node}/qemu/${id}/config" --data-urlencode "tags=${newtags}" >/dev/null
  fi
done
echo "published template ${vmid}: ${tags_new}"
