#!/usr/bin/env bash
# Installs the Jitsi Meet server on Ubuntu 22.04, 24.04, or 26.04 from an offline mirror. One binary holds
# the web app, Prosody, Jicofo, Videobridge and a Java runtime. The download is checked against the sha256
# value in this script.
#
# The installer asks for each value when a terminal is attached. A value that is already set in the
# environment is not asked for:
#   JITSI_PUBLIC_HOST    host name or IP address that browsers use (required)
#   JITSI_XMPP_DOMAIN    XMPP domain for the conferences (default meet.local)
#   JITSI_TLS            internal (default: a CA made here), file (your certificate), or http (no TLS)
#   JITSI_TLS_CERT_FILE  PEM certificate with the full chain (JITSI_TLS=file)
#   JITSI_TLS_KEY_FILE   PEM private key (JITSI_TLS=file)
#   JITSI_HTTPS_PORT     HTTPS port for the web app (default 443; not used with JITSI_TLS=http)
#   JITSI_HTTP_PORT      HTTP port, used only with JITSI_TLS=http (default 80)
#   JITSI_UDP_PORT       UDP port of the Videobridge for media (default 10000)
#   NONINTERACTIVE=1     never prompt; values that are not set take their defaults
set -euo pipefail

INSTALL_DIR=/opt/jitsi-meet
SERVICE=jitsi-meet
MIRROR_FILES="http://188.213.67.196:8080/files"
declare -A MIRROR_SHA256=(
  ["jitsi-meet/jitsi-meet-server"]="031e7b1d28829913a09d8b0fdda6a23a98b32e70f2679a810941d03af16604be"
)

die() { echo "error: $*" >&2; exit 1; }
log() { echo "==> $*"; }

mirror_fetch() {
    # mirror_fetch <key> <dest>: downloads the bundled binary and refuses it unless its sha256 matches.
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
    # url_for <https|http> <port>: the public address, with the port only when it is not the scheme's default.
    if { [ "$1" = https ] && [ "$2" = 443 ]; } || { [ "$1" = http ] && [ "$2" = 80 ]; }; then
        echo "$1://$JITSI_PUBLIC_HOST"
    else
        echo "$1://$JITSI_PUBLIC_HOST:$2"
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
    x86_64|amd64) ;;
    *) die "architecture $(uname -m) is not covered by this offline bundle (amd64 only)" ;;
esac
for tool in curl sha256sum systemctl ss awk openssl; do
    command -v "$tool" >/dev/null 2>&1 || die "$tool is required"
done
[ ! -e "$INSTALL_DIR/bin/jitsi-meet-server" ] || die "Jitsi Meet is already installed in $INSTALL_DIR; remove that directory to reinstall"

ask JITSI_PUBLIC_HOST "host name or IP address that browsers use" ""
[ -n "$JITSI_PUBLIC_HOST" ] || die "JITSI_PUBLIC_HOST is required"
[[ "$JITSI_PUBLIC_HOST" =~ ^[A-Za-z0-9.-]+$ ]] || die "JITSI_PUBLIC_HOST may contain only letters, digits, dots, and dashes"
ask JITSI_XMPP_DOMAIN "XMPP domain for the conferences" "meet.local"
# TLS: the browsers need HTTPS for the microphone and the camera, so http is only for a test network.
ask JITSI_TLS "TLS mode: internal (a CA made here), file (your certificate), or http (no TLS)" "internal"
case "$JITSI_TLS" in
    internal) ;;
    file)
        ask JITSI_TLS_CERT_FILE "path to the certificate file (PEM, with the full chain)" ""
        ask JITSI_TLS_KEY_FILE "path to the private key file (PEM)" ""
        [ -r "$JITSI_TLS_CERT_FILE" ] || die "cannot read the certificate file $JITSI_TLS_CERT_FILE"
        [ -r "$JITSI_TLS_KEY_FILE" ] || die "cannot read the key file $JITSI_TLS_KEY_FILE"
        openssl x509 -in "$JITSI_TLS_CERT_FILE" -noout >/dev/null 2>&1 || die "$JITSI_TLS_CERT_FILE is not a certificate"
        openssl pkey -in "$JITSI_TLS_KEY_FILE" -noout >/dev/null 2>&1 || die "$JITSI_TLS_KEY_FILE is not a private key"
        [ "$(openssl x509 -in "$JITSI_TLS_CERT_FILE" -noout -pubkey | openssl pkey -pubin -outform der | sha256sum)" = \
          "$(openssl pkey -in "$JITSI_TLS_KEY_FILE" -pubout -outform der | sha256sum)" ] || die "the certificate and the key do not match"
        ;;
    http)
        echo "warning: HTTP only. Browsers block the microphone and the camera on this address, so calls will not work." >&2
        ;;
    *) die "JITSI_TLS must be internal, file, or http" ;;
esac

if [ "$JITSI_TLS" = http ]; then
    ask_port JITSI_HTTP_PORT "HTTP port for the web app (no TLS)" "80"
    port_free "$JITSI_HTTP_PORT" tcp
    BASE=$(url_for http "$JITSI_HTTP_PORT")
    scheme=http
else
    ask_port JITSI_HTTPS_PORT "HTTPS port for the web app" "443"
    port_free "$JITSI_HTTPS_PORT" tcp
    BASE=$(url_for https "$JITSI_HTTPS_PORT")
    scheme=https
fi
# The HTTP port is only used in http mode; the settings file always names it.
: "${JITSI_HTTP_PORT:=80}" "${JITSI_HTTPS_PORT:=443}"
ask_port JITSI_UDP_PORT "UDP port of the Videobridge for media" "10000"
port_free "$JITSI_UDP_PORT" udp

log "creating the service user and the install folder"
id jitsi-meet >/dev/null 2>&1 || useradd --system --home-dir "$INSTALL_DIR" --shell /usr/sbin/nologin jitsi-meet
# The service user writes the runtime and the data here; the binary stays owned by root.
install -d -m 0755 -o jitsi-meet -g jitsi-meet "$INSTALL_DIR" "$INSTALL_DIR/data"
install -d -m 0755 -o root -g root "$INSTALL_DIR/bin"
install -d -m 0750 -o jitsi-meet -g jitsi-meet "$INSTALL_DIR/data/tls"
if [ "$JITSI_TLS" = file ]; then
    install -m 0644 -o jitsi-meet -g jitsi-meet "$JITSI_TLS_CERT_FILE" "$INSTALL_DIR/data/tls/server.crt"
    install -m 0600 -o jitsi-meet -g jitsi-meet "$JITSI_TLS_KEY_FILE" "$INSTALL_DIR/data/tls/server.key"
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
log "fetching and checking the server binary"
mirror_fetch "jitsi-meet/jitsi-meet-server" "$TMP/jitsi-meet-server"
install -m 0755 -o root -g root "$TMP/jitsi-meet-server" "$INSTALL_DIR/bin/jitsi-meet-server"

log "writing the settings"
(umask 077; cat >"$INSTALL_DIR/jitsi-meet.env" <<ENV
JITSI_PUBLIC_HOST=$JITSI_PUBLIC_HOST
JITSI_XMPP_DOMAIN=$JITSI_XMPP_DOMAIN
JITSI_HTTPS_LISTEN=:$JITSI_HTTPS_PORT
JITSI_HTTP_LISTEN=:$JITSI_HTTP_PORT
JITSI_TLS=$JITSI_TLS
JITSI_UDP_PORT=$JITSI_UDP_PORT
ENV
)

log "installing the systemd service"
cat >/etc/systemd/system/$SERVICE.service <<UNIT
[Unit]
Description=Jitsi Meet server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=jitsi-meet
Group=jitsi-meet
WorkingDirectory=$INSTALL_DIR
EnvironmentFile=$INSTALL_DIR/jitsi-meet.env
# Ports below 1024 need this capability; the service has no other privilege.
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
ExecStart=$INSTALL_DIR/bin/jitsi-meet-server
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now "$SERVICE.service"

# The first start unpacks the runtime and starts Prosody, Jicofo and Videobridge before HTTPS answers.
log "waiting for the web server (the first start can take a few minutes)"
if [ "$JITSI_TLS" = http ]; then WEB_PORT="$JITSI_HTTP_PORT"; else WEB_PORT="$JITSI_HTTPS_PORT"; fi
ready=no
for _ in $(seq 1 180); do
    if curl -fsSk --resolve "$JITSI_PUBLIC_HOST:$WEB_PORT:127.0.0.1" "$BASE/" >/dev/null 2>&1; then
        ready=yes
        break
    fi
    sleep 2
done
[ "$ready" = yes ] || die "Jitsi Meet did not answer on $BASE/; check: journalctl -u $SERVICE"

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    log "opening the web and media ports in ufw"
    ufw allow "$WEB_PORT/tcp" >/dev/null
    ufw allow "$JITSI_UDP_PORT/udp" >/dev/null
fi

cat <<DONE

Jitsi Meet is running at $BASE/
Media uses UDP port $JITSI_UDP_PORT on this server.
DONE
if [ "$JITSI_TLS" = internal ]; then
    echo "Browsers that open the page must trust the local CA certificate: $INSTALL_DIR/data/tls/ca.crt"
fi
echo "Logs: journalctl -u $SERVICE"
