#!/usr/bin/env bash
# System metrics generator for dashboard
# Outputs a JSON file to the web server root

set -Eeuo pipefail
umask 022

# Output configuration
OUT="/var/www/html/assets/status.json"
TMP="${OUT}.tmp.$$"

# Cleanup temp file on exit
trap 'rm -f "$TMP"' EXIT

# ISO 8601 timestamp
ts=$(date +"%Y-%m-%dT%H:%M:%S%:z")

# Helper function to check HTTP services
probe(){ 
  # usage: probe "Name" "URL" [expected_code]
  local name="$1" url="$2" expect="${3:-}" out code t ms ok=false
  
  # Silent curl with 4s timeout, writing code:time
  out=$(curl -sS --max-time 4 -o /dev/null -w "%{http_code}:%{time_total}" "$url" || echo "000:0")
  
  code="${out%%:*}"
  t="${out#*:}"
  ms=$(awk -v x="$t" 'BEGIN{printf "%d", x*1000}')
  
  if [[ -n "$expect" ]]; then 
    [[ "$code" == "$expect" ]] && ok=true
  else 
    [[ "$code" =~ ^2|3 ]] && ok=true
  fi
  
  printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$code" "$ms" "$ok" ""
}
# Service health checks
# Using localhost to bypass DNS issues
svcs_tsv=$(
  probe "Seafile (Web)"        "http://127.0.0.1:8083"       "302"
  probe "Seafile (FileServer)" "http://127.0.0.1:8084/seafhttp" "404"
  probe "Filebrowser"          "http://127.0.0.1:8085/"
  probe "Pi-hole"              "http://127.0.0.1:8080/admin" "301"
  probe "Router Gateway"       "http://192.168.1.1"
)

# Convert TSV to JSON using jq
# The 'note' field is localized for the user
svcs=$(printf '%s' "$svcs_tsv" | jq -R -s '
  split("\n") 
  | map(select(length>0)) 
  | map(split("\t"))
  | map({
      name: .[0],
      code: .[1],
      ms:   (.[2]|tonumber),
      ok:   (.[3]=="true"),
      note: (if .[0]=="Seafile (FileServer)" then "Error 404 esperado en backend" else "" end)
    })
')

# Check WireGuard UDP port
if ss -Huln | grep -qE '\:51820\s'; then
  svcs=$(jq '. + [ {"name":"WireGuard","ok":true,"code":"UDP","ms":0,"note":"Puerto 51820 Abierto"} ]' <<<"$svcs")
else
  svcs=$(jq '. + [ {"name":"WireGuard","ok":false,"code":"ERR","ms":0,"note":"Puerto 51820 Cerrado"} ]' <<<"$svcs")
fi
# Host metrics gathering
hostname=$(hostname)
model=$(tr -d '\0' </proc/device-tree/model 2>/dev/null || echo "Raspberry Pi")
. /etc/os-release 2>/dev/null || true; os="${PRETTY_NAME:-Linux}"
kernel=$(uname -r)

# Uptime translation to Spanish
uptime_es=$(uptime -p | sed -E \
  -e 's/^up //' \
  -e 's/years?/años/g' \
  -e 's/months?/meses/g' \
  -e 's/weeks?/semanas/g' \
  -e 's/days?/días/g' \
  -e 's/hours?/horas/g' \
  -e 's/minutes?/minutos/g' \
  -e 's/,/ y/g')

# Network interface IP detection
dev=$(ip -4 route ls default | awk '{print $5; exit}') || true
if [[ -n "${dev:-}" ]]; then
  ip=$(ip -4 -brief addr show dev "$dev" | awk '{print $3}' | cut -d/ -f1 | head -n1)
else
  ip="127.0.0.1"
fi

# System load
read l1 l5 l15 _ < /proc/loadavg

# Disk usage on root
read dtot dusd davl < <(df -B1 --output=size,used,avail / | tail -1)
dpct=$(( dtot>0 ? (dusd*100/dtot) : 0 ))

# Memory usage
mt=$(awk '/MemTotal:/{print $2}' /proc/meminfo)
ma=$(awk '/MemAvailable:/{print $2}' /proc/meminfo)
mu=$(( mt - ma ))
mp=$(( mt>0 ? (mu*100/mt) : 0 ))
mt_mb=$(( mt/1024 ))
mu_mb=$(( mu/1024 ))
# Swap usage
st=$(awk '/SwapTotal:/{print $2}' /proc/meminfo)
sf=$(awk '/SwapFree:/{print $2}' /proc/meminfo)
su=$(( st - sf ))
sp=$(( st>0 ? (su*100/st) : 0 ))
st_mb=$(( st/1024 ))
su_mb=$(( su/1024 ))

# CPU temperature
if [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
  cpu=$(awk '{printf "%.1f", $1/1000}' /sys/class/thermal/thermal_zone0/temp)
else
  cpu="N/A"
fi

# WireGuard clients activity
if command -v wg >/dev/null 2>&1; then
  now=$(date +%s); dump=$(wg show wg0 dump 2>/dev/null || true)
  vpn_total=$(printf "%s\n" "$dump" | awk 'NR>1{c++} END{print c+0}')
  # Count active if handshake was less than 150s ago
  vpn_active=$(printf "%s\n" "$dump" | awk -v now="$now" 'NR>1{hs=$6+0; if (hs>0 && (now-hs)<150) c++} END{print c+0}')
else
  vpn_total=0; vpn_active=0
fi

# Build host JSON object
host=$(jq -n \
  --arg hostname "$hostname" --arg model "$model" --arg os "$os" --arg kernel "$kernel" \
  --arg uptime "$uptime_es" --arg ip "$ip" --arg cpu "$cpu" \
  --arg l1 "$l1" --arg l5 "$l5" --arg l15 "$l15" \
  --arg Th "$(numfmt --to=iec --suffix=B "$dtot")" \
  --arg Uh "$(numfmt --to=iec --suffix=B "$dusd")" \
  --arg Ah "$(numfmt --to=iec --suffix=B "$davl")" \
  --argjson T "$dtot" --argjson U "$dusd" --argjson A "$davl" --argjson P "$dpct" \
  --argjson MT "$mt" --argjson MU "$mu" --argjson MP "$mp" \
  --argjson MTmb "$mt_mb" --argjson MUmb "$mu_mb" \
  --argjson ST "$st" --argjson SU "$su" --argjson SP "$sp" \
  --argjson STmb "$st_mb" --argjson SUmb "$su_mb" \
  --argjson VA "$vpn_active" --argjson VT "$vpn_total" '
 {
    hostname: $hostname, 
    model: $model, 
    os_pretty: $os, 
    kernel: $kernel,
    uptime: $uptime, 
    ip_lan: $ip, 
    cpu_temp_c: $cpu,
    loadavg: { "1min": $l1, "5min": $l5, "15min": $l15 },
    disk: { 
      total: $Th, usado: $Uh, libre: $Ah, porcentaje: ($P|tostring+"%"),
      bytes: { total: $T, usado: $U, libre: $A } 
    },
    memoria: { total_mb: $MTmb, usada_mb: $MUmb, porcentaje: $MP },
    swap: { total_mb: $STmb, usada_mb: $SUmb, porcentaje: $SP },
    vpn: { activos: $VA, total: $VT }
  }'
)

# Write output atomically
jq -n --arg ts "$ts" --argjson services "$svcs" --argjson host "$host" \
  '{generated_at: $ts, services: $services, host: $host}' > "$TMP"

chmod 0644 "$TMP"
mv -f "$TMP" "$OUT"
