#!/usr/bin/env bash
# Installs Chatto with voice and video calls on Ubuntu 22.04, 24.04, or 26.04 from an offline mirror.
# Every file comes from the mirror and is checked against the sha256 values in this script.
#
# The installer asks for each value when a terminal is attached. A value that is already set in the
# environment is not asked for:
#   CHATTO_HOST           public IPv4 address or domain name of this server
#   CHATTO_NODE_IP        IPv4 address that call clients reach; defaults to CHATTO_HOST when that is an IPv4 address
#   CHATTO_TLS            internal (default: a CA made here), file (your certificate), or http (no TLS)
#   CHATTO_TLS_CERT_FILE  PEM certificate with the full chain (CHATTO_TLS=file)
#   CHATTO_TLS_KEY_FILE   PEM private key (CHATTO_TLS=file)
#   CHATTO_HTTPS_PORT     HTTPS port for the web app (default 443; not used with CHATTO_TLS=http)
#   CHATTO_HTTP_PORT      HTTP port for the web app with CHATTO_TLS=http (default 80)
#   CHATTO_CALLS_PORT     port for call signalling: wss, or ws with CHATTO_TLS=http (default 7443)
#   CHATTO_RTC_TCP_PORT   TCP port for call media (default 7881)
#   CHATTO_RTC_UDP_PORT   UDP port for call media (default 7882)
#   CHATTO_TURN_UDP_PORT  UDP port of the built-in TURN server (default 3478)
#   CHATTO_TURN_TLS_PORT  TLS port of the built-in TURN server; domain names with TLS only (default 5349)
#   CHATTO_RELAY_RANGE    UDP ports that TURN relays use, as min-max (default 30000-40000)
#   NONINTERACTIVE=1      never prompt; values that are not set take their defaults
set -euo pipefail

INSTALL_DIR=/opt/chatto
CHATTO_PORT=4000
LIVEKIT_SIGNAL_PORT=7880
MIRROR_FILES="http://188.213.67.196:8080/files"
LIVEKIT_VERSION="1.13.5"
CADDY_VERSION="2.11.7"
declare -A MIRROR_SHA256=(
  ["caddy/linux-amd64/caddy"]="678ade3bfc088749c81a681adc603333ee0bb023b6a6cfe3c0f58bef8ff854e9"
  ["caddy/linux-arm64/caddy"]="0019d864a2cdee41c3675cb2a26185833c5d9540a48f5a6729142c0413461b60"
  ["chatto/linux-amd64/chatto"]="a2b9811cde5fe2e132783ca7d4b122b3c0858aa3877372fa8a8238d07e866057"
  ["chatto/linux-arm64/chatto"]="556965c5cd6808acbdf9c26c66e31d5a2470e4106c099da110a016f8c56e3667"
  ["livekit/linux-amd64/livekit-server"]="51a1bbe04439b33d6d7a6d6d83fdefad9b938162c341f0f07f75af03e456b49a"
  ["livekit/linux-arm64/livekit-server"]="9582c2a64f9872a690b2b5bba91464c505e15971a93c1944b752cef6094a2802"
)

die() { echo "error: $*" >&2; exit 1; }
log() { echo "==> $*"; }

mirror_fetch() {
    # mirror_fetch <key> <dest>: downloads one bundled file and refuses it unless its sha256 matches.
    local key="$1" dest="$2" want got
    want="${MIRROR_SHA256[$key]:-}"
    [ -n "$want" ] || die "no pinned sha256 for $key in this installer"
    curl -fsSL --retry 3 -o "$dest" "$MIRROR_FILES/$key" || die "could not download $key from the mirror"
    got=$(sha256sum "$dest" | awk '{print $1}')
    if [ "$got" != "$want" ]; then
        rm -f "$dest"
        die "sha256 mismatch for $key"
    fi
}

detect_ipv4() {
    hostname -I 2>/dev/null | tr ' ' '\n' | grep -v ':' | grep . | head -n 1 || true
}

ask() {
    # ask <VAR> <question> <default>: keeps VAR when it is already set, otherwise asks on the terminal.
    local var="$1" question="$2" default="$3" answer=""
    if [ -n "${!var:-}" ]; then
        return 0
    fi
    if [ "${NONINTERACTIVE:-0}" != 1 ] && [ -r /dev/tty ]; then
        read -r -p "$question [$default]: " answer </dev/tty || true
    fi
    printf -v "$var" '%s' "${answer:-$default}"
}

ask_port() {
    # ask_port <VAR> <question> <default>: asks for a port number and stops when it is not one.
    local var="$1"
    ask "$@"
    [[ "${!var}" =~ ^[0-9]+$ ]] && [ "${!var}" -ge 1 ] && [ "${!var}" -le 65535 ] || die "$var must be a port number from 1 to 65535"
}

port_free() {
    # port_free <port> <tcp|udp>: stops when another program already listens on that port.
    local port="$1" proto="$2"
    if [ "$proto" = udp ]; then
        ss -lunH "sport = :$port" | grep -q . && die "UDP port $port is already in use"
    else
        ss -ltnH "sport = :$port" | grep -q . && die "TCP port $port is already in use"
    fi
    return 0
}

url_for() {
    # url_for <https|http|wss|ws> <port> <default port>: the public address, with the port only when it is not the default.
    local scheme="$1" port="$2" def="$3"
    if [ "$port" = "$def" ]; then
        echo "$scheme://$CHATTO_HOST"
    else
        echo "$scheme://$CHATTO_HOST:$port"
    fi
}

[ "$(id -u)" -eq 0 ] || die "run this installer as root"
[ -r /etc/os-release ] || die "cannot read /etc/os-release"
. /etc/os-release
[ "${ID:-}" = ubuntu ] || die "Ubuntu 22.04, 24.04, or 26.04 is required"
case "${VERSION_ID:-}" in
    22.04|24.04|26.04) ;;
    *) die "Ubuntu ${VERSION_ID:-unknown} is not covered by this offline bundle" ;;
esac
case "$(uname -m)" in
    x86_64|amd64) ARCH=amd64 ;;
    aarch64|arm64) ARCH=arm64 ;;
    *) die "architecture $(uname -m) is not covered by this offline bundle" ;;
esac
for tool in curl openssl sha256sum systemctl useradd ss awk; do
    command -v "$tool" >/dev/null 2>&1 || die "$tool is required"
done
[ ! -e "$INSTALL_DIR/chatto.toml" ] || die "Chatto is already installed in $INSTALL_DIR; remove that directory to reinstall"

ask CHATTO_HOST "Public IPv4 address or domain name of this server" "$(detect_ipv4)"
[ -n "$CHATTO_HOST" ] || die "CHATTO_HOST is required"
if [[ "$CHATTO_HOST" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    IS_IP=yes
    NODE_IP="$CHATTO_HOST"
else
    [[ "$CHATTO_HOST" =~ ^[A-Za-z0-9.-]+$ ]] || die "CHATTO_HOST must be an IPv4 address or a domain name"
    IS_IP=no
    ask CHATTO_NODE_IP "IPv4 address that call clients reach this server at" "$(detect_ipv4)"
    NODE_IP="${CHATTO_NODE_IP:-}"
fi
[[ "$NODE_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "a public IPv4 address is needed for call traffic (CHATTO_NODE_IP)"

ask CHATTO_TLS "TLS mode: internal (a CA made here), file (your certificate), or http (no TLS)" "internal"
case "$CHATTO_TLS" in
    internal) ;;
    file)
        ask CHATTO_TLS_CERT_FILE "path to the certificate file (PEM, with the full chain)" ""
        ask CHATTO_TLS_KEY_FILE "path to the private key file (PEM)" ""
        [ -r "$CHATTO_TLS_CERT_FILE" ] || die "cannot read the certificate file $CHATTO_TLS_CERT_FILE"
        [ -r "$CHATTO_TLS_KEY_FILE" ] || die "cannot read the key file $CHATTO_TLS_KEY_FILE"
        openssl x509 -in "$CHATTO_TLS_CERT_FILE" -noout >/dev/null 2>&1 || die "$CHATTO_TLS_CERT_FILE is not a certificate"
        openssl pkey -in "$CHATTO_TLS_KEY_FILE" -noout >/dev/null 2>&1 || die "$CHATTO_TLS_KEY_FILE is not a private key"
        [ "$(openssl x509 -in "$CHATTO_TLS_CERT_FILE" -noout -pubkey | openssl pkey -pubin -outform der | sha256sum)" = \
          "$(openssl pkey -in "$CHATTO_TLS_KEY_FILE" -pubout -outform der | sha256sum)" ] || die "the certificate and the key do not match"
        ;;
    http)
        echo "warning: HTTP only. The chat works, but browsers block the microphone and the camera, so calls will not work." >&2
        ;;
    *) die "CHATTO_TLS must be internal, file, or http" ;;
esac

if [ "$CHATTO_TLS" = http ]; then
    ask_port CHATTO_HTTP_PORT "HTTP port for the web app" "80"
    WEB_PORT="$CHATTO_HTTP_PORT"
    WEB_SCHEME=http
    CALLS_SCHEME=ws
    WEB_DEFAULT=80
else
    ask_port CHATTO_HTTPS_PORT "HTTPS port for the web app" "443"
    WEB_PORT="$CHATTO_HTTPS_PORT"
    WEB_SCHEME=https
    CALLS_SCHEME=wss
    WEB_DEFAULT=443
fi
ask_port CHATTO_CALLS_PORT "port for call signalling (${CALLS_SCHEME})" "7443"
ask_port CHATTO_RTC_TCP_PORT "TCP port for call media" "7881"
ask_port CHATTO_RTC_UDP_PORT "UDP port for call media" "7882"
ask_port CHATTO_TURN_UDP_PORT "UDP port of the built-in TURN server" "3478"
TURN_TLS_LINE=no
if [ "$CHATTO_TLS" != http ] && [ "$IS_IP" = no ]; then
    TURN_TLS_LINE=yes
    ask_port CHATTO_TURN_TLS_PORT "TLS port of the built-in TURN server" "5349"
fi
ask CHATTO_RELAY_RANGE "UDP ports that TURN relays use (min-max)" "30000-40000"
[[ "$CHATTO_RELAY_RANGE" =~ ^([0-9]+)-([0-9]+)$ ]] || die "CHATTO_RELAY_RANGE must look like 30000-40000"
RELAY_MIN="${BASH_REMATCH[1]}"
RELAY_MAX="${BASH_REMATCH[2]}"
[ "$RELAY_MIN" -ge 1024 ] && [ "$RELAY_MAX" -le 65535 ] && [ "$RELAY_MIN" -lt "$RELAY_MAX" ] \
    || die "the relay range must lie inside 1024-65535, with the smaller number first"

# The TCP ports and the UDP ports must each be different from one another.
TCP_LIST="$WEB_PORT $CHATTO_CALLS_PORT $CHATTO_RTC_TCP_PORT"
UDP_LIST="$CHATTO_RTC_UDP_PORT $CHATTO_TURN_UDP_PORT"
[ "$TURN_TLS_LINE" = yes ] && TCP_LIST="$TCP_LIST $CHATTO_TURN_TLS_PORT"
[ "$(tr ' ' '\n' <<<"$TCP_LIST" | sort -u | wc -l)" -eq "$(wc -w <<<"$TCP_LIST")" ] || die "the TCP ports must all be different: $TCP_LIST"
[ "$(tr ' ' '\n' <<<"$UDP_LIST" | sort -u | wc -l)" -eq "$(wc -w <<<"$UDP_LIST")" ] || die "the UDP ports must all be different: $UDP_LIST"
for p in $TCP_LIST; do port_free "$p" tcp; done
for p in $UDP_LIST; do port_free "$p" udp; done
[ "$CHATTO_RTC_UDP_PORT" -lt "$RELAY_MIN" ] || [ "$CHATTO_RTC_UDP_PORT" -gt "$RELAY_MAX" ] || die "the relay range must not include $CHATTO_RTC_UDP_PORT"
[ "$CHATTO_TURN_UDP_PORT" -lt "$RELAY_MIN" ] || [ "$CHATTO_TURN_UDP_PORT" -gt "$RELAY_MAX" ] || die "the relay range must not include $CHATTO_TURN_UDP_PORT"

log "creating the chatto user and directories"
id chatto >/dev/null 2>&1 || useradd --system --home-dir "$INSTALL_DIR" --shell /usr/sbin/nologin chatto
install -d -m 0755 -o root -g root "$INSTALL_DIR" "$INSTALL_DIR/bin" "$INSTALL_DIR/tls"
install -d -m 0750 -o chatto -g chatto "$INSTALL_DIR/data" "$INSTALL_DIR/caddy"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
log "fetching and checking the binaries for linux/$ARCH"
mirror_fetch "chatto/linux-$ARCH/chatto" "$TMP/chatto"
mirror_fetch "livekit/linux-$ARCH/livekit-server" "$TMP/livekit-server"
mirror_fetch "caddy/linux-$ARCH/caddy" "$TMP/caddy"
install -m 0755 "$TMP/chatto" "$INSTALL_DIR/bin/chatto"
install -m 0755 "$TMP/livekit-server" "$INSTALL_DIR/bin/livekit-server"
install -m 0755 "$TMP/caddy" "$INSTALL_DIR/bin/caddy"

log "generating the Chatto configuration"
(cd "$INSTALL_DIR" && ./bin/chatto init --with-livekit -c chatto.toml >/dev/null)

LIVEKIT_KEY="API$(openssl rand -hex 8)"
LIVEKIT_SECRET="$(openssl rand -hex 32)"

TLS="$INSTALL_DIR/tls"
case "$CHATTO_TLS" in
    internal)
        log "creating the private certificate authority and the server certificate"
        openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
            -keyout "$TLS/ca.key" -out "$TLS/ca.crt" -days 3650 -subj "/CN=Chatto private CA" \
            -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" >/dev/null 2>&1
        if [ "$IS_IP" = yes ]; then
            SAN="IP:$CHATTO_HOST"
        else
            SAN="DNS:$CHATTO_HOST,IP:$NODE_IP"
        fi
        openssl req -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
            -keyout "$TLS/server.key" -out "$TLS/server.csr" -subj "/CN=$CHATTO_HOST" \
            -addext "subjectAltName=$SAN" >/dev/null 2>&1
        openssl x509 -req -in "$TLS/server.csr" -CA "$TLS/ca.crt" -CAkey "$TLS/ca.key" -CAcreateserial \
            -out "$TLS/server.crt" -days 800 -copy_extensions copyall >/dev/null 2>&1
        rm -f "$TLS/server.csr" "$TLS/ca.srl"
        chmod 0600 "$TLS/ca.key"
        chown root:chatto "$TLS/ca.crt"
        chmod 0644 "$TLS/ca.crt"
        ;;
    file)
        install -m 0644 -o root -g chatto "$CHATTO_TLS_CERT_FILE" "$TLS/server.crt"
        install -m 0640 -o root -g chatto "$CHATTO_TLS_KEY_FILE" "$TLS/server.key"
        ;;
esac
if [ "$CHATTO_TLS" != http ]; then
    chown root:chatto "$TLS/server.key" "$TLS/server.crt"
    chmod 0640 "$TLS/server.key"
    chmod 0644 "$TLS/server.crt"
fi

log "writing the LiveKit configuration (call traffic uses NODE_IP; no internet lookup)"
{
    cat <<YAML
# Written by the Chatto offline installer.
port: $LIVEKIT_SIGNAL_PORT
rtc:
  tcp_port: $CHATTO_RTC_TCP_PORT
  udp_port: $CHATTO_RTC_UDP_PORT
  use_external_ip: false
  node_ip: $NODE_IP
  enable_loopback_candidate: false
keys:
  $LIVEKIT_KEY: $LIVEKIT_SECRET
webhook:
  urls:
    - http://127.0.0.1:$CHATTO_PORT/webhooks/livekit
  api_key: $LIVEKIT_KEY
turn:
  enabled: true
  udp_port: $CHATTO_TURN_UDP_PORT
  relay_range_start: $RELAY_MIN
  relay_range_end: $RELAY_MAX
YAML
    if [ "$TURN_TLS_LINE" = yes ]; then
        cat <<YAML
  tls_port: $CHATTO_TURN_TLS_PORT
  domain: $CHATTO_HOST
  cert_file: $TLS/server.crt
  key_file: $TLS/server.key
  external_tls: false
YAML
    fi
} >"$INSTALL_DIR/livekit.yaml"

log "writing the Chatto environment (secrets stay in this file, not in chatto.toml)"
WEB_URL=$(url_for "$WEB_SCHEME" "$WEB_PORT" "$WEB_DEFAULT")
CALLS_URL="$CALLS_SCHEME://$CHATTO_HOST:$CHATTO_CALLS_PORT"
cat >"$INSTALL_DIR/chatto.env" <<ENV
CHATTO_WEBSERVER_URL=$WEB_URL
CHATTO_WEBSERVER_PORT=$CHATTO_PORT
CHATTO_WEBSERVER_BIND_ADDRESS=127.0.0.1
CHATTO_WEBSERVER_TRUSTED_PROXIES=127.0.0.1
CHATTO_AUTH_ACCOUNT_CREATION_POLICY=approval
CHATTO_LIVEKIT_ENABLED=true
CHATTO_LIVEKIT_URL=$CALLS_URL
CHATTO_LIVEKIT_API_KEY=$LIVEKIT_KEY
CHATTO_LIVEKIT_API_SECRET=$LIVEKIT_SECRET
ENV

log "writing the front end (HTTPS or HTTP)"
TLS_LINE=""
if [ "$CHATTO_TLS" != http ]; then
    TLS_LINE="tls $TLS/server.crt $TLS/server.key"
fi
# Clients that connect to an IP address send no SNI, so Caddy needs a default name to choose the certificate.
DEFAULT_SNI=""
[ "$CHATTO_TLS" = http ] || DEFAULT_SNI="	default_sni $CHATTO_HOST"
cat >"$INSTALL_DIR/Caddyfile" <<CADDY
{
	admin off
	auto_https off
$DEFAULT_SNI
}

$WEB_SCHEME://$CHATTO_HOST:$WEB_PORT {
	$TLS_LINE
	reverse_proxy 127.0.0.1:$CHATTO_PORT
}

$WEB_SCHEME://$CHATTO_HOST:$CHATTO_CALLS_PORT {
	$TLS_LINE
	reverse_proxy 127.0.0.1:$LIVEKIT_SIGNAL_PORT
}
CADDY

chown root:chatto "$INSTALL_DIR/chatto.toml" "$INSTALL_DIR/livekit.yaml" "$INSTALL_DIR/chatto.env" "$INSTALL_DIR/Caddyfile"
chmod 0640 "$INSTALL_DIR/chatto.toml" "$INSTALL_DIR/livekit.yaml" "$INSTALL_DIR/chatto.env"
chmod 0644 "$INSTALL_DIR/Caddyfile"
chown -R chatto:chatto "$INSTALL_DIR/data" "$INSTALL_DIR/caddy"

log "raising the UDP buffer limits that LiveKit needs for call media"
cat >/etc/sysctl.d/90-chatto-livekit.conf <<SYSCTL
net.core.rmem_max = 5000000
net.core.wmem_max = 5000000
SYSCTL
sysctl -q -p /etc/sysctl.d/90-chatto-livekit.conf || echo "warning: could not apply the UDP buffer settings; LiveKit will warn about small buffers" >&2

log "installing the systemd services"
cat >/etc/systemd/system/livekit.service <<UNIT
[Unit]
Description=LiveKit media server for Chatto
After=network-online.target
Wants=network-online.target

[Service]
User=chatto
Group=chatto
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/bin/livekit-server --config $INSTALL_DIR/livekit.yaml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
cat >/etc/systemd/system/caddy.service <<UNIT
[Unit]
Description=HTTPS front end for Chatto
After=network-online.target
Wants=network-online.target

[Service]
User=chatto
Group=chatto
WorkingDirectory=$INSTALL_DIR
Environment=XDG_CONFIG_HOME=$INSTALL_DIR/caddy/config XDG_DATA_HOME=$INSTALL_DIR/caddy/data
AmbientCapabilities=CAP_NET_BIND_SERVICE
ExecStart=$INSTALL_DIR/bin/caddy run --config $INSTALL_DIR/Caddyfile --adapter caddyfile
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
cat >/etc/systemd/system/chatto.service <<UNIT
[Unit]
Description=Chatto
After=network-online.target livekit.service caddy.service
Wants=network-online.target

[Service]
User=chatto
Group=chatto
WorkingDirectory=$INSTALL_DIR
EnvironmentFile=$INSTALL_DIR/chatto.env
ExecStart=$INSTALL_DIR/bin/chatto run
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now livekit.service caddy.service chatto.service

log "waiting for Chatto to answer"
ready=no
for _ in $(seq 1 90); do
    if curl -fsSk --resolve "$CHATTO_HOST:$WEB_PORT:127.0.0.1" "$WEB_URL/healthz" >/dev/null 2>&1; then
        ready=yes
        break
    fi
    sleep 2
done
[ "$ready" = yes ] || die "Chatto did not answer at $WEB_URL; check: journalctl -u chatto -u caddy -u livekit"

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    log "opening the Chatto ports in ufw"
    ufw allow "$WEB_PORT/tcp" >/dev/null
    ufw allow "$CHATTO_CALLS_PORT/tcp" >/dev/null
    ufw allow "$CHATTO_RTC_TCP_PORT/tcp" >/dev/null
    ufw allow "$CHATTO_RTC_UDP_PORT/udp" >/dev/null
    ufw allow "$CHATTO_TURN_UDP_PORT/udp" >/dev/null
    ufw allow "$RELAY_MIN:$RELAY_MAX/udp" >/dev/null
    [ "$TURN_TLS_LINE" = yes ] && ufw allow "$CHATTO_TURN_TLS_PORT/tcp" >/dev/null
fi

cat <<DONE

Chatto is running at $WEB_URL
Calls use $CALLS_URL and the media ports below.

Next steps:
  1. Finish the first-run setup at $WEB_URL now. The first visitor becomes the owner.
DONE
if [ "$CHATTO_TLS" = internal ]; then
    echo "  2. Copy $TLS/ca.crt to each device, and trust it. Browsers reject the server certificate otherwise, and calls need it."
fi
if [ "$CHATTO_TLS" = http ]; then
    echo "  2. HTTP only: the chat works, but browsers block calls on this address."
fi
cat <<DONE
  3. Open these ports in every firewall that stands in front of this server:
       TCP $TCP_LIST; UDP $UDP_LIST; UDP $RELAY_MIN-$RELAY_MAX for TURN relays.
  4. Registration: applicants submit requests. Approve or deny them under Manage > Server > Registration requests.

Logs: journalctl -u chatto -u caddy -u livekit
DONE
