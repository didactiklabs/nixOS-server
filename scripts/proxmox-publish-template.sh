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
#      content type), PVE_CACERT (CA file for the API certificate) or
#      PVE_INSECURE=1 (skip certificate verification).
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

curl_opts=(-fsS --retry 3 -H "Authorization: PVEAPIToken=${PVE_TOKEN_ID}=${PVE_TOKEN_SECRET}")
[ -n "${PVE_CACERT:-}" ] && curl_opts+=(--cacert "$PVE_CACERT")
[ "${PVE_INSECURE:-}" = 1 ] && curl_opts+=(-k)
api() { # api METHOD PATH [curl args...] -> .data
  local m="$1" p="$2"
  shift 2
  curl "${curl_opts[@]}" -X "$m" "${PVE_URL%/}/api2/json${p}" "$@" | jq -c '.data'
}
wait_task() {
  local upid="$1" st
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

if templates | awk '{print $2}' | tr ';' '\n' | grep -qx "$itag"; then
  echo "image ${imghash} already published for ${vtag}, nothing to do"
  exit 0
fi

echo "uploading ${file} to ${istore}..."
upid="$(curl "${curl_opts[@]}" -X POST "${PVE_URL%/}/api2/json/nodes/${node}/storage/${istore}/upload" \
  -F content=import -F "filename=@${image};filename=${file}" | jq -r '.data')"
wait_task "$upid"
volid="${istore}:import/${file}"

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
wait_task "$(api POST "/nodes/${node}/qemu" "${args[@]}" | jq -r .)"
echo "converting ${vmid} to a template..."
wait_task "$(api POST "/nodes/${node}/qemu/${vmid}/template" | jq -r .)"
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
