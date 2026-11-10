#!/bin/bash
# Installs Backhaul (https://github.com/Musixal/Backhaul) from the offline mirror and runs it as the backhaul service.
#
# The menu installs the binary, then writes /etc/backhaul/config.toml for this machine as the server (the side that
# listens for the tunnel) or as the client (the side that connects to it). Each value is asked for on the terminal.
# NONINTERACTIVE=1 takes the defaults, and a value that is set in the environment is not asked for.
# Every download is checked against the sha256 value in this script. Run it as root.
set -euo pipefail
umask 022

BACKHAUL_TAG="v0.7.2"
MIRROR_BASE="http://188.213.67.196:8080/files"
declare -A MIRROR_SHA256=(
  ["apt/22.04/amd64/haproxy/haproxy_2.4.30-0ubuntu0.22.04.2_amd64.deb"]="3b9c67cf816775f1e516edd3eca5ebf7cb68963feb939932ee1b652ee130d853"
  ["apt/22.04/amd64/haproxy/jq_1.6-2.1ubuntu3.2_amd64.deb"]="4e8c6cd028729579074bd17c0d8d9f03fde2bd482244ca20c22238ae726edf1b"
  ["apt/22.04/amd64/haproxy/libjq1_1.6-2.1ubuntu3.2_amd64.deb"]="060f21dd061c83b3803dcdb0f64f1c7bcf4bc16e3e13fa68e0ed63b202d18245"
  ["apt/22.04/amd64/haproxy/liblua5.3-0_5.3.6-1build1_amd64.deb"]="54720e25dccf40c688fe5755b8b741f8c905937c49da67544d59c35192899e39"
  ["apt/22.04/amd64/haproxy/libonig5_6.9.7.1-2build1_amd64.deb"]="b02dbaa37b4ec7ad303cc8655b03a2a158299ce56fede9849e3bda501831f413"
  ["apt/22.04/amd64/haproxy/unzip_6.0-26ubuntu3.2_amd64.deb"]="4f274ffc6774d52878322ef1e3eb6d185003e1607448e62893849825bfae347d"
  ["apt/22.04/arm64/haproxy/haproxy_2.4.30-0ubuntu0.22.04.2_arm64.deb"]="7fb635e1e1cf03464d2b7359cba8a32b7302d796b1527b9da366e86236467b46"
  ["apt/22.04/arm64/haproxy/jq_1.6-2.1ubuntu3.2_arm64.deb"]="68896fbdf8e6ae7dfff173c9de6f63c530a50d5bf674e3ee735c45616fb43b76"
  ["apt/22.04/arm64/haproxy/libjq1_1.6-2.1ubuntu3.2_arm64.deb"]="4f659195b1ace2315f2c720ab07ec4bf8366898d3786eb326d07760eb810bb70"
  ["apt/22.04/arm64/haproxy/liblua5.3-0_5.3.6-1build1_arm64.deb"]="fe34c3940ac3a14499dec5f5c2a9bc76c98d15ab4a82e98e459e1d82faf5fc62"
  ["apt/22.04/arm64/haproxy/libonig5_6.9.7.1-2build1_arm64.deb"]="38624d0a72080e17a09d10a95f0336747c5f26d5c809ca5b357c7c138be99a7b"
  ["apt/22.04/arm64/haproxy/unzip_6.0-26ubuntu3.2_arm64.deb"]="793aedf54de24cf57a6c15b9d7710caaa119a934a1bba9c967a87792566e1c1e"
  ["apt/24.04/amd64/haproxy/adduser_3.137ubuntu1_all.deb"]="542aff2395eb912a56833e11a78076342779689d8fede7adcf08d1d6b0d0cd8b"
  ["apt/24.04/amd64/haproxy/haproxy_2.8.16-0ubuntu0.24.04.3_amd64.deb"]="934fee7a7a0bf7610649d6927da5ed712136a72b22c1ae5f329c14599a1f9c8a"
  ["apt/24.04/amd64/haproxy/jq_1.7.1-3ubuntu0.24.04.2_amd64.deb"]="f59183392f84fe67b407b494d8ba6185e9b0e4a106ffcb369490bd20a83fd40e"
  ["apt/24.04/amd64/haproxy/libjq1_1.7.1-3ubuntu0.24.04.2_amd64.deb"]="078fbf38b2e7c3f24cc5dc894d1bb03b617894b887a6e13d5943e13818e724f3"
  ["apt/24.04/amd64/haproxy/liblua5.4-0_5.4.6-3build2_amd64.deb"]="6a520259e5b06e86191a25af6d448387cdd2b3d291a0aa956ce272e84d071260"
  ["apt/24.04/amd64/haproxy/libonig5_6.9.9-1build1_amd64.deb"]="605f42287d2bcb6c84f5a02377c7cd777090c5e857259a4030a571989f19dde2"
  ["apt/24.04/amd64/haproxy/unzip_6.0-28ubuntu4.1_amd64.deb"]="a505b9d491386167bd8e14e3383315a4a7d6539e4406745901ccf009a7988271"
  ["apt/24.04/arm64/haproxy/adduser_3.137ubuntu1_all.deb"]="542aff2395eb912a56833e11a78076342779689d8fede7adcf08d1d6b0d0cd8b"
  ["apt/24.04/arm64/haproxy/haproxy_2.8.16-0ubuntu0.24.04.3_arm64.deb"]="036d8bf45d37f4e288d5891fd2b449ee80003551ee09ef9fcd1b3728166a5636"
  ["apt/24.04/arm64/haproxy/jq_1.7.1-3ubuntu0.24.04.2_arm64.deb"]="d26709d728bf14016eac6ec5e56f88027b1751dffe1471e8cda3f6f8a0c8c1dc"
  ["apt/24.04/arm64/haproxy/libjq1_1.7.1-3ubuntu0.24.04.2_arm64.deb"]="0dbdaf70784536d6dd15f2521101399e89b3b697926862e171b2beaffc6ac22e"
  ["apt/24.04/arm64/haproxy/liblua5.4-0_5.4.6-3build2_arm64.deb"]="6c7ddb1ac35d241e65e0cd0f7fd6c5508b1f52562021ee4fa681fa44a95bfd77"
  ["apt/24.04/arm64/haproxy/libonig5_6.9.9-1build1_arm64.deb"]="12044a8919f3aae339652bfcd8b424245d6606a6124ae3ce08682485c12b124f"
  ["apt/24.04/arm64/haproxy/unzip_6.0-28ubuntu4.1_arm64.deb"]="6c03087d20f67ec7333b65090e4bbcb7f680d4c045b1e81c8421634e87297d23"
  ["apt/26.04/amd64/haproxy/adduser_3.153ubuntu1_all.deb"]="78de3c5c3ec5657bcbdc10c2b2bcd9cedd78e6814182566f1522af422b26d3ce"
  ["apt/26.04/amd64/haproxy/haproxy_3.2.9-1ubuntu2.2_amd64.deb"]="dea67c09366e9a2197edcc1341031125c0989c345b9f4f62237f6aac153b5a4d"
  ["apt/26.04/amd64/haproxy/jq_1.8.1-4ubuntu2_amd64.deb"]="bb7f69de12414f6e52eea1da952ed7226b8e3fd9db74f93bb8ea3f2f39f4836f"
  ["apt/26.04/amd64/haproxy/libjemalloc2_5.3.0-4_amd64.deb"]="df00a1d37c735bfb1830418efb721c2c0b79cd0a735c3d35e4015eb6a4d2683d"
  ["apt/26.04/amd64/haproxy/libjq1_1.8.1-4ubuntu2_amd64.deb"]="3ced45ef4154cce59ce9fc74cc606b7361fa1b2f088b31a903d54fbcee75cb43"
  ["apt/26.04/amd64/haproxy/liblua5.4-0_5.4.8-1build1_amd64.deb"]="ff589ea3f181b89dd76b0240f79c59ac2f13f24e2053f624f774f596c7ef7897"
  ["apt/26.04/amd64/haproxy/libonig5_6.9.10-1build1_amd64.deb"]="050ad79c8c02956d896407ff66fddcb24e114b307cde196a0226697cf643ef88"
  ["apt/26.04/amd64/haproxy/unzip_6.0-29ubuntu1_amd64.deb"]="1f6f2bdcde84641e89c9367a7a99d90e990efa3e487a8d625241c2f9c55db5f4"
  ["apt/26.04/arm64/haproxy/adduser_3.153ubuntu1_all.deb"]="78de3c5c3ec5657bcbdc10c2b2bcd9cedd78e6814182566f1522af422b26d3ce"
  ["apt/26.04/arm64/haproxy/haproxy_3.2.9-1ubuntu2.2_arm64.deb"]="5e8bd19c6fc028245fcfdacb793198b7e29ecf70e74c8a3bccf3fcc794f5171a"
  ["apt/26.04/arm64/haproxy/jq_1.8.1-4ubuntu2_arm64.deb"]="cce43b39016580187284dbff0f2c0843225772e31ec30b039dd46f7b9231c781"
  ["apt/26.04/arm64/haproxy/libjemalloc2_5.3.0-4_arm64.deb"]="393bc51bf9d4c527abb95a0f50280b63f4882374b52d6cf261267f7ebb43d232"
  ["apt/26.04/arm64/haproxy/libjq1_1.8.1-4ubuntu2_arm64.deb"]="4d497013ca8167da61c173c60ced41ac1a190b776b637a1dd051d00dcce10142"
  ["apt/26.04/arm64/haproxy/liblua5.4-0_5.4.8-1build1_arm64.deb"]="1931d085d2232808f86af3b6ba7eda3abe535d8759cd668cad441d84f83b44fb"
  ["apt/26.04/arm64/haproxy/libonig5_6.9.10-1build1_arm64.deb"]="ccd57631285e57e0a509d3177153288689770ff65fdf16f3086eac8c799aa637"
  ["apt/26.04/arm64/haproxy/unzip_6.0-29ubuntu1_arm64.deb"]="91fad8e5a2ffc8076c645680f4bf6634c56b63a2725bd773f661e08b8fb5a53f"
  ["musixal/backhaul/v0.7.2/backhaul_linux_amd64.tar.gz"]="57bf95c2eabeddb1152d2e94ac42f4310883ce0fb909ee2a57bd53503b2dabbc"
  ["musixal/backhaul/v0.7.2/backhaul_linux_arm64.tar.gz"]="9a424c97ff16fc3f682e8314c418790d2b5bf3136e008edbb6cd402ea00999f6"
  ["musixal/easymesh/v1.2.0/easytier-linux-armv7/easytier-cli"]="b442c3d0ac327889e4538fb7e3d3b740b4a8246400e298ae3b83071289959aa0"
  ["musixal/easymesh/v1.2.0/easytier-linux-armv7/easytier-core"]="f916bc4666a925584ff05ac3733302c52f7276304b0b1991d8280c969241d809"
  ["musixal/easymesh/v1.2.0/easytier-linux-armv7hf/easytier-cli"]="4d257157889076bb07958ec0994a1bf57d645e88730a400320a64a78e3372d6d"
  ["musixal/easymesh/v1.2.0/easytier-linux-armv7hf/easytier-core"]="8049266be90c94a0f0e3539d0281e9aa4b23204023d910df84d17ac6bfbe2c25"
  ["musixal/easymesh/v1.2.0/easytier-linux-x86_64/easytier-cli"]="c70afa94a0c8cd78de887ba3a30dcdf8971461329fc444d098919e850496ed2d"
  ["musixal/easymesh/v1.2.0/easytier-linux-x86_64/easytier-core"]="c2e4e095b700e2513bf23ab14e5a87cd74fb2e1e90fba3ea3393d00432921f6b"
  ["musixal/easymesh/v2.0.3/easytier-linux-armv7/easytier-cli"]="bf6fbab324fcbfaead2112b816e425381722b5a2fa10bce9118b5a0d1dc67ed6"
  ["musixal/easymesh/v2.0.3/easytier-linux-armv7/easytier-core"]="e84c81ec2b5c078c7eac6bb15af6ff993d76e20cfdd4f035230bb9d50632c834"
  ["musixal/easymesh/v2.0.3/easytier-linux-armv7hf/easytier-cli"]="b9a60a35c43ad04d8499aa2fdd4a7f392a925ceb65e82002fb688b00d68edbac"
  ["musixal/easymesh/v2.0.3/easytier-linux-armv7hf/easytier-core"]="810585bef262cf9c937befd0407960b064340b399402c69eeed0b6f16d8ac970"
  ["musixal/easymesh/v2.0.3/easytier-linux-x86_64/easytier-cli"]="03ce9abdd311809119b6a6f2f739a658cccdbc53c9e834a9bb085a6be1df71ea"
  ["musixal/easymesh/v2.0.3/easytier-linux-x86_64/easytier-core"]="3782ffadd8d6483d1b70e63d859a028ca1b933ff6da0b9c9544267fc4035c0b2"
  ["musixal/rathole/rathole.zip"]="da96a27518aef8f90d8f0d4c8a0751cd54903c1d42577d62cd7266e05bc22f14"
  ["musixal/rathole/rathole_modified.zip"]="3dac37a4440ccf6c580edc8e53c2719c1da5c84c40e5f46f8a36965b78db615b"
)
BIN=/usr/local/bin/backhaul
CONF_DIR=/etc/backhaul
CONF="$CONF_DIR/config.toml"
UNIT=/etc/systemd/system/backhaul.service
TRANSPORTS="tcp tcpmux ws wsmux wss wssmux"

die() { echo "error: $*" >&2; exit 1; }
log() { echo "==> $*"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mirror_get() {
    # mirror_get URL DEST: downloads one bundled file, and fails unless its sha256 is the pinned one.
    local url="$1" dest="$2" key want got
    key="${url#"$MIRROR_BASE"/}"
    want="${MIRROR_SHA256[$key]:-}"
    [ -n "$want" ] || die "no pinned sha256 for $key in this installer"
    curl -fsSL --retry 3 -o "$dest" "$url" || die "could not download $key from the mirror"
    got=$(sha256sum "$dest" | awk '{print $1}')
    if [ "$got" != "$want" ]; then rm -f "$dest"; die "sha256 mismatch for $key"; fi
}

ask() {
    # ask VAR QUESTION DEFAULT: keeps VAR when it is already set, otherwise asks on the terminal.
    local var="$1" question="$2" default="$3" answer=""
    if [ -n "${!var:-}" ]; then return 0; fi
    if [ "${NONINTERACTIVE:-0}" != 1 ] && [ -r /dev/tty ]; then
        read -r -p "$question [$default]: " answer </dev/tty || true
    fi
    printf -v "$var" '%s' "${answer:-$default}"
}

valid_port() { [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ] && [ "$1" -le 65535 ]; }

valid_transport() {
    local t
    for t in $TRANSPORTS; do [ "$1" = "$t" ] && return 0; done
    return 1
}

valid_port_entry() {
    # One ports entry, in the forms of the Backhaul README: 443, 443-600, 443-600:5201, 4000=5000, 443=10.0.0.5:5201,
    # 127.0.0.2:443=5201, and so on.
    [[ "$1" =~ ^([0-9.]+:)?[0-9]+(-[0-9]+)?(:[0-9]+)?(=([A-Za-z0-9.-]+:)?[0-9]+)?$ ]]
}

port_free() {
    # port_free PORT: stops when another program already listens on that TCP port.
    if ss -ltnH "sport = :$1" | grep -q .; then die "TCP port $1 is already in use"; fi
}

[ "$(id -u)" -eq 0 ] || die "run this installer as root"
command -v systemctl >/dev/null 2>&1 || die "systemd is required"
for tool in curl tar sha256sum install openssl ss awk; do
    command -v "$tool" >/dev/null 2>&1 || die "$tool is required"
done
case "$(uname -m)" in
    x86_64|amd64) ARCH=amd64 ;;
    aarch64|arm64) ARCH=arm64 ;;
    *) die "architecture $(uname -m) is not covered by this bundle" ;;
esac

install_binary() {
    local archive="$TMP/backhaul_linux_$ARCH.tar.gz"
    log "downloading Backhaul $BACKHAUL_TAG from the mirror"
    mirror_get "$MIRROR_BASE/musixal/backhaul/$BACKHAUL_TAG/backhaul_linux_$ARCH.tar.gz" "$archive"
    tar -xzf "$archive" -C "$TMP" backhaul || die "the archive does not hold the backhaul binary"
    install -m 0755 "$TMP/backhaul" "$BIN"
    log "installed $BIN"
}

need_binary() {
    if [ ! -x "$BIN" ]; then install_binary; fi
}

write_unit() {
    cat >"$UNIT" <<UNIT
[Unit]
Description=Backhaul tunnel (Musixal/Backhaul)
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=$BIN -c $CONF
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
UNIT
    systemctl daemon-reload
}

start_service() {
    systemctl enable backhaul >/dev/null 2>&1 || true
    systemctl restart backhaul
    sleep 3
    if ! systemctl is-active --quiet backhaul; then
        journalctl -u backhaul -n 20 --no-pager >&2 || true
        die "the backhaul service did not start; the log is above"
    fi
    log "the backhaul service is running"
}

make_self_signed() {
    # make_self_signed: a certificate for wss and wssmux when the server has none. Clients must trust it or skip checks.
    local host
    host=$(hostname -I 2>/dev/null | awk '{print $1}')
    openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
        -keyout "$CONF_DIR/server.key" -out "$CONF_DIR/server.crt" -days 3650 -subj "/CN=backhaul" \
        -addext "subjectAltName=IP:${host:-127.0.0.1}" >/dev/null 2>&1 || die "could not make a self-signed certificate"
    chmod 0600 "$CONF_DIR/server.key"
}

configure_server() {
    need_binary
    local BIND_PORT TRANSPORT TOKEN PORTS TLS_CERT TLS_KEY entry toml_ports="" tls_lines=""
    ask BIND_PORT "port the server listens on for the tunnel" "3080"
    valid_port "$BIND_PORT" || die "BIND_PORT must be a port number from 1 to 65535"
    ask TRANSPORT "transport: tcp, tcpmux, ws, wsmux, wss, or wssmux" "tcp"
    valid_transport "$TRANSPORT" || die "TRANSPORT must be one of: $TRANSPORTS"
    ask TOKEN "token the client must send (letters, digits, and . _ - : @ +)" "$(openssl rand -hex 16)"
    [[ "$TOKEN" =~ ^[A-Za-z0-9._@:+-]+$ ]] || die "the token may use only letters, digits, and . _ - : @ +"
    ask PORTS "ports to publish, comma separated (e.g. 443,8443=127.0.0.1:8443; see the README)" ""
    [ -n "$PORTS" ] || die "at least one port entry is required (PORTS)"
    IFS=',' read -r -a entries <<<"$PORTS"
    for entry in "${entries[@]}"; do
        entry="${entry// /}"
        valid_port_entry "$entry" || die "not a port entry: $entry"
        toml_ports+="    \"$entry\","$'\n'
    done
    if [[ "$TRANSPORT" == *wss* ]]; then
        ask TLS_CERT "path to the TLS certificate (PEM); empty makes a self-signed one" ""
        if [ -z "$TLS_CERT" ]; then
            mkdir -p "$CONF_DIR"
            make_self_signed
            TLS_CERT="$CONF_DIR/server.crt"
            TLS_KEY="$CONF_DIR/server.key"
        else
            ask TLS_KEY "path to the TLS private key (PEM)" ""
            [ -r "$TLS_CERT" ] || die "cannot read $TLS_CERT"
            [ -r "$TLS_KEY" ] || die "cannot read $TLS_KEY"
        fi
        tls_lines="tls_cert = \"$TLS_CERT\""$'\n'"tls_key = \"$TLS_KEY\""$'\n'
    fi
    systemctl stop backhaul >/dev/null 2>&1 || true
    port_free "$BIND_PORT"
    mkdir -p "$CONF_DIR"
    cat >"$CONF" <<CONF
[server]
bind_addr = "0.0.0.0:$BIND_PORT"
transport = "$TRANSPORT"
token = "$TOKEN"
log_level = "info"
web_port = 0
${tls_lines}ports = [
$toml_ports]
CONF
    chmod 0600 "$CONF"
    write_unit
    start_service
    log "server config: $CONF (clients need the port $BIND_PORT, the transport $TRANSPORT, and the same token)"
}

configure_client() {
    need_binary
    local REMOTE TRANSPORT TOKEN EDGE_IP="" CONNECTION_POOL
    ask REMOTE "server address and port, e.g. 203.0.113.5:3080" ""
    [[ "$REMOTE" =~ ^[A-Za-z0-9.-]+:[0-9]{1,5}$ ]] || die "REMOTE must look like host:port"
    ask TRANSPORT "transport, the same as the server: tcp, tcpmux, ws, wsmux, wss, or wssmux" "tcp"
    valid_transport "$TRANSPORT" || die "TRANSPORT must be one of: $TRANSPORTS"
    ask TOKEN "token the server set (letters, digits, and . _ - : @ +)" ""
    [[ "$TOKEN" =~ ^[A-Za-z0-9._@:+-]+$ ]] || die "the token may use only letters, digits, and . _ - : @ +"
    if [[ "$TRANSPORT" == ws* || "$TRANSPORT" == wss* ]]; then
        ask EDGE_IP "CDN edge IP for the WebSocket transports; empty skips it" ""
    fi
    ask CONNECTION_POOL "connections kept open to the server" "8"
    valid_port "$CONNECTION_POOL" || die "CONNECTION_POOL must be a number from 1 to 65535"
    need_binary
    systemctl stop backhaul >/dev/null 2>&1 || true
    mkdir -p "$CONF_DIR"
    {
        echo "[client]"
        echo "remote_addr = \"$REMOTE\""
        echo "transport = \"$TRANSPORT\""
        echo "token = \"$TOKEN\""
        [ -z "$EDGE_IP" ] || echo "edge_ip = \"$EDGE_IP\""
        echo "connection_pool = $CONNECTION_POOL"
        echo "retry_interval = 3"
        echo "dial_timeout = 10"
        echo "log_level = \"info\""
        echo "web_port = 0"
    } >"$CONF"
    chmod 0600 "$CONF"
    write_unit
    start_service
    log "client config: $CONF (it connects to $REMOTE over $TRANSPORT)"
}

show_status() {
    if [ ! -f "$UNIT" ]; then echo "Backhaul is not configured yet."; return 0; fi
    systemctl --no-pager status backhaul | head -n 12 || true
}

show_config() {
    [ -f "$CONF" ] || die "no config yet"
    sed -E 's/^(token = ")[^"]*"/\1***"/' "$CONF"
}

uninstall() {
    local confirm REMOVE_CONFIG
    ask confirm "remove Backhaul from this server? yes or no" "no"
    [ "$confirm" = yes ] || { echo "kept Backhaul."; return 0; }
    systemctl disable --now backhaul >/dev/null 2>&1 || true
    rm -f "$UNIT"
    systemctl daemon-reload
    rm -f "$BIN"
    ask REMOVE_CONFIG "also delete $CONF_DIR (the config and any certificate)? yes or no" "no"
    if [ "$REMOVE_CONFIG" = yes ]; then rm -rf "$CONF_DIR"; fi
    log "removed Backhaul"
}

menu() {
    local choice
    while true; do
        echo
        echo "Backhaul $BACKHAUL_TAG (Musixal/Backhaul)"
        echo "  1) install the binary from the mirror"
        echo "  2) configure this server as the tunnel server (listens for the client)"
        echo "  3) configure this server as the tunnel client (connects to the server)"
        echo "  4) status"
        echo "  5) restart the service"
        echo "  6) show the config (token hidden)"
        echo "  7) uninstall"
        echo "  0) exit"
        read -r -p "choose: " choice </dev/tty || die "run this menu on a terminal"
        case "$choice" in
            1) install_binary ;;
            2) configure_server ;;
            3) configure_client ;;
            4) show_status ;;
            5) [ -f "$CONF" ] || die "no config yet"; systemctl restart backhaul && log "restarted" ;;
            6) show_config ;;
            7) uninstall ;;
            0) exit 0 ;;
            *) echo "unknown choice: $choice" ;;
        esac
    done
}

menu
