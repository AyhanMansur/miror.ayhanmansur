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

# just press key to continue
press_key(){
 read -p "Press any key to continue..."
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

# Function to install unzip if not already installed
install_unzip() {
    if ! command -v unzip &> /dev/null; then
        # Check if the system is using apt package manager
        if command -v apt-get &> /dev/null; then
            echo -e "${RED}unzip is not installed. Installing...${NC}"
            sleep 1
            true
            install_from_mirror unzip
        else
            echo -e "${RED}Error: Unsupported package manager. Please install unzip manually.${NC}\n"
            press_key
            exit 1
        fi
    fi
}
# Install unzip
install_unzip

#Function to install cron if not already installed
install_cron() {
    if ! command -v cron &> /dev/null; then
        # Check if the system is using apt package manager
        if command -v apt-get &> /dev/null; then
            echo -e "${RED}cron is not installed. Installing...${NC}"
            sleep 1
            true
            sudo apt-get install -y cron
        else
            echo -e "${RED}Error: Unsupported package manager. Please install cron manually.${NC}\n"
            press_key
            exit 1
        fi
    fi
}

# Install cron
install_cron

# Function to install jq if not already installed
install_jq() {
    if ! command -v jq &> /dev/null; then
        # Check if the system is using apt package manager
        if command -v apt-get &> /dev/null; then
            echo -e "${RED}jq is not installed. Installing...${NC}"
            sleep 1
            true
            install_from_mirror jq
        else
            echo -e "${RED}Error: Unsupported package manager. Please install jq manually.${NC}\n"
            press_key
            exit 1
        fi
    fi
}

# Install jq
install_jq

config_dir="/root/rathole-core"
# Function to download and extract Rathole Core
download_and_extract_rathole() {
    # check if core installed already
    if [[ -f "${config_dir}/rathole" ]]; then
        if [[ "$1" == "sleep" ]]; then
        	echo 
            colorize green "Rathole Core is already installed." bold
        	sleep 1
       	fi 
        return 1
    fi

    # Define the entry to check/add
     ENTRY="185.199.108.133 raw.githubusercontent.com"
    # Check if the github entry exists in /etc/hosts
    if ! grep -q "$ENTRY" /etc/hosts; then
	echo "Github Entry not found. Adding to /etc/hosts..."
        echo "$ENTRY" >> /etc/hosts
    else
    echo "Github entry already exists in /etc/hosts."
    fi

    # Check operating system
    if [[ $(uname) == "Linux" ]]; then
        ARCH=$(uname -m)
        DOWNLOAD_URL=""
    else
        echo -e "${RED}Unsupported operating system.${NC}"
        sleep 1
        exit 1
    fi
    if [[ "$ARCH" == "x86_64" ]]; then
    	DOWNLOAD_URL='http://188.213.67.196:8080/files/musixal/rathole/rathole.zip'
    fi

    if [ -z "$DOWNLOAD_URL" ]; then
        echo -e "${RED}Failed to retrieve download URL.${NC}"
        sleep 1
        exit 1
    fi

    DOWNLOAD_DIR=$(mktemp -d)
    echo -e "Downloading Rathole from $DOWNLOAD_URL...\n"
    sleep 1
    mirror_get "$DOWNLOAD_URL" "$DOWNLOAD_DIR/rathole.zip"
    echo -e "Extracting Rathole...\n"
    sleep 1
    unzip -q "$DOWNLOAD_DIR/rathole.zip" -d "$config_dir"
    echo -e "${GREEN}Rathole installation completed.${NC}\n"
    chmod u+x ${config_dir}/rathole
    rm -rf "$DOWNLOAD_DIR"
}

#Download and extract the Rathole core
download_and_extract_rathole

# Get server IP
#SERVER_IP=$(hostname -I | awk '{print $1}')

# Fetch server country
SERVER_COUNTRY=$(curl --max-time 3 -sS "http://ipwhois.app/json/$SERVER_IP" | jq -r '.country')

# Fetch server isp 
SERVER_ISP=$(curl --max-time 3 -sS "http://ipwhois.app/json/$SERVER_IP" | jq -r '.isp')

# Function to display ASCII logo
# Function to display ASCII logo
display_logo() {   
    echo -e "${CYAN}"
    cat << "EOF"
               __  .__           .__          
____________ _/  |_|  |__   ____ |  |   ____  
\_  __ \__  \\   __|  |  \ /  _ \|  | _/ __ \ 
 |  | \// __ \|  | |   Y  (  <_> |  |_\  ___/ 
 |__|  (____  |__| |___|  /\____/|____/\___  >
            \/          \/                 \/ 	
EOF
    echo -e "${NC}${GREEN}"
    echo -e "Version: ${YELLOW}v2.0${GREEN}"
    echo -e "Github: ${YELLOW}github.com/Musixal/Rathole-Tunnel${GREEN}"
    echo -e "Telegram Channel: ${YELLOW}@Gozar_Xray${NC}"
}

# Function to display server location and IP
display_server_info() {
    echo -e "\e[93m═════════════════════════════════════════════\e[0m"  
 	#	Hidden for security issues   
    #echo -e "${CYAN}IP Address:${NC} $SERVER_IP"
    echo -e "${CYAN}Location:${NC} $SERVER_COUNTRY "
    echo -e "${CYAN}Datacenter:${NC} $SERVER_ISP"
}

# Function to display Rathole Core installation status
display_rathole_core_status() {
    if [[ -f "${config_dir}/rathole" ]]; then
        echo -e "${CYAN}Rathole Core:${NC} ${GREEN}Installed${NC}"
    else
        echo -e "${CYAN}Rathole Core:${NC} ${RED}Not installed${NC}"
    fi
    echo -e "\e[93m═════════════════════════════════════════════\e[0m"  
}

# Function to check if a given string is a valid IPv6 address
check_ipv6() {
    local ip=$1
    # Define the IPv6 regex pattern
    ipv6_pattern="^([0-9a-fA-F]{1,4}:){7}([0-9a-fA-F]{1,4}|:)$|^(([0-9a-fA-F]{1,4}:){1,7}|:):((:[0-9a-fA-F]{1,4}){1,7}|:)$"
    # Remove brackets if present
    ip="${ip#[}"
    ip="${ip%]}"

    if [[ $ip =~ $ipv6_pattern ]]; then
        return 0  # Valid IPv6 address
    else
        return 1  # Invalid IPv6 address
    fi
}

check_port() {
    local PORT=$1
	local TRANSPORT=$2
	
    if [ -z "$PORT" ]; then
        echo "Usage: check_port <port> <transport>"
        return 1
    fi
    
	if [[ "$TRANSPORT" == "tcp" ]]; then
		if ss -tlnp "sport = :$PORT" | grep "$PORT" > /dev/null; then
			return 0
		else
			return 1
		fi
	elif [[ "$TRANSPORT" == "udp" ]]; then
		if ss -ulnp "sport = :$PORT" | grep "$PORT" > /dev/null; then
			return 0
		else
			return 1
		fi
	else
		return 1
   	fi
   	
}

# Function for configuring tunnel
configure_tunnel() {

# check if the rathole-core installed or not
if [[ ! -d "$config_dir" ]]; then
    echo -e "\n${RED}Rathole-core directory not found. Install it first through 'Install Rathole core' option.${NC}\n"
    read -p "Press Enter to continue..."
    return 1
fi

    clear
    colorize green "Essential tips:" bold
    colorize yellow "   Enable TCP_NODELAY to improve the latency but decrease the bandwidth.
   For the high number of connections, I recommend turning off the Heartbeat option" 
    echo
    colorize green "1) Configure for IRAN server" bold
    colorize magenta "2) Configure for KHAREJ server" bold
    echo
    read -p "Enter your choice: " configure_choice
    case "$configure_choice" in
        1) iran_server_configuration ;;
        2) kharej_server_configuration ;;
        *) echo -e "${RED}Invalid option!${NC}" && sleep 1 ;;
    esac
    echo
    read -p "Press Enter to continue..."
}


#Global Variables
service_dir="/etc/systemd/system"
  
# Function to configure Iran server
iran_server_configuration() {  
    clear
    colorize cyan "Configuring IRAN server" bold
    
    echo
    
    #Add IPv6 Support
	local_ip='0.0.0.0'
	read -p "[-] Listen for IPv6 address? (y/n): " answer
	if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
	    colorize yellow "IPv6 Enabled"
	    local_ip='[::]'
	elif [ "$answer" = "n" ]; then
	    colorize yellow "IPv4 Enabled"
	    local_ip='0.0.0.0'
	else
	    colorize yellow "Invalid choice. IPv4 enabled by default."
	    local_ip='0.0.0.0'
	fi

	echo 
	
	while true; do
	    echo -ne "[*] Tunnel port: "
	    read -r tunnel_port
	
	    if [[ "$tunnel_port" =~ ^[0-9]+$ ]] && [ "$tunnel_port" -gt 22 ] && [ "$tunnel_port" -le 65535 ]; then
	        if check_port "$tunnel_port" "tcp"; then
	            colorize red "Port $tunnel_port is in use."
	        else
	            break
	        fi
	    else
	        colorize red "Please enter a valid port number between 23 and 65535"
	    fi
	done
	
	echo
	
	# Initialize nodelay variable
	local nodelay=""
	# Keep prompting the user until a valid input is provided
	while [[ "$nodelay" != "true" && "$nodelay" != "false" ]]; do
	    echo -ne "[*] Enable TCP_NODELAY (true/false): " 
	    read -r nodelay
	    if [[ "$nodelay" != "true" && "$nodelay" != "false" ]]; then
	        colorize red "Invalid TCP_NODELAY value. Please enter 'true' or 'false'"
	    fi
	done
    
    echo
    
    # Initialize HEARTBEAT variable
	local HEARTBEAT=""
	# Keep prompting the user until a valid input is provided
	while [[ "$HEARTBEAT" != "true" && "$HEARTBEAT" != "false" ]]; do
	    echo -ne "[*] Enable HEARTBEAT (true/false): " 
	    read -r HEARTBEAT
	    if [[ "$HEARTBEAT" != "true" && "$HEARTBEAT" != "false" ]]; then
	        colorize red "Invalid HEARTBEAT value. Please enter 'true' or 'false'"
	    fi
	done
    
    if [[ "$HEARTBEAT" == "true" ]]; then
    	HEARTBEAT="30"
    else
    	HEARTBEAT="0"
    fi
    echo
    
    # Initialize transport variable
	local transport=""
	# Keep prompting the user until a valid input is provided
	while [[ "$transport" != "tcp" && "$transport" != "udp" ]]; do
	    # Prompt the user to input transport type
	    echo -ne "[*] Transport type(tcp/udp): " 
	    read -r transport
	
	    # Check if the input is either tcp or udp
	    if [[ "$transport" != "tcp" && "$transport" != "udp" ]]; then
	        colorize red "Invalid transport type. Please enter 'tcp' or 'udp'"
	    fi
	done
	
	echo 

	echo -ne "[-] Security Token (press enter to use default value): "
	read -r token
	if [[ -z "$token" ]]; then
		token="musixal"
	fi

	echo 
	
	# Prompt for Ports
	echo -ne "[*] Enter your ports separated by commas (e.g. 2070,2080): "
	read -r input_ports
	input_ports=$(echo "$input_ports" | tr -d ' ')
	# Convert the input into an array, splitting by comma
	IFS=',' read -r -a ports <<< "$input_ports"
	declare -a config_ports
	# Iterate through each port and perform an action
	for port in "${ports[@]}"; do
		if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -gt 22 ] && [ "$port" -le 65535 ]; then
			if check_port "$port" "$transport"; then
			    colorize red "[ERROR] Port $port is in use."
			else
				colorize green "[INFO] Port $port added to your configs"
			    config_ports+=("$port")
			fi
		else
			colorize red "[ERROR] Port $port is Invalid. Please enter a valid port number between 23 and 65535"
		fi
	  
	done

	if [ ${#config_ports[@]} -eq 0 ]; then
		colorize red "No ports were entered. Exiting." bold
		sleep 2
		return 1
	fi
	
	
    # Generate server configuration file
    cat << EOF > "${config_dir}/iran${tunnel_port}.toml"
[server]
bind_addr = "${local_ip}:${tunnel_port}"
default_token = "$token"
heartbeat_interval = $HEARTBEAT

[server.transport]
type = "tcp"

[server.transport.tcp]
nodelay = $nodelay

EOF

    # Add each config port to the configuration file
    for port in "${config_ports[@]}"; do
        cat << EOF >> "${config_dir}/iran${tunnel_port}.toml"
[server.services.${port}]
type = "$transport"
bind_addr = "${local_ip}:${port}"

EOF
    done

    echo 

    # Create the systemd service unit file
    cat << EOF > "${service_dir}/rathole-iran${tunnel_port}.service"
[Unit]
Description=Rathole Iran Port $tunnel_port (Iran)
After=network.target

[Service]
Type=simple
ExecStart=${config_dir}/rathole ${config_dir}/iran${tunnel_port}.toml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd to read the new unit file
    systemctl daemon-reload >/dev/null 2>&1

    # Enable and start the service to start on boot
    if systemctl enable --now "${service_dir}/rathole-iran${tunnel_port}.service" >/dev/null 2>&1; then
        colorize green "Iran service with port $tunnel_port enabled to start on boot and started."
    else
        colorize red "Failed to enable service with port $tunnel_port. Please check your system configuration."
        return 1
    fi
     
    echo
    colorize green "IRAN server configuration completed successfully."
}

#Function for configuring Kharej server
kharej_server_configuration() {
    clear
    colorize cyan "Configuring kharej server" bold 
    
    echo
 
	# Prompt for IRAN server IP address
	while true; do
	    echo -ne "[*] IRAN server IP address [IPv4/IPv6]: " 
	    read -r SERVER_ADDR
	    if [[ -n "$SERVER_ADDR" ]]; then
	        break
	    else
	        colorize red "Server address cannot be empty. Please enter a valid address."
	        echo
	    fi
	done
	
    echo
    
    # Read the tunnel port
 	while true; do
	    echo -ne "[*] Tunnel port: "
	    read -r tunnel_port
	
	    if [[ "$tunnel_port" =~ ^[0-9]+$ ]] && [ "$tunnel_port" -gt 22 ] && [ "$tunnel_port" -le 65535 ]; then
	       	break
	    else
	        colorize red "Please enter a valid port number between 23 and 65535"
	    fi
	done
    
    echo
    
	# Initialize nodelay variable
	local nodelay=""
	# Keep prompting the user until a valid input is provided
	while [[ "$nodelay" != "true" && "$nodelay" != "false" ]]; do
	    echo -ne "[*] TCP_NODELAY (true/false): " 
	    read -r nodelay
	    if [[ "$nodelay" != "true" && "$nodelay" != "false" ]]; then
	        colorize red "Invalid nodelay input. Please enter 'true' or 'false'"
	    fi
	done

	echo
	
	# Initialize HEARTBEAT variable
	local HEARTBEAT=""
	# Keep prompting the user until a valid input is provided
	while [[ "$HEARTBEAT" != "true" && "$HEARTBEAT" != "false" ]]; do
	    echo -ne "[*] Enable HEARTBEAT (true/false): " 
	    read -r HEARTBEAT
	    if [[ "$HEARTBEAT" != "true" && "$HEARTBEAT" != "false" ]]; then
	        colorize red "Invalid HEARTBEAT value. Please enter 'true' or 'false'"
	    fi
	done
    
    if [[ "$HEARTBEAT" == "true" ]]; then
    	HEARTBEAT="40"
    else
    	HEARTBEAT="0"
    fi
    
    echo

    # Initialize transport variable
    local transport=""

	# Keep prompting the user until a valid input is provided
	while [[ "$transport" != "tcp" && "$transport" != "udp" ]]; do
	    # Prompt the user to input transport type
	    echo -ne "[*] Transport type (tcp/udp): " 
	    read -r transport
	
	    # Check if the input is either tcp or udp
	    if [[ "$transport" != "tcp" && "$transport" != "udp" ]]; then
	        colorize red "Invalid transport type. Please enter 'tcp' or 'udp'"
	    fi
	done

	echo

	echo -ne "[-] Security Token (press enter to use default value): "
	read -r token
	if [[ -z "$token" ]]; then
		token="musixal"
	fi

	echo
	
		
	# Prompt for Ports
	echo -ne "[*] Enter your ports separated by commas (e.g. 2070,2080): "
	read -r input_ports
	input_ports=$(echo "$input_ports" | tr -d ' ')
	declare -a config_ports
	# Convert the input into an array, splitting by comma
	IFS=',' read -r -a ports <<< "$input_ports"
	# Iterate through each port and perform an action
	for port in "${ports[@]}"; do
		if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -gt 22 ] && [ "$port" -le 65535 ]; then
			if ! check_port "$port" "$transport" ; then
			    colorize yellow "[INFO] Port $port is not in LISTENING state."
			fi
			colorize green "[INFO] Port $port added to your configs"
		    config_ports+=("$port")
		else
			colorize red "[ERROR] Port $port is Invalid. Please enter a valid port number between 23 and 65535"
		fi
	  
	done
	

	if [ ${#config_ports[@]} -eq 0 ]; then
		colorize red "No ports were entered. Exiting." bold
		sleep 2
		return 1
	fi
	
	
	#Add IPv6 Support
	local_ip='0.0.0.0'
	if check_ipv6 "$SERVER_ADDR"; then
	    local_ip='[::]'
	    # Remove brackets if present
	    SERVER_ADDR="${SERVER_ADDR#[}"
	    SERVER_ADDR="${SERVER_ADDR%]}"
	fi

    # Generate server configuration file
    cat << EOF > "${config_dir}/kharej${tunnel_port}.toml"
[client]
remote_addr = "${SERVER_ADDR}:${tunnel_port}"
default_token = "$token"
heartbeat_timeout = $HEARTBEAT
retry_interval = 1

[client.transport]
type = "tcp"

[client.transport.tcp]
nodelay = $nodelay

EOF

    # Add each config port to the configuration file
    for port in "${config_ports[@]}"; do
        cat << EOF >> "${config_dir}/kharej${tunnel_port}.toml"
[client.services.${port}]
type = "$transport"
local_addr = "${local_ip}:${port}"

EOF
    done
    
    echo

    # Create the systemd service unit file
    cat << EOF > "${service_dir}/rathole-kharej${tunnel_port}.service"
[Unit]
Description=Rathole Kharej Port $tunnel_port 
After=network.target

[Service]
Type=simple
ExecStart=${config_dir}/rathole ${config_dir}/kharej${tunnel_port}.toml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd to read the new unit file
    systemctl daemon-reload >/dev/null 2>&1

    # Enable and start the service to start on boot
    if systemctl enable --now "${service_dir}/rathole-kharej${tunnel_port}.service" >/dev/null 2>&1; then
        colorize green "Kharej service with port $tunnel_port enabled to start on boot and started."
    else
        colorize red "Failed to enable service with port $tunnel_port. Please check your system configuration."
        return 1
    fi

    echo
    colorize green "Kharej server configuration completed successfully."
}


# Function for checking tunnel status
check_tunnel_status() {
    echo
    
	# Check for .toml files
	if ! ls "$config_dir"/*.toml 1> /dev/null 2>&1; then
	    colorize red "No config files found in the rathole directory." bold
	    echo 
	    press_key
	    return 1
	fi

	clear
    colorize yellow "Checking all services status..." bold
    sleep 1
    echo
    for config_path in "$config_dir"/iran*.toml; do
        if [ -f "$config_path" ]; then
            # Extract config_name without directory path and change it to service name
			config_name=$(basename "$config_path")
			config_name="${config_name%.toml}"
			service_name="rathole-${config_name}.service"
            config_port="${config_name#iran}"
            
			# Check if the rathole-client-kharej service is active
			if systemctl is-active --quiet "$service_name"; then
				colorize green "Iran service with tunnel port $config_port is running"
			else
				colorize red "Iran service with tunnel port $config_port is not running"
			fi
   		fi
    done
    
    for config_path in "$config_dir"/kharej*.toml; do
        if [ -f "$config_path" ]; then
            # Extract config_name without directory path and change it to service name
			config_name=$(basename "$config_path")
			config_name="${config_name%.toml}"
			service_name="rathole-${config_name}.service"
            config_port="${config_name#kharej}"
            
			# Check if the rathole-client-kharej service is active
			if systemctl is-active --quiet "$service_name"; then
				colorize green "Kharej service with tunnel port $config_port is running"
			else
				colorize red "Kharej service with tunnel port $config_port is not running"
			fi
   		fi
    done
    
    
    echo
    press_key
}


# Function for destroying tunnel
tunnel_management() {
	echo
	# Check for .toml files
	if ! ls "$config_dir"/*.toml 1> /dev/null 2>&1; then
	    colorize red "No config files found in the rathole directory." bold
	    echo 
	    press_key
	    return 1
	fi
	
	clear
	colorize cyan "List of existing services to manage:" bold
	echo 
	
	#Variables
    local index=1
    declare -a configs

    for config_path in "$config_dir"/iran*.toml; do
        if [ -f "$config_path" ]; then
            # Extract config_name without directory path
            config_name=$(basename "$config_path")
            
            # Remove "iran" prefix and ".toml" suffix
            config_port="${config_name#iran}"
            config_port="${config_port%.toml}"
            
            configs+=("$config_path")
            echo -e "${MAGENTA}${index}${NC}) ${GREEN}Iran${NC} service, Tunnel port: ${YELLOW}$config_port${NC}"
            ((index++))
        fi
    done
    

    
    for config_path in "$config_dir"/kharej*.toml; do
        if [ -f "$config_path" ]; then
            # Extract config_name without directory path
            config_name=$(basename "$config_path")
            
            # Remove "kharej" prefix and ".toml" suffix
            config_port="${config_name#kharej}"
            config_port="${config_port%.toml}"
            
            configs+=("$config_path")
            echo -e "${MAGENTA}${index}${NC}) ${GREEN}Kharej${NC} service, Tunnel port: ${YELLOW}$config_port${NC}"
            ((index++))
        fi
    done
    
    echo
	echo -ne "Enter your choice (0 to return): "
    read choice 
	
	# Check if the user chose to return
	if (( choice == 0 )); then
	    return
	fi
	#  validation
	while ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 0 || choice > ${#configs[@]} )); do
	    colorize red "Invalid choice. Please enter a number between 1 and ${#configs[@]}." bold
	    echo
	    echo -ne "Enter your choice (0 to return): "
	    read choice
		if (( choice == 0 )); then
			return
		fi
	done
	
	selected_config="${configs[$((choice - 1))]}"
	config_name=$(basename "${selected_config%.toml}")
	service_name="rathole-${config_name}.service"
	  
	clear
	colorize cyan "List of available commands for $config_name:" bold
	echo 
	colorize red "1) Remove this tunnel"
	colorize yellow "2) Restart this tunnel"
	colorize green "3) Add a new config for this tunnel"
	colorize reset "4) Add a cronjob for this tunnel"
	colorize reset "5) Remove existing cronjob for this tunnel"
	colorize reset "6) View service logs"
    colorize reset "7) View service status"
	echo 
	read -p "Enter your choice (0 to return): " choice
	
    case $choice in
        1) destroy_tunnel "$selected_config" ;;
        2) restart_service "$service_name" ;;
        3) add_new_config "$selected_config" ;;
        4) add_cron_job_menu "$service_name";;
        5) delete_cron_job "$service_name";;
        6) view_service_logs "$service_name" ;;
        7) view_service_status "$service_name" ;;
        0) return 1 ;;
        *) echo -e "${RED}Invalid option!${NC}" && sleep 1 && return 1;;
    esac
	
}

remove_core(){
	echo
	# If user try to remove core and still a service is running, we should prohibit this.	
	# Check if any .toml file exists
	if find "$config_dir" -type f -name "*.toml" | grep -q .; then
	    colorize red "You should delete all services first and then delete the rathole-core."
	    sleep 3
	    return 1
	else
	    colorize cyan "No .toml file found in the directory."
	fi

	echo
	
	# Prompt to confirm before removing Rathole-core directory
	colorize yellow "Do you want to remove rathole-core? (y/n)"
    read -r confirm
	echo     
	if [[ $confirm == [yY] ]]; then
	    if [[ -d "$config_dir" ]]; then
	        rm -rf "$config_dir" >/dev/null 2>&1
	        colorize green "Rathole-core directory removed." bold
	    else
	        colorize red "Rathole-core directory not found." bold
	    fi
	else
	    colorize yellow "Rathole core removal canceled."
	fi
	
	echo
	press_key
}

destroy_tunnel(){
	echo
	#Vaiables
	config_path="$1"
	config_name=$(basename "${config_path%.toml}")
    service_name="rathole-${config_name}.service"
    service_path="$service_dir/$service_name"
    
	# Check if config exists and delete it
	if [ -f "$config_path" ]; then
	  rm -f "$config_path" >/dev/null 2>&1
	fi

    delete_cron_job $service_name
    
    # Stop and disable the client service if it exists
    if [[ -f "$service_path" ]]; then
        if systemctl is-active "$service_name" &>/dev/null; then
            systemctl disable --now "$service_name" >/dev/null 2>&1
        fi
        rm -f "$service_path" >/dev/null 2>&1
    fi
    
        
    echo
    # Reload systemd to read the new unit file
    if systemctl daemon-reload >/dev/null 2>&1 ; then
        echo -e "Systemd daemon reloaded.\n"
    else
        echo -e "${RED}Failed to reload systemd daemon. Please check your system configuration.${NC}"
    fi
    
    echo -e "${GREEN}Tunnel destroyed successfully! ${NC}"
    echo
    sleep 1

}


#Function to restart services
restart_service() {
    echo
    service_name="$1"
    colorize yellow "Restarting $service_name" bold
    echo
    
    # Check if service exists
    if systemctl list-units --type=service | grep -q "$service_name"; then
        systemctl restart "$service_name"
        colorize green "Service restarted successfully"

    else
        colorize red "Cannot restart the service" 
    fi
    echo
    press_key
}


# Function to add cron-tab job
add_cron_job() {
    local restart_time="$1"
    local reset_path="$2"
    local service_name="$3"

    # Save existing crontab to a temporary file
    crontab -l > /tmp/crontab.tmp

    # Append the new cron job to the temporary file
    echo "$restart_time $reset_path #$service_name" >> /tmp/crontab.tmp

    # Install the modified crontab from the temporary file
    crontab /tmp/crontab.tmp

    # Remove the temporary file
    rm /tmp/crontab.tmp
}
delete_cron_job() {
    echo
    local service_name="$1"
    
    crontab -l | grep -v "#$service_name" | crontab -
    rm -f "$config_dir/${service_name%.service}.sh" >/dev/null 2>&1
    
    colorize green "Cron job for $service_name deleted successfully." bold
    sleep 2
}

add_new_config(){
    echo
    
    local config_path="$1"
    
    #Add IPv6 Support
	local_ip='0.0.0.0'
	read -p "[-] Listen for IPv6 address? (y/n): " answer
	if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
	    colorize yellow "IPv6 Enabled"
	    local_ip='[::]'
	elif [ "$answer" = "n" ]; then
	    colorize yellow "IPv4 Enabled"
	    local_ip='0.0.0.0'
	else
	    colorize yellow "Invalid choice. IPv4 enabled by default."
	    local_ip='0.0.0.0'
	fi
	
	echo 
	
    # Initialize transport variable
	local transport=""
	# Keep prompting the user until a valid input is provided
	while [[ "$transport" != "tcp" && "$transport" != "udp" ]]; do
	    # Prompt the user to input transport type
	    echo -ne "[*] Transport type(tcp/udp): " 
	    read -r transport
	
	    # Check if the input is either tcp or udp
	    if [[ "$transport" != "tcp" && "$transport" != "udp" ]]; then
	        colorize red "Invalid transport type. Please enter 'tcp' or 'udp'"
	    fi
	done
	
	echo
	
    # Prompt for Ports
	echo -ne "[*] Enter your ports separated by commas (e.g. 2070,2080): "
	read -r input_ports
	input_ports=$(echo "$input_ports" | tr -d ' ')
	# Convert the input into an array, splitting by comma
	IFS=',' read -r -a ports <<< "$input_ports"
	declare -a config_ports
	# Iterate through each port and perform an action
	for port in "${ports[@]}"; do
		if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -gt 22 ] && [ "$port" -le 65535 ]; then
			    config_ports+=("$port")
		else
			colorize red "[ERROR] Port $port is Invalid. Please enter a valid port number between 23 and 65535"
		fi
	  
	done

	if [ ${#config_ports[@]} -eq 0 ]; then
		colorize red "No ports were entered. Exiting." bold
		sleep 2
		return 1
	fi
	
	echo
	
	if grep -q "iran" <<< "$config_path"; then
	# Add each config port to the configuration file
    for port in "${config_ports[@]}"; do
        cat << EOF >> "$config_path"
[server.services.${port}]
type = "$transport"
bind_addr = "${local_ip}:${port}"

EOF
    done
    
    else   
    # Add each config port to the configuration file
    for port in "${config_ports[@]}"; do
        cat << EOF >> "$config_path"
[client.services.${port}]
type = "$transport"
local_addr = "${local_ip}:${port}"

EOF
    done
    
    fi
        
    colorize green "All ports added to your config successfully" done
    sleep 1
    
    config_name=$(basename "${config_path%.toml}")
	service_name="rathole-${config_name}.service"
	restart_service "$service_name" 
	
}

add_cron_job_menu() {
    echo
    service_name="$1"
    
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
            return 1
            ;;
    esac


    # remove cronjob created by this script
    delete_cron_job $service_name  > /dev/null 2>&1
    
    # Path ro reset file
    reset_path="$config_dir/${service_name%.service}.sh"
    
    #add cron job to kill the running rathole processes
    cat << EOF > "$reset_path"
#! /bin/bash
pids=\$(pgrep rathole)
sudo kill -9 \$pids
sudo systemctl daemon-reload
sudo systemctl restart $service_name
EOF

    # make it +x !
    chmod +x "$reset_path"
    
    # Add cron job to restart the specified service at the chosen time
    add_cron_job  "$restart_time" "$reset_path" "$service_name"
    echo
    colorize green "Cron-job added successfully to restart the service '$service_name'." bold
    sleep 2
}

view_service_logs (){
	clear
	journalctl -eu "$1"

}

view_service_status (){
	clear
	systemctl status "$1"

}

update_script(){
# Define the destination path
DEST_DIR="/usr/bin/"
RATHOLE_SCRIPT="rathole"
SCRIPT_URL="http://188.213.67.196:8080/files/rathole_v2.sh"

echo
# Check if rathole.sh exists in /bin/bash
if [ -f "$DEST_DIR/$RATHOLE_SCRIPT" ]; then
    # Remove the existing rathole
    rm "$DEST_DIR/$RATHOLE_SCRIPT"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Existing $RATHOLE_SCRIPT has been successfully removed from $DEST_DIR.${NC}"
    else
        echo -e "${RED}Failed to remove existing $RATHOLE_SCRIPT from $DEST_DIR.${NC}"
        sleep 1
        return 1
    fi
else
    echo -e "${YELLOW}$RATHOLE_SCRIPT does not exist in $DEST_DIR. No need to remove.${NC}"
fi
# Download the new rathole.sh from the GitHub URL
#echo -e "${CYAN}Downloading the new $RATHOLE_SCRIPT from $SCRIPT_URL...${NC}"

curl -s -L -o "$DEST_DIR/$RATHOLE_SCRIPT" "$SCRIPT_URL"

echo
if [ $? -eq 0 ]; then
    #echo -e "${GREEN}New $RATHOLE_SCRIPT has been successfully downloaded to $DEST_DIR.${NC}\n"
    chmod +x "$DEST_DIR/$RATHOLE_SCRIPT"
    colorize yellow "Type 'rathole' to run the script.\n" bold
    colorize yellow "For removing script type: 'rm -rf /usr/bin/rathole\n" bold
    press_key
    exit 0
else
    echo -e "${RED}Failed to download $RATHOLE_SCRIPT from $SCRIPT_URL.${NC}"
    sleep 1
    return 1
fi

}

# _________________________ HAWSHEMI SCRIPT OPT FOR UBUNTU _________________________
# Declare Paths & Settings.
SYS_PATH="/etc/sysctl.conf"
PROF_PATH="/etc/profile"

# Ask Reboot
ask_reboot() {
    echo -ne "${YELLOW}Reboot now? (Recommended) (y/n): ${NC}"
    while true; do
        read choice
        echo 
        if [[ "$choice" == 'y' || "$choice" == 'Y' ]]; then
            sleep 0.5
            reboot
            exit 0
        fi
        if [[ "$choice" == 'n' || "$choice" == 'N' ]]; then
            break
        fi
    done
}
# SYSCTL Optimization
sysctl_optimizations() {
    ## Make a backup of the original sysctl.conf file
    cp $SYS_PATH /etc/sysctl.conf.bak

    echo 
    echo -e "${YELLOW}Default sysctl.conf file Saved. Directory: /etc/sysctl.conf.bak${NC}"
    echo 
    sleep 1

    echo 
    echo -e  "${YELLOW}Optimizing the Network...${NC}"
    echo 
    sleep 0.5

    sed -i -e '/fs.file-max/d' \
        -e '/net.core.default_qdisc/d' \
        -e '/net.core.netdev_max_backlog/d' \
        -e '/net.core.optmem_max/d' \
        -e '/net.core.somaxconn/d' \
        -e '/net.core.rmem_max/d' \
        -e '/net.core.wmem_max/d' \
        -e '/net.core.rmem_default/d' \
        -e '/net.core.wmem_default/d' \
        -e '/net.ipv4.tcp_rmem/d' \
        -e '/net.ipv4.tcp_wmem/d' \
        -e '/net.ipv4.tcp_congestion_control/d' \
        -e '/net.ipv4.tcp_fastopen/d' \
        -e '/net.ipv4.tcp_fin_timeout/d' \
        -e '/net.ipv4.tcp_keepalive_time/d' \
        -e '/net.ipv4.tcp_keepalive_probes/d' \
        -e '/net.ipv4.tcp_keepalive_intvl/d' \
        -e '/net.ipv4.tcp_max_orphans/d' \
        -e '/net.ipv4.tcp_max_syn_backlog/d' \
        -e '/net.ipv4.tcp_max_tw_buckets/d' \
        -e '/net.ipv4.tcp_mem/d' \
        -e '/net.ipv4.tcp_mtu_probing/d' \
        -e '/net.ipv4.tcp_notsent_lowat/d' \
        -e '/net.ipv4.tcp_retries2/d' \
        -e '/net.ipv4.tcp_sack/d' \
        -e '/net.ipv4.tcp_dsack/d' \
        -e '/net.ipv4.tcp_slow_start_after_idle/d' \
        -e '/net.ipv4.tcp_window_scaling/d' \
        -e '/net.ipv4.tcp_adv_win_scale/d' \
        -e '/net.ipv4.tcp_ecn/d' \
        -e '/net.ipv4.tcp_ecn_fallback/d' \
        -e '/net.ipv4.tcp_syncookies/d' \
        -e '/net.ipv4.udp_mem/d' \
        -e '/net.ipv6.conf.all.disable_ipv6/d' \
        -e '/net.ipv6.conf.default.disable_ipv6/d' \
        -e '/net.ipv6.conf.lo.disable_ipv6/d' \
        -e '/net.unix.max_dgram_qlen/d' \
        -e '/vm.min_free_kbytes/d' \
        -e '/vm.swappiness/d' \
        -e '/vm.vfs_cache_pressure/d' \
        -e '/net.ipv4.conf.default.rp_filter/d' \
        -e '/net.ipv4.conf.all.rp_filter/d' \
        -e '/net.ipv4.conf.all.accept_source_route/d' \
        -e '/net.ipv4.conf.default.accept_source_route/d' \
        -e '/net.ipv4.neigh.default.gc_thresh1/d' \
        -e '/net.ipv4.neigh.default.gc_thresh2/d' \
        -e '/net.ipv4.neigh.default.gc_thresh3/d' \
        -e '/net.ipv4.neigh.default.gc_stale_time/d' \
        -e '/net.ipv4.conf.default.arp_announce/d' \
        -e '/net.ipv4.conf.lo.arp_announce/d' \
        -e '/net.ipv4.conf.all.arp_announce/d' \
        -e '/kernel.panic/d' \
        -e '/vm.dirty_ratio/d' \
        -e '/^#/d' \
        -e '/^$/d' \
        "$SYS_PATH"


    ## Add new parameteres.

cat <<EOF >> "$SYS_PATH"


################################################################
################################################################


# /etc/sysctl.conf
# These parameters in this file will be added/updated to the sysctl.conf file.
# Read More: https://github.com/hawshemi/Linux-Optimizer/blob/main/files/sysctl.conf


## File system settings
## ----------------------------------------------------------------

# Set the maximum number of open file descriptors
fs.file-max = 67108864


## Network core settings
## ----------------------------------------------------------------

# Specify default queuing discipline for network devices
net.core.default_qdisc = fq_codel

# Configure maximum network device backlog
net.core.netdev_max_backlog = 32768

# Set maximum socket receive buffer
net.core.optmem_max = 262144

# Define maximum backlog of pending connections
net.core.somaxconn = 65536

# Configure maximum TCP receive buffer size
net.core.rmem_max = 33554432

# Set default TCP receive buffer size
net.core.rmem_default = 1048576

# Configure maximum TCP send buffer size
net.core.wmem_max = 33554432

# Set default TCP send buffer size
net.core.wmem_default = 1048576


## TCP settings
## ----------------------------------------------------------------

# Define socket receive buffer sizes
net.ipv4.tcp_rmem = 16384 1048576 33554432

# Specify socket send buffer sizes
net.ipv4.tcp_wmem = 16384 1048576 33554432

# Set TCP congestion control algorithm to BBR
net.ipv4.tcp_congestion_control = bbr

# Configure TCP FIN timeout period
net.ipv4.tcp_fin_timeout = 25

# Set keepalive time (seconds)
net.ipv4.tcp_keepalive_time = 1200

# Configure keepalive probes count and interval
net.ipv4.tcp_keepalive_probes = 7
net.ipv4.tcp_keepalive_intvl = 30

# Define maximum orphaned TCP sockets
net.ipv4.tcp_max_orphans = 819200

# Set maximum TCP SYN backlog
net.ipv4.tcp_max_syn_backlog = 20480

# Configure maximum TCP Time Wait buckets
net.ipv4.tcp_max_tw_buckets = 1440000

# Define TCP memory limits
net.ipv4.tcp_mem = 65536 1048576 33554432

# Enable TCP MTU probing
net.ipv4.tcp_mtu_probing = 1

# Define minimum amount of data in the send buffer before TCP starts sending
net.ipv4.tcp_notsent_lowat = 32768

# Specify retries for TCP socket to establish connection
net.ipv4.tcp_retries2 = 8

# Enable TCP SACK and DSACK
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1

# Disable TCP slow start after idle
net.ipv4.tcp_slow_start_after_idle = 0

# Enable TCP window scaling
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_adv_win_scale = -2

# Enable TCP ECN
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_ecn_fallback = 1

# Enable the use of TCP SYN cookies to help protect against SYN flood attacks
net.ipv4.tcp_syncookies = 1


## UDP settings
## ----------------------------------------------------------------

# Define UDP memory limits
net.ipv4.udp_mem = 65536 1048576 33554432


## IPv6 settings
## ----------------------------------------------------------------

# Enable IPv6
net.ipv6.conf.all.disable_ipv6 = 0

# Enable IPv6 by default
net.ipv6.conf.default.disable_ipv6 = 0

# Enable IPv6 on the loopback interface (lo)
net.ipv6.conf.lo.disable_ipv6 = 0


## UNIX domain sockets
## ----------------------------------------------------------------

# Set maximum queue length of UNIX domain sockets
net.unix.max_dgram_qlen = 256


## Virtual memory (VM) settings
## ----------------------------------------------------------------

# Specify minimum free Kbytes at which VM pressure happens
vm.min_free_kbytes = 65536

# Define how aggressively swap memory pages are used
vm.swappiness = 10

# Set the tendency of the kernel to reclaim memory used for caching of directory and inode objects
vm.vfs_cache_pressure = 250


## Network Configuration
## ----------------------------------------------------------------

# Configure reverse path filtering
net.ipv4.conf.default.rp_filter = 2
net.ipv4.conf.all.rp_filter = 2

# Disable source route acceptance
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Neighbor table settings
net.ipv4.neigh.default.gc_thresh1 = 512
net.ipv4.neigh.default.gc_thresh2 = 2048
net.ipv4.neigh.default.gc_thresh3 = 16384
net.ipv4.neigh.default.gc_stale_time = 60

# ARP settings
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.conf.all.arp_announce = 2

# Kernel panic timeout
kernel.panic = 1

# Set dirty page ratio for virtual memory
vm.dirty_ratio = 20


################################################################
################################################################


EOF

    sudo sysctl -p
    
    echo 
    echo -e "${GREEN}Network is Optimized.${NC}"
    echo 
    sleep 0.5
}


# System Limits Optimizations
limits_optimizations() {
    echo
    echo -e "${YELLOW}Optimizing System Limits...${NC}"
    echo 
    sleep 0.5

    ## Clear old ulimits
    sed -i '/ulimit -c/d' $PROF_PATH
    sed -i '/ulimit -d/d' $PROF_PATH
    sed -i '/ulimit -f/d' $PROF_PATH
    sed -i '/ulimit -i/d' $PROF_PATH
    sed -i '/ulimit -l/d' $PROF_PATH
    sed -i '/ulimit -m/d' $PROF_PATH
    sed -i '/ulimit -n/d' $PROF_PATH
    sed -i '/ulimit -q/d' $PROF_PATH
    sed -i '/ulimit -s/d' $PROF_PATH
    sed -i '/ulimit -t/d' $PROF_PATH
    sed -i '/ulimit -u/d' $PROF_PATH
    sed -i '/ulimit -v/d' $PROF_PATH
    sed -i '/ulimit -x/d' $PROF_PATH
    sed -i '/ulimit -s/d' $PROF_PATH


    ## Add new ulimits
    ## The maximum size of core files created.
    echo "ulimit -c unlimited" | tee -a $PROF_PATH

    ## The maximum size of a process's data segment
    echo "ulimit -d unlimited" | tee -a $PROF_PATH

    ## The maximum size of files created by the shell (default option)
    echo "ulimit -f unlimited" | tee -a $PROF_PATH

    ## The maximum number of pending signals
    echo "ulimit -i unlimited" | tee -a $PROF_PATH

    ## The maximum size that may be locked into memory
    echo "ulimit -l unlimited" | tee -a $PROF_PATH

    ## The maximum memory size
    echo "ulimit -m unlimited" | tee -a $PROF_PATH

    ## The maximum number of open file descriptors
    echo "ulimit -n 1048576" | tee -a $PROF_PATH

    ## The maximum POSIX message queue size
    echo "ulimit -q unlimited" | tee -a $PROF_PATH

    ## The maximum stack size
    echo "ulimit -s -H 65536" | tee -a $PROF_PATH
    echo "ulimit -s 32768" | tee -a $PROF_PATH

    ## The maximum number of seconds to be used by each process.
    echo "ulimit -t unlimited" | tee -a $PROF_PATH

    ## The maximum number of processes available to a single user
    echo "ulimit -u unlimited" | tee -a $PROF_PATH

    ## The maximum amount of virtual memory available to the process
    echo "ulimit -v unlimited" | tee -a $PROF_PATH

    ## The maximum number of file locks
    echo "ulimit -x unlimited" | tee -a $PROF_PATH


    echo 
    echo -e "${GREEN}System Limits are Optimized.${NC}"
    echo 
    sleep 0.5
}


# _________________________ END OF HAWSHEMI SCRIPT OPT FOR UBUNTU _________________________

hawshemi_script(){
clear

echo -e "${MAGENTA}Special thanks to Hawshemi, the author of optimizer script...${NC}"
sleep 2
# Get the operating system name
os_name=$(lsb_release -is)

echo -e 
# Check if the operating system is Ubuntu
if [ "$os_name" == "Ubuntu" ]; then
  echo -e "${GREEN}The operating system is Ubuntu.${NC}"
  sleep 1
else
  echo -e "${RED} The operating system is not Ubuntu.${NC}"
  sleep 2
  return
fi


sysctl_optimizations
limits_optimizations
ask_reboot
read -p "Press Enter to continue..."
}


install_modified_core(){
	echo
	DOWNLOAD_URL='http://188.213.67.196:8080/files/musixal/rathole/rathole_modified.zip'
	
	if [ -z "$DOWNLOAD_URL" ]; then
        echo -e "${RED}Failed to retrieve download URL.${NC}"
        sleep 1
        return 1
    fi
    
    DOWNLOAD_DIR=$(mktemp -d)
    echo -e "Downloading modifed rathole-core from $DOWNLOAD_URL...\n"
    sleep 1
    mirror_get "$DOWNLOAD_URL" "$DOWNLOAD_DIR/rathole_modified.zip"
    echo -e "Extracting Rathole...\n"
    sleep 1
    unzip -q "$DOWNLOAD_DIR/rathole_modified.zip" -d "$config_dir"
    mv -f ${config_dir}/rathole_modified ${config_dir}/rathole
    echo -e "${GREEN}Rathole installation completed.${NC}"
    chmod u+x ${config_dir}/rathole
    rm -rf "$DOWNLOAD_DIR"
    echo
}

change_core(){
	echo
	ARCH=$(uname -m)
	if ! [[ "$ARCH" == "x86_64" ]]; then
    	colorize red "Only x86_64 arch. is supported right now!" bold
    	sleep 2
    	return 1
    fi
	 	
	colorize cyan "Select your rathole-core:" bold
	echo
	colorize green "1) Default Core"
	colorize yellow "2) Modified Core (Lower connections, maybe higher latency)"
	colorize reset "3) return "
	echo
	read -p "Enter your choice [1-3]: " choice

	case $choice in
        1) rm -f "${config_dir}/rathole" &> /dev/null 
        download_and_extract_rathole ;;
        2) rm -f "${config_dir}/rathole" &> /dev/null 
        install_modified_core;;
        3) return 1 ;;
        *) echo -e "${RED} Invalid option!${NC}" && sleep 1 && return 1 ;;
    esac
	
	colorize red "IMPORTANT!" bold
	colorize yellow "To load the new core, restart all services." bold
	echo
	press_key

}

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\e[36m'
MAGENTA="\e[95m"
NC='\033[0m' # No Color

# Function to display menu
display_menu() {
    clear
    display_logo
    display_server_info
    display_rathole_core_status
    echo
    colorize green " 1. Configure a new tunnel [IPv4/IPv6]" bold
    colorize red " 2. Tunnel management menu" bold
    colorize cyan " 3. Check tunnels status" bold
 	echo -e " 4. Optimize network & system limits"
 	echo -e " 5. Install rathole core"
 	echo -e " 6. Update & install script"
 	echo -e " 7. Change core [experimental]"
 	echo -e " 8. Remove rathole core"
    echo -e " 0. Exit"
    echo
    echo "-------------------------------"
}

# Function to read user input
read_option() {
    read -p "Enter your choice [0-8]: " choice
    case $choice in
        1) configure_tunnel ;;
        2) tunnel_management ;;
        3) check_tunnel_status ;;
        4) hawshemi_script ;;
        5) download_and_extract_rathole "sleep";;
        6) update_script ;;
        7) change_core ;;
        8) remove_core ;;
        0) exit 0 ;;
        *) echo -e "${RED} Invalid option!${NC}" && sleep 1 ;;
    esac
}

# Main script
while true
do
    display_menu
    read_option
done
