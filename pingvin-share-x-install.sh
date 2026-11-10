#!/usr/bin/env bash
# Installs Pingvin Share X on Ubuntu 22.04, 24.04, or 26.04 from an offline mirror.
# The binary and Caddy come from the mirror, and each is checked against the sha256 value in this script.
#
# The installer asks for each value when a terminal is attached. A value that is already set in the
# environment is not asked for:
#   PINGVIN_TLS           http (default: plain HTTP), internal (a CA made here), or file (your certificate)
#   PINGVIN_HOST          host name or IP address that users type (TLS modes; the certificate is made for it)
#   PINGVIN_TLS_CERT_FILE PEM certificate with the full chain (PINGVIN_TLS=file)
#   PINGVIN_TLS_KEY_FILE  PEM private key (PINGVIN_TLS=file)
#   PINGVIN_PORT          port that users open: 3000 with http, 443 with the TLS modes
#   PINGVIN_HTTP_PORT     port that redirects to HTTPS in the TLS modes (default 80)
#   NONINTERACTIVE=1      never prompt; values that are not set take their defaults
set -euo pipefail

INSTALL_DIR=/opt/pingvin-share-x
SERVICE=pingvin-share-x
BACKEND_PORT=13000
MIRROR_FILES="http://188.213.67.196:8080/files"
declare -A MIRROR_SHA256=(
  ["caddy/linux-amd64/caddy"]="678ade3bfc088749c81a681adc603333ee0bb023b6a6cfe3c0f58bef8ff854e9"
  ["caddy/linux-arm64/caddy"]="0019d864a2cdee41c3675cb2a26185833c5d9540a48f5a6729142c0413461b60"
  ["pingvin-share-x/linux-amd64/pingvin-share-x"]="807653c569694a8c7504100dc7e664af39e801fb04d06a295b79f6eae32e8400"
  ["pingvin-share-x/linux-arm64/pingvin-share-x"]="2a75bbb3357bea6cba1350c22acb753f655d765270f782b10fc438a459dc3ab6"
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
    # port_free <port>: stops when another program already listens on that TCP port.
    ss -ltnH "sport = :$1" | grep -q . && die "TCP port $1 is already in use"
    return 0
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
[ ! -e "$INSTALL_DIR/$SERVICE" ] || die "Pingvin Share X is already installed in $INSTALL_DIR; remove that directory to reinstall"

ask PINGVIN_TLS "TLS mode: http (plain HTTP), internal (a CA made here), or file (your certificate)" "http"
case "$PINGVIN_TLS" in
    http)
        echo "warning: plain HTTP. Anyone on the network can read the passwords and the shared files." >&2
        ;;
    internal)
        ask PINGVIN_HOST "host name or IP address that users type" "$(detect_ipv4)"
        ;;
    file)
        ask PINGVIN_HOST "host name or IP address that users type" "$(detect_ipv4)"
        ask PINGVIN_TLS_CERT_FILE "path to the certificate file (PEM, with the full chain)" ""
        ask PINGVIN_TLS_KEY_FILE "path to the private key file (PEM)" ""
        [ -r "$PINGVIN_TLS_CERT_FILE" ] || die "cannot read the certificate file $PINGVIN_TLS_CERT_FILE"
        [ -r "$PINGVIN_TLS_KEY_FILE" ] || die "cannot read the key file $PINGVIN_TLS_KEY_FILE"
        openssl x509 -in "$PINGVIN_TLS_CERT_FILE" -noout >/dev/null 2>&1 || die "$PINGVIN_TLS_CERT_FILE is not a certificate"
        openssl pkey -in "$PINGVIN_TLS_KEY_FILE" -noout >/dev/null 2>&1 || die "$PINGVIN_TLS_KEY_FILE is not a private key"
        [ "$(openssl x509 -in "$PINGVIN_TLS_CERT_FILE" -noout -pubkey | openssl pkey -pubin -outform der | sha256sum)" = \
          "$(openssl pkey -in "$PINGVIN_TLS_KEY_FILE" -pubout -outform der | sha256sum)" ] || die "the certificate and the key do not match"
        ;;
    *) die "PINGVIN_TLS must be http, internal, or file" ;;
esac
if [ "$PINGVIN_TLS" = http ]; then
    ask_port PINGVIN_PORT "HTTP port for users" "3000"
    port_free "$PINGVIN_PORT"
    PINGVIN_HOST="${PINGVIN_HOST:-$(detect_ipv4)}"
    URL="http://$PINGVIN_HOST:$PINGVIN_PORT"
    if [ "$PINGVIN_PORT" = 80 ]; then URL="http://$PINGVIN_HOST"; fi
else
    [[ "${PINGVIN_HOST:-}" =~ ^[A-Za-z0-9.-]+$ ]] || die "PINGVIN_HOST must be an IPv4 address or a domain name"
    ask_port PINGVIN_PORT "HTTPS port for users" "443"
    ask_port PINGVIN_HTTP_PORT "HTTP port that redirects to HTTPS" "80"
    [ "$PINGVIN_PORT" != "$PINGVIN_HTTP_PORT" ] || die "the HTTPS and HTTP ports must differ"
    port_free "$PINGVIN_PORT"
    port_free "$PINGVIN_HTTP_PORT"
    port_free "$BACKEND_PORT"
    if [ "$PINGVIN_PORT" = 443 ]; then URL="https://$PINGVIN_HOST"; else URL="https://$PINGVIN_HOST:$PINGVIN_PORT"; fi
fi

log "creating the service user and the install directory"
id pingvin-share >/dev/null 2>&1 || useradd --system --home-dir "$INSTALL_DIR" --shell /usr/sbin/nologin pingvin-share
install -d -m 0755 -o root -g root "$INSTALL_DIR"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
log "fetching and checking the binary for linux/$ARCH"
mirror_fetch "pingvin-share-x/linux-$ARCH/pingvin-share-x" "$TMP/$SERVICE"
install -m 0755 -o root -g root "$TMP/$SERVICE" "$INSTALL_DIR/$SERVICE"
# The binary unpacks its runtime and its data next to itself on first start, so that folder is writable.
chown pingvin-share:pingvin-share "$INSTALL_DIR"

TLS="$INSTALL_DIR/tls"
if [ "$PINGVIN_TLS" != http ]; then
    log "fetching and checking Caddy for linux/$ARCH"
    mirror_fetch "caddy/linux-$ARCH/caddy" "$TMP/caddy"
    install -m 0755 -o root -g root "$TMP/caddy" "$INSTALL_DIR/caddy"
    "$INSTALL_DIR/caddy" version >/dev/null || die "caddy does not run on this system"
    install -d -m 0750 -o pingvin-share -g pingvin-share "$INSTALL_DIR/caddy-data"
    install -d -m 0750 -o root -g pingvin-share "$TLS"
fi

case "$PINGVIN_TLS" in
    internal)
        log "creating the private certificate authority and the server certificate"
        openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
            -keyout "$TLS/ca.key" -out "$TLS/ca.crt" -days 3650 -subj "/CN=Pingvin Share X private CA" \
            -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" >/dev/null 2>&1
        if [[ "$PINGVIN_HOST" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then SAN="IP:$PINGVIN_HOST"; else SAN="DNS:$PINGVIN_HOST"; fi
        openssl req -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
            -keyout "$TLS/server.key" -out "$TLS/server.csr" -subj "/CN=$PINGVIN_HOST" \
            -addext "subjectAltName=$SAN" >/dev/null 2>&1
        openssl x509 -req -in "$TLS/server.csr" -CA "$TLS/ca.crt" -CAkey "$TLS/ca.key" -CAcreateserial \
            -out "$TLS/server.crt" -days 800 -copy_extensions copyall >/dev/null 2>&1
        rm -f "$TLS/server.csr" "$TLS/ca.srl"
        chmod 0600 "$TLS/ca.key"
        chown root:pingvin-share "$TLS/ca.crt"
        chmod 0644 "$TLS/ca.crt"
        ;;
    file)
        install -m 0644 -o root -g pingvin-share "$PINGVIN_TLS_CERT_FILE" "$TLS/server.crt"
        install -m 0640 -o root -g pingvin-share "$PINGVIN_TLS_KEY_FILE" "$TLS/server.key"
        ;;
esac
if [ "$PINGVIN_TLS" != http ]; then
    chown root:pingvin-share "$TLS/server.key" "$TLS/server.crt"
    chmod 0640 "$TLS/server.key"
    chmod 0644 "$TLS/server.crt"
fi

if [ "$PINGVIN_TLS" = http ]; then
    LISTEN="0.0.0.0:$PINGVIN_PORT"
    HEALTH="http://127.0.0.1:$PINGVIN_PORT/api/health"
else
    LISTEN="127.0.0.1:$BACKEND_PORT"
    HEALTH="http://127.0.0.1:$BACKEND_PORT/api/health"
    log "writing the HTTPS front end"
    # Clients that connect to an IP address send no SNI, so Caddy needs a default name to choose the certificate.
    cat >"$INSTALL_DIR/Caddyfile" <<CADDY
{
	admin off
	auto_https off
	default_sni $PINGVIN_HOST
}

https://$PINGVIN_HOST:$PINGVIN_PORT {
	tls $TLS/server.crt $TLS/server.key
	reverse_proxy 127.0.0.1:$BACKEND_PORT
}

http://$PINGVIN_HOST:$PINGVIN_HTTP_PORT {
	redir https://$PINGVIN_HOST:$PINGVIN_PORT{uri} permanent
}
CADDY
    chown root:pingvin-share "$INSTALL_DIR/Caddyfile"
    chmod 0644 "$INSTALL_DIR/Caddyfile"
    cat >/etc/systemd/system/$SERVICE-caddy.service <<UNIT
[Unit]
Description=HTTPS front end for Pingvin Share X
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=pingvin-share
Group=pingvin-share
WorkingDirectory=$INSTALL_DIR
Environment=XDG_CONFIG_HOME=$INSTALL_DIR/caddy-data/config XDG_DATA_HOME=$INSTALL_DIR/caddy-data/data
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
ExecStart=$INSTALL_DIR/caddy run --config $INSTALL_DIR/Caddyfile --adapter caddyfile
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
fi

log "installing the systemd service"
cat >/etc/systemd/system/$SERVICE.service <<UNIT
[Unit]
Description=Pingvin Share X
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=pingvin-share
Group=pingvin-share
WorkingDirectory=$INSTALL_DIR
Environment=PINGVIN_HOME=$INSTALL_DIR
Environment=PINGVIN_LISTEN=$LISTEN
ExecStart=$INSTALL_DIR/$SERVICE
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now "$SERVICE.service"
if [ "$PINGVIN_TLS" != http ]; then
    systemctl enable --now "$SERVICE-caddy.service"
fi

log "waiting for the first start (the runtime unpacks and the database is created)"
ready=no
for _ in $(seq 1 150); do
    if curl -fsS "$HEALTH" >/dev/null 2>&1; then
        ready=yes
        break
    fi
    sleep 2
done
[ "$ready" = yes ] || die "Pingvin Share X did not answer at $HEALTH; check: journalctl -u $SERVICE"
if [ "$PINGVIN_TLS" != http ]; then
    curl -fsSk --resolve "$PINGVIN_HOST:$PINGVIN_PORT:127.0.0.1" "$URL/api/health" >/dev/null 2>&1 \
        || die "the HTTPS front end does not answer at $URL; check: journalctl -u $SERVICE-caddy"
fi

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    log "opening the Pingvin Share X ports in ufw"
    ufw allow "$PINGVIN_PORT/tcp" >/dev/null
    [ "$PINGVIN_TLS" = http ] || ufw allow "$PINGVIN_HTTP_PORT/tcp" >/dev/null
fi

cat <<DONE

Pingvin Share X is running at $URL
  - Create the first account in the browser. Sign-up is open by default; change the policy in the admin settings.
DONE
case "$PINGVIN_TLS" in
    http) echo "  - Plain HTTP: the passwords and the shared files travel unencrypted. Use the TLS modes for public use." ;;
    internal) echo "  - Copy $TLS/ca.crt to each device and trust it, or browsers show a certificate warning." ;;
    file) echo "  - The certificate is the one you supplied; browsers trust it through its own authority." ;;
esac
echo "  - Logs: journalctl -u $SERVICE"
