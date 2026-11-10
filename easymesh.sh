#!/bin/bash
# Added for the offline mirror: files come from the mirror, and each one must match its pinned sha256 value.
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

mirror_get() {
    # mirror_get URL DEST: downloads one bundled file, and fails unless its sha256 is the pinned one.
    local url="$1" dest="$2" key want got
    key="${url#"$MIRROR_BASE"/}"
    want="${MIRROR_SHA256[$key]:-}"
    if [ -z "$want" ]; then echo "error: no pinned sha256 for $key" >&2; return 1; fi
    if ! curl -fsSL --retry 3 -o "$dest" "$url"; then echo "error: could not download $key from the mirror" >&2; return 1; fi
    got=$(sha256sum "$dest" | awk '{print $1}')
    if [ "$got" != "$want" ]; then rm -f "$dest"; echo "error: sha256 mismatch for $key" >&2; return 1; fi
}

install_from_mirror() {
    # install_from_mirror PACKAGE...: installs the packages from the bundled HAProxy profile, which holds them with
    # their dependencies. Nothing is installed when every package is already there.
    local pkg key name dir n release arch missing=0 debs=()
    for pkg in "$@"; do dpkg -s "$pkg" >/dev/null 2>&1 || missing=1; done
    [ "$missing" -eq 1 ] || return 0
    release=$(. /etc/os-release; echo "$VERSION_ID")
    case "$(uname -m)" in
        x86_64|amd64) arch=amd64 ;;
        aarch64|arm64) arch=arm64 ;;
        *) echo "error: no packages for $(uname -m)" >&2; return 1 ;;
    esac
    dir=$(mktemp -d)
    for key in "${!MIRROR_SHA256[@]}"; do
        case "$key" in
            "apt/$release/$arch/haproxy/"*)
                name="${key##*/}"
                mirror_get "$MIRROR_BASE/$key" "$dir/$name" || { rm -rf "$dir"; return 1; }
                debs+=("$dir/$name")
                ;;
        esac
    done
    if [ "${#debs[@]}" -eq 0 ]; then echo "error: this bundle has no packages for Ubuntu $release $arch" >&2; rm -rf "$dir"; return 1; fi
    # dpkg checks dependencies in the order it unpacks, so a package can fail on one pass and succeed on the next.
    for n in 1 2 3; do
        DEBIAN_FRONTEND=noninteractive dpkg -i --force-confold "${debs[@]}" >/dev/null 2>&1 && break
    done
    rm -rf "$dir"
    for pkg in "$@"; do
        dpkg -s "$pkg" >/dev/null 2>&1 || { echo "error: $pkg did not install from the bundle" >&2; return 1; }
    done
}

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   sleep 1
   exit 1
fi


#color codes
GREEN="\033[0;32m"
CYAN="\033[0;36m"
WHITE="\033[1;37m"
RESET="\033[0m"
MAGENTA="\033[0;35m"


# just press key to continue
press_key(){
 read -p "Press Enter to continue..."
}


# Define a function to colorize text
colorize() {
    local color="$1"
    local text="$2"
    local style="${3:-normal}"
    
    # Define ANSI color codes
    local black="\033[30m"
    local red="\033[31m"
    local green="\033[32m"
    local yellow="\033[33m"
    local blue="\033[34m"
    local magenta="\033[35m"
    local cyan="\033[36m"
    local white="\033[37m"
    local reset="\033[0m"
    
    # Define ANSI style codes
    local normal="\033[0m"
    local bold="\033[1m"
    local underline="\033[4m"
    # Select color code
    local color_code
    case $color in
        black) color_code=$black ;;
        red) color_code=$red ;;
        green) color_code=$green ;;
        yellow) color_code=$yellow ;;
        blue) color_code=$blue ;;
        magenta) color_code=$magenta ;;
        cyan) color_code=$cyan ;;
        white) color_code=$white ;;
        *) color_code=$reset ;;  # Default case, no color
    esac
    # Select style code
    local style_code
    case $style in
        bold) style_code=$bold ;;
        underline) style_code=$underline ;;
        normal | *) style_code=$normal ;;  # Default case, normal text
    esac

    # Print the colored and styled text
    echo -e "${style_code}${color_code}${text}${reset}"
}

install_easytier() {
    # Define the directory and files
    DEST_DIR="/root/easytier"
    FILE1="easytier-core"
    FILE2="easytier-cli"
    #URL_X86="https://github.com/EasyTier/EasyTier/releases/download/v1.1.0/easytier-x86_64-unknown-linux-musl-v1.1.0.zip"
    #URL_ARM_SOFT="https://github.com/EasyTier/EasyTier/releases/download/v1.1.0/easytier-armv7-unknown-linux-musleabi-v1.1.0.zip"              
    #URL_ARM_HARD="https://github.com/EasyTier/EasyTier/releases/download/v1.1.0/easytier-armv7-unknown-linux-musleabihf-v1.1.0.zip"

    #New Version
    URL_X86="http://188.213.67.196:8080/files/musixal/easymesh/v1.2.0/easytier-linux-x86_64"
    URL_ARM_SOFT="http://188.213.67.196:8080/files/musixal/easymesh/v1.2.0/easytier-linux-armv7"              
    URL_ARM_HARD="http://188.213.67.196:8080/files/musixal/easymesh/v1.2.0/easytier-linux-armv7hf"
    
    # Check if the directory exists
    if [ -d "$DEST_DIR" ]; then    
        # Check if the files exist
        if [ -f "$DEST_DIR/$FILE1" ] && [ -f "$DEST_DIR/$FILE2" ]; then
            colorize green "EasyMesh Core Installed" bold
            return 0
        fi
    fi
    
    # Detect the system architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        URL=$URL_X86
    elif [ "$ARCH" = "armv7l" ] || [ "$ARCH" = "aarch64" ]; then
        if [ "$(ldd /bin/ls | grep -c 'armhf')" -eq 1 ]; then
            URL=$URL_ARM_HARD
        else
            URL=$URL_ARM_SOFT
        fi
    else
        colorize red "Unsupported architecture: $ARCH\n" bold
        return 1
    fi


    mkdir -p $DEST_DIR &> /dev/null
    colorize yellow "Downloading EasyMesh Core...\n"
    mirror_get "$URL/easytier-cli" "$DEST_DIR/easytier-cli"
    mirror_get "$URL/easytier-core" "$DEST_DIR/easytier-core"


    if [ -f "$DEST_DIR/$FILE1" ] && [ -f "$DEST_DIR/$FILE2" ]; then
    	chmod +x "$DEST_DIR/easytier-cli"
    	chmod +x "$DEST_DIR/easytier-core"
        colorize green "EasyMesh Core Installed Successfully...\n" bold
        sleep 1
        return 0
    else
        colorize red "Failed to install EasyMesh Core...\n" bold
        exit 1
    fi
}



# Call the function
install_easytier

generate_random_secret() {
    openssl rand -hex 6
}

#Var
EASY_CLIENT='/root/easytier/easytier-cli'
SERVICE_FILE="/etc/systemd/system/easymesh.service"
    
connect_network_pool(){
	clear
	colorize cyan "Connect to the Mesh Network" bold 
	echo 
	colorize yellow "Leave the peer addresses blank to enable reverse mode.
Ws and wss modes are not recommended for iran's network environment.
Try disable multi-thread mode if your mesh network is unstable.
UDP mode is more stable rather than tcp mode.
	"
	echo
    read -p "[-] Enter Peer IPv4/IPv6 Addresses (separate multiple addresses by ','): " PEER_ADDRESSES
    
    read -p "[*] Enter Local IPv4 Address (e.g., 10.144.144.1): " IP_ADDRESS
    if [ -z $IP_ADDRESS ]; then
    	colorize red "Null value. aborting..."
    	sleep 2
    	return 1
    fi
    
    read -r -p "[*] Enter Hostname (e.g., Hetnzer): " HOSTNAME
    if [ -z $HOSTNAME ]; then
    	colorize red "Null value. aborting..."
    	sleep 2
    	return 1
    fi
    
    read -p "[-] Enter Tunnel Port (Default 2090): " PORT
    if [ -z $PORT ]; then
    	colorize red "Default port is 2090..."
    	PORT='2090'
    fi
    
	echo ''
    NETWORK_SECRET=$(generate_random_secret)
    colorize cyan "[✓] Generated Network Secret: $NETWORK_SECRET" bold
    while true; do
    read -p "[*] Enter Network Secret (recommend using a strong password): " NETWORK_SECRET
    if [[ -n $NETWORK_SECRET ]]; then
        break
    else
        colorize red "Network secret cannot be empty. Please enter a valid secret.\n"
    fi
	done
	
	

	echo ''
    colorize green "[-] Select Default Protocol:" bold
    echo "1) tcp"
    echo "2) udp"
    echo "3) ws"
    echo "4) wss"
    read -p "[*] Select your desired protocol (e.g., 1 for tcp): " PROTOCOL_CHOICE
	
    case $PROTOCOL_CHOICE in
        1) DEFAULT_PROTOCOL="tcp" ;;
        2) DEFAULT_PROTOCOL="udp" ;;
        3) DEFAULT_PROTOCOL="ws" ;;
        4) DEFAULT_PROTOCOL="wss" ;;
        *) colorize red "Invalid choice. Defaulting to tcp." ; DEFAULT_PROTOCOL="tcp" ;;
    esac
	
	echo 
	read -p "[-] Enable encryption? (yes/no): " ENCRYPTION_CHOICE
	case $ENCRYPTION_CHOICE in
        [Nn]*)
        	ENCRYPTION_OPTION="--disable-encryption"
        	colorize yellow "Encryption is disabled"
       		 ;;
   		*)
       		ENCRYPTION_OPTION=""
       		colorize yellow "Encryption is enabled"
             ;;
	esac
	
	echo
	
	read -p "[-] Enable multi-thread? (yes/no): " MULTI_THREAD
	case $MULTI_THREAD in
        [Nn]*)
        	MULTI_THREAD=""
        	colorize yellow "Multi-thread is disabled"
       		 ;;
   		*)
       		MULTI_THREAD="--multi-thread"
       		colorize yellow "Multi-thread is enabled"
             ;;
	esac
	
	echo
	
	read -p "[-] Enable IPv6? (yes/no): " IPV6_MODE
	case $IPV6_MODE in
        [Nn]*)
        	IPV6_MODE="--disable-ipv6"
        	colorize yellow "IPv6 is disabled"
       		 ;;
   		*)
       		IPV6_MODE=""
       		colorize yellow "IPv6 is enabled"
             ;;
	esac
	
	echo
    
    IFS=',' read -ra ADDR_ARRAY <<< "$PEER_ADDRESSES"
    PROCESSED_ADDRESSES=()
    for ADDRESS in "${ADDR_ARRAY[@]}"; do
        ADDRESS=$(echo $ADDRESS | xargs)
        
        if [[ "$ADDRESS" == *:* ]]; then
            if [[ "$ADDRESS" != \[*\] ]]; then
                ADDRESS="[$ADDRESS]"
            fi
        fi
    
        if [ ! -z "$ADDRESS" ]; then
            PROCESSED_ADDRESSES+=("${DEFAULT_PROTOCOL}://${ADDRESS}:${PORT}")
        fi
    done
    
    JOINED_ADDRESSES=$(IFS=' '; echo "${PROCESSED_ADDRESSES[*]}")
    
    if [ ! -z "$JOINED_ADDRESSES" ]; then
        PEER_ADDRESS="--peers ${JOINED_ADDRESSES}"
    fi
    
    LISTENERS="--listeners ${DEFAULT_PROTOCOL}://[::]:${PORT} ${DEFAULT_PROTOCOL}://0.0.0.0:${PORT}"
    
    SERVICE_FILE="/etc/systemd/system/easymesh.service"
    
cat > $SERVICE_FILE <<EOF
[Unit]
Description=EasyMesh Network Service
After=network.target

[Service]
ExecStart=/root/easytier/easytier-core -i $IP_ADDRESS $PEER_ADDRESS --hostname $HOSTNAME --network-secret $NETWORK_SECRET --default-protocol $DEFAULT_PROTOCOL $LISTENERS $MULTI_THREAD $ENCRYPTION_OPTION $IPV6_MODE
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd, enable and start the service
    sudo systemctl daemon-reload &> /dev/null
    sudo systemctl enable easymesh.service &> /dev/null
    sudo systemctl start easymesh.service &> /dev/null

    colorize green "EasyMesh Network Service Started.\n" bold
	press_key
}


display_peers()
{	
	watch -n1 $EASY_CLIENT peer	
}
display_routes(){

	watch -n1 $EASY_CLIENT route	
}

peer_center(){

	watch -n1 $EASY_CLIENT peer-center	
}

restart_easymesh_service() {
	echo ''
	if [[ ! -f $SERVICE_FILE ]]; then
		colorize red "	EasyMesh service does not exists." bold
		sleep 1
		return 1
	fi
    colorize yellow "	Restarting EasyMesh service...\n" bold
    sudo systemctl restart easymesh.service &> /dev/null
    if [[ $? -eq 0 ]]; then
        colorize green "	EasyMesh service restarted successfully." bold
    else
        colorize red "	Failed to restart EasyMesh service." bold
    fi
    echo ''
	 read -p "	Press Enter to continue..."
}

remove_easymesh_service() {
	echo
	if [[ ! -f $SERVICE_FILE ]]; then
		 colorize red "	EasyMesh service does not exists." bold
		 sleep 1
		 return 1
	fi
    colorize yellow "	Stopping EasyMesh service..." bold
    sudo systemctl stop easymesh.service &> /dev/null
    if [[ $? -eq 0 ]]; then
        colorize green "	EasyMesh service stopped successfully.\n"
    else
        colorize red "	Failed to stop EasyMesh service.\n"
        sleep 2
        return 1
    fi

    colorize yellow "	Disabling EasyMesh service..." bold
    sudo systemctl disable easymesh.service &> /dev/null
    if [[ $? -eq 0 ]]; then
        colorize green "	EasyMesh service disabled successfully.\n"
    else
        colorize red "	Failed to disable EasyMesh service.\n"
        sleep 2
        return 1
    fi

    colorize yellow "	Removing EasyMesh service..." bold
    sudo rm /etc/systemd/system/easymesh.service &> /dev/null
    if [[ $? -eq 0 ]]; then
        colorize green "	EasyMesh service removed successfully.\n"
    else
        colorize red "	Failed to remove EasyMesh service.\n"
        sleep 2
        return 1
    fi

    colorize yellow "	Reloading systemd daemon..." bold
    sudo systemctl daemon-reload
    if [[ $? -eq 0 ]]; then
        colorize green "	Systemd daemon reloaded successfully.\n"
    else
        colorize red "	Failed to reload systemd daemon.\n"
        sleep 2
        return 1
    fi
    
 read -p "	Press Enter to continue..."
}

show_network_secret() {
	echo ''
    if [[ -f $SERVICE_FILE ]]; then
        NETWORK_SECRET=$(grep -oP '(?<=--network-secret )[^ ]+' $SERVICE_FILE)
        
        if [[ -n $NETWORK_SECRET ]]; then
            colorize cyan "	Network Secret Key: $NETWORK_SECRET" bold
        else
            colorize red "	Network Secret key not found" bold
        fi
    else
        colorize red "	EasyMesh service does not exists." bold
    fi
    echo ''
    read -p "	Press Enter to continue..."
   
    
}

view_service_status() {
	if [[ ! -f $SERVICE_FILE ]]; then
		 colorize red "	EasyMesh service does not exists." bold
		 sleep 1
		 return 1
	fi
	clear
    sudo systemctl status easymesh.service
}

set_watchdog(){
	clear
	view_watchdog_status
	echo "---------------------------------------------"
	echo 
	colorize cyan "Select your option:" bold
	colorize green "1) Create watchdog service"
	colorize red "2) Stop & remove watchdog service"
    colorize yellow "3) View Logs"
    colorize reset "4) Back"
    echo ''
    read -p "Enter your choice: " CHOICE
    case $CHOICE in 
    	1) start_watchdog ;;
    	2) stop_watchdog ;;
    	3) view_logs ;;
    	4) return 0;;
    	*) colorize red "Invalid option!" bold && sleep 1 && return 1;;
    esac

}

start_watchdog(){
	clear
	colorize cyan "Important: You can check the status of the service \nand restart it if the latency is higher than a certain limit. \nI recommend to run it only on one server and preferably outside (Kharej) server" bold
	echo ''
	
	read -p "Enter the local IP address to monitor: " IP_ADDRESS
	read -p "Enter the latency threshold in ms (200): " LATENCY_THRESHOLD
	read -p "Enter the time between checks in seconds (8): " CHECK_INTERVAL
	
	
	stop_watchdog
	touch /etc/monitor.sh /etc/monitor.log &> /dev/null
	
cat << EOF | sudo tee /etc/monitor.sh > /dev/null
#!/bin/bash

# Configuration
IP_ADDRESS="$IP_ADDRESS"
LATENCY_THRESHOLD=$LATENCY_THRESHOLD
CHECK_INTERVAL=$CHECK_INTERVAL
SERVICE_NAME="easymesh.service"
LOG_FILE="/etc/monitor.log"

# Function to restart the service
restart_service() {
    local restart_time=\$(date +"%Y-%m-%d %H:%M:%S")
    sudo systemctl restart "\$SERVICE_NAME"
    if [ \$? -eq 0 ]; then
        echo "\$restart_time: Service \$SERVICE_NAME restarted successfully." >> "\$LOG_FILE"
    else
        echo "\$restart_time: Failed to restart service \$SERVICE_NAME." >> "\$LOG_FILE"
    fi
}

# Function to calculate average latency
calculate_average_latency() {
    local latencies=(\$(ping -c 3 -W 2 -i 0.2 "\$IP_ADDRESS" | grep 'time=' | sed -n 's/.*time=\([0-9.]*\) ms.*/\1/p'))
    local total_latency=0
    local count=\${#latencies[@]}

    for latency in "\${latencies[@]}"; do
        total_latency=\$(echo "\$total_latency + \$latency" | bc)
    done

    if [ \$count -gt 0 ]; then
        local average_latency=\$(echo "scale=2; \$total_latency / \$count" | bc)
        echo \$average_latency
    else
        echo 0
    fi
}

# Main monitoring loop
while true; do
    # Calculate average latency
    AVG_LATENCY=\$(calculate_average_latency)
    
    if [ "\$AVG_LATENCY" == "0" ]; then
        echo "\$(date +"%Y-%m-%d %H:%M:%S"): Failed to ping \$IP_ADDRESS. Restarting service..." >> "\$LOG_FILE"
        restart_service
    else
        LATENCY_INT=\${AVG_LATENCY%.*}  # Convert latency to integer for comparison
        if [ "\$LATENCY_INT" -gt "\$LATENCY_THRESHOLD" ]; then
            echo "\$(date +"%Y-%m-%d %H:%M:%S"): Average latency \$AVG_LATENCY ms exceeds threshold of \$LATENCY_THRESHOLD ms. Restarting service..." >> "\$LOG_FILE"
            restart_service
        fi
    fi

    # Wait for the specified interval before checking again
    sleep "\$CHECK_INTERVAL"
done
EOF


	echo
	colorize yellow "Creating a service for watchdog" bold
	echo
    
SERVICE_FILE="/etc/systemd/system/easymesh-watchdog.service"    
cat > $SERVICE_FILE <<EOF
[Unit]
Description=EasyMesh Watchdog Service
After=network.target

[Service]
ExecStart=/bin/bash /etc/monitor.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

	# Execute the script in the background
    systemctl daemon-reload >/dev/null 2>&1
	systemctl enable --now easymesh-watchdog.service
	
    echo
    colorize green "Watchdog service started successfully" bold
    echo
press_key
}

# Function to stop the watchdog
stop_watchdog() {
	echo 
	SERVICE_FILE="/etc/systemd/system/easymesh-watchdog.service" 
	
	if [[ ! -f $SERVICE_FILE ]]; then
		 colorize red "Watchdog service does not exists." bold
		 sleep 1
		 return 1
	fi
	
    systemctl disable --now easymesh-watchdog.service &> /dev/null
    rm -f /etc/monitor.sh /etc/monitor.log &> /dev/null 
    rm -f "$SERVICE_FILE"  &> /dev/null 
    systemctl daemon-reload &> /dev/null
    colorize yellow "Watchdog service stopped and removed successfully" bold
    echo
    sleep 2
}

view_watchdog_status(){
	if systemctl is-active --quiet "easymesh-watchdog.service"; then
				colorize green "	Watchdog service is running" bold
			else
				colorize red "	Watchdog service is not running" bold
	fi		

}
# Function to view logs
view_logs() {
    if [ -f /etc/monitor.log ]; then
        less +G /etc/monitor.log
    else
    	echo ''
        colorize yellow "No logs found.\n" bold
        press_key
    fi
    
}


# Function to add cron-tab job
add_cron_job() {
	echo 

	local service_name="easymesh.service"
	
    # Prompt user to choose a restart time interval
    colorize cyan "Select the restart time interval:" bold
    echo
    echo "1. Every 30th minute"
    echo "2. Every 1 hour"
    echo "3. Every 2 hours"
    echo "4. Every 4 hours"
    echo "5. Every 6 hours"
    echo "6. Every 12 hours"
    echo "7. Every 24 hours"
    echo
    read -p "Enter your choice: " time_choice
    # Validate user input for restart time interval
    case $time_choice in
        1)
            restart_time="*/30 * * * *"
            ;;
        2)
            restart_time="0 * * * *"
            ;;
        3)
            restart_time="0 */2 * * *"
            ;;
        4)
            restart_time="0 */4 * * *"
            ;;
        5)
            restart_time="0 */6 * * *"
            ;;
        6)
            restart_time="0 */12 * * *"
            ;;
        7)
            restart_time="0 0 * * *"
            ;;
        *)
            echo -e "${RED}Invalid choice. Please enter a number between 1 and 7.${NC}\n"
            sleep 2
            return 1
            ;;
    esac


    # remove cronjob created by this script
    delete_cron_job > /dev/null 2>&1
    
    # Path to reset file
    local reset_path="/root/easytier/reset.sh"
    
    #add cron job to kill the running easymesh processes
    cat << EOF > "$reset_path"
#! /bin/bash
pids=\$(pgrep easytier)
sudo kill -9 \$pids
sudo systemctl daemon-reload
sudo systemctl restart $service_name
EOF

    # make it +x
    chmod +x "$reset_path"
    
    # Save existing crontab to a temporary file
    crontab -l > /tmp/crontab.tmp

    # Append the new cron job to the temporary file
    echo "$restart_time $reset_path #$service_name" >> /tmp/crontab.tmp

    # Install the modified crontab from the temporary file
    crontab /tmp/crontab.tmp

    # Remove the temporary file
    rm /tmp/crontab.tmp
    
    echo
    colorize green "Cron-job added successfully to restart the service '$service_name'." bold
    sleep 2
}

delete_cron_job() {
    echo
    local service_name="easymesh.service"
    local reset_path="/root/easytier/reset.sh"
    
    crontab -l | grep -v "#$service_name" | crontab -
    rm -f "$reset_path" >/dev/null 2>&1
    
    colorize green "Cron job for $service_name deleted successfully." bold
    
    sleep 2
}

set_cronjob(){
   	clear
   	colorize cyan "Cron-job setting menu" bold
   	echo 
   	
   	colorize green "1) Add a new cronjob"
   	colorize red "2) Delete existing cronjob"
   	colorize reset "3) Return..."
   	
   	echo
   	echo -ne "Select you option [1-3]: "
   	read -r choice
   	
   	case $choice in 
   		1) add_cron_job ;;
   		2) delete_cron_job ;;
   		3) return 0 ;;
   		*) colorize red "Invalid option!" && sleep 1 && return 1 ;;
   	esac
   	
}

check_core_status(){
    DEST_DIR="/root/easytier"
    FILE1="easytier-core"
    FILE2="easytier-cli"
    
        if [ -f "$DEST_DIR/$FILE1" ] && [ -f "$DEST_DIR/$FILE2" ]; then
        colorize green "EasyMesh Core Installed" bold
        return 0
    else
        colorize red "EasyMesh Core not found" bold
        return 1
    fi
}

# New function to remove core
remove_easymesh_core(){
	echo
	
	if [[ ! -d '/root/easytier' ]]; then
		 colorize red "	EasyMesh directory not found." bold
		 sleep 2
		 return 1
	fi
	
	
	rm -rf /root/easytier &> /dev/null
	
	colorize green "	Easymesh core deleted successfully." bold
	sleep 2

}
# Function to display menu
display_menu() {
    clear
# Print the header with colors
echo -e "   ${CYAN}╔════════════════════════════════════════╗"
echo -e "   ║            🌐 ${WHITE}EasyMesh                 ${CYAN}║"
echo -e "   ║        ${WHITE}VPN Network Solution            ${CYAN}║"
echo -e "   ╠════════════════════════════════════════╣"
echo -e "   ║  ${WHITE}Version: 0.97 beta                    ${CYAN}║"
echo -e "   ║  ${WHITE}Telegram Channel: @Gozar_Xray         ${CYAN}║"
echo -e "   ║  ${WHITE}GitHub: github.com/Musixal/easy-mesh  ${CYAN}║"
echo -e "   ╠════════════════════════════════════════╣${RESET}"
echo -e "   ║        $(check_core_status)         ║"
echo -e "   ╚════════════════════════════════════════╝"

    echo ''
    colorize green "	[1] Connect to the Mesh Network" bold 
    colorize yellow "	[2] Display Peers" 
    colorize cyan "	[3] Display Routes" 
    colorize reset "	[4] Peer-Center"
    colorize reset "	[5] Display Secret Key"
    colorize reset "	[6] View Service Status"  
    colorize reset "	[7] Set Watchdog [Auto-Restarter]"
    colorize reset "	[8] Cron-jon setting"   
    colorize yellow "	[9] Restart Service" 
    colorize red "	[10] Remove Service" 
    colorize magenta "	[11] Remove Core" 
    
    echo -e "	[0] Exit" 
    echo ''
}


# Function to read user input
read_option() {
	echo -e "\t-------------------------------"
    echo -en "\t${MAGENTA}\033[1mEnter your choice:${RESET} "
    read -p '' choice 
    case $choice in
        1) connect_network_pool ;;
        2) display_peers ;;
        3) display_routes ;;
        4) peer_center ;;
        5) show_network_secret ;;
        6) view_service_status ;;
        7) set_watchdog ;;
        8) set_cronjob ;;
        9) restart_easymesh_service ;;
        10) remove_easymesh_service ;;
        11) remove_easymesh_core ;;
        0) exit 0 ;;
        *) colorize red "	Invalid option!" bold && sleep 1 ;;
    esac
}

# Main script
while true
do
    display_menu
    read_option
done
