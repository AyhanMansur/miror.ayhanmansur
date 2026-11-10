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

# Logo
show_logo() {
echo -e "${BLUE}"
cat << "EOF"
    __  _____    ____                       
   / / / /   |  / __ \_________  _  ____  __
  / /_/ / /| | / /_/ / ___/ __ \| |/_/ / / /
 / __  / ___ |/ ____/ /  / /_/ />  </ /_/ / 
/_/ /_/_/  |_/_/   /_/   \____/_/|_|\__, /  
                                   /____/   
                  github.com/Musixal v1.2 
EOF
  echo -e "${NC}"
}

# Check if the script is being run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    sleep 2
    exit 1
fi

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
            read -p "Press any key to continue..."
            exit 1
        fi
    
    fi
}


# Install jq
install_jq

install_haproxy() {
    if ! command -v haproxy &> /dev/null; then
        # Check if the system is using apt package manager
        if command -v apt-get &> /dev/null; then
            echo -e "${RED}HAProxy is not installed. Installing...${NC}"
            sleep 1
            true
            install_from_mirror haproxy
        else
            echo -e "${RED}Error: Unsupported package manager. Please install HAProxy manually.${NC}\n"
            read -p "Press any key to continue..."
            exit 1
        fi
    fi
}

#install HAProxy
install_haproxy


# Fetch server country
SERVER_COUNTRY=$(curl --max-time 5 -sS "http://ipwhois.app/json/$SERVER_IP" | jq -r '.country')

# Fetch server isp 
SERVER_ISP=$(curl --max-time 5 -sS "http://ipwhois.app/json/$SERVER_IP" | jq -r '.isp')

# Function to display server location and IP
display_server_info() {
    echo -e "${GREEN}Location:${NC} $SERVER_COUNTRY "
    echo -e "${GREEN}Datacenter:${NC} $SERVER_ISP"
}

# Function to show HAProxy status
show_haproxy_status() {
    # Check if HAProxy is installed
    if ! command -v haproxy &>/dev/null; then
        echo -e "${RED}HAProxy is not installed.${NC}"
        return
    fi

    # Check the status of HAProxy service
    systemctl is-active --quiet haproxy && echo -e "${GREEN}HAProxy is active${NC}" || echo -e "${RED}HAProxy is not active${NC}"
}


# Menu for multi-server configuration
multiple_server_menu() {
clear
    echo -e "Select an option:"
    echo ''
    echo -e "${GREEN}1. New Configuration${NC}"
    echo -e "${BLUE}2. Add a new config${NC}"
    echo -e "${RED}3. Quit${NC}"
    echo ''
    read -p "Enter your choice: " choice
    case $choice in
        1) configure_new_tunnel ;;
        2) add_new_server ;;
        3) echo -e "${RED}3. Exiting...${NC}" && sleep 1 && return 0 ;;
        *) echo -e "${RED}Invalid option!${NC}" && sleep 1  ;;
    esac
}

# Define the default HAProxy configuration file path
haproxy_config_file="/etc/haproxy/haproxy.cfg"

# Function to configure tunnel
configure_new_tunnel() {
clear
# Prompt the user for confirmation
read -p "All your previous configs will be deleted, continue? (yes/no): " confirm

# Check user's response
if ! [[ $confirm == "yes" || $confirm == "Yes" || $confirm == "YES" ]]; then
	echo -e "${RED}Operation cancelled by user.${NC}" && sleep 1
	return 1
fi

echo

# Verify if the file exists, if not, create it
if [ ! -f "$haproxy_config_file" ]; then
    touch "$haproxy_config_file"
fi

echo "# HAProxy configuration generated by script" > "$haproxy_config_file"
echo "global" >> "$haproxy_config_file"
echo "    log /dev/log    local0" >> "$haproxy_config_file"
echo "    log /dev/log    local1 notice" >> "$haproxy_config_file"
echo "    chroot /var/lib/haproxy" >> "$haproxy_config_file"
echo "    stats socket /run/haproxy/admin.sock mode 660 level admin" >> "$haproxy_config_file"
echo "    stats timeout 30s" >> "$haproxy_config_file"
echo "    user haproxy" >> "$haproxy_config_file"
echo "    group haproxy" >> "$haproxy_config_file"
echo "    daemon" >> "$haproxy_config_file"
echo "" >> "$haproxy_config_file"
echo "defaults" >> "$haproxy_config_file"
echo "    log     global" >> "$haproxy_config_file"
echo "    mode    tcp" >> "$haproxy_config_file"
echo "    option  tcplog" >> "$haproxy_config_file"
echo "    option  dontlognull" >> "$haproxy_config_file"
echo "    timeout connect 5000ms" >> "$haproxy_config_file"
echo "    timeout client  50000ms" >> "$haproxy_config_file"
echo "    timeout server  50000ms" >> "$haproxy_config_file"
echo "" >> "$haproxy_config_file"

    # Add multi-port support
    read -p "1. Enter HAProxy bind ports (e.g., 443,8443,2096): " haproxy_bind_ports
    read -p "2. Enter Destination ports (in the same order as HAProxy bind ports, e.g., 443,8443,2096): " destination_ports
    read -p "3. Enter Destination (Kharej) IP address: " destination_ip

    # Split the comma-separated ports into arrays
    IFS=',' read -r -a haproxy_ports_array <<< "$haproxy_bind_ports"
    IFS=',' read -r -a destination_ports_array <<< "$destination_ports"

    # Check if both arrays have the same length
    if [ "${#haproxy_ports_array[@]}" -ne "${#destination_ports_array[@]}" ]; then
        echo -e "${RED}The number of HAProxy bind ports and Destination ports must match.${NC}"
        read -p "Press Enter to continue..."
        systemctl stop haproxy
        rm -f "$haproxy_config_file"
        return 1
    fi

    # Iterate over each port in the array
    for i in "${!haproxy_ports_array[@]}"; do
        haproxy_bind_port="${haproxy_ports_array[$i]}"
        destination_port="${destination_ports_array[$i]}"
        
        # Trim any leading or trailing whitespace from the ports
        haproxy_bind_port=$(echo "$haproxy_bind_port" | xargs)
        destination_port=$(echo "$destination_port" | xargs)
        
        # Append frontend and backend configurations to HAProxy configuration file
        echo "frontend frontend_$haproxy_bind_port" >> "$haproxy_config_file"
        echo "    bind *:$haproxy_bind_port" >> "$haproxy_config_file"
        echo "    default_backend backend_$haproxy_bind_port" >> "$haproxy_config_file"
        echo "" >> "$haproxy_config_file"
        echo "backend backend_$haproxy_bind_port" >> "$haproxy_config_file"
        echo "    server server_$haproxy_bind_port $destination_ip:$destination_port" >> "$haproxy_config_file"
        echo "" >> "$haproxy_config_file"
    done
 
echo
echo -e "${GREEN}Configuration updated successfully in $haproxy_config_file${NC}"

  
    # Restart HAProxy service
    systemctl restart haproxy
    
    echo 
    read -p "Press Enter to continue..."
}

#Function to add a new server
add_new_server(){
# Verify if the file exists, if not, return
if [ ! -f "$haproxy_config_file" ]; then
     echo ''
     echo -e "${RED} There is no HAProxy config. First configurate a tunnel through option 1${NC}\n"
     read -p "Press Enter to continue..."
     return 1
fi

clear
while true; do
	clear
    read -p "Enter HAProxy bind port: " haproxy_bind_port
    read -p "Enter Destination (Kharej) IP address: " destination_ip
    read -p "Enter Destination port: " destination_port

    # Append frontend and backend configurations to HAProxy configuration file
    echo "frontend frontend_$haproxy_bind_port" >> "$haproxy_config_file"
    echo "    bind *:$haproxy_bind_port" >> "$haproxy_config_file"
    echo "    default_backend backend_$haproxy_bind_port" >> "$haproxy_config_file"
    echo "" >> "$haproxy_config_file"
    echo "backend backend_$haproxy_bind_port" >> "$haproxy_config_file"
    echo "    server server_$haproxy_bind_port $destination_ip:$destination_port" >> "$haproxy_config_file"
    echo "" >> "$haproxy_config_file"
	echo ''
    read -p "Do you want to add another config? (yes/no): " add_another
    echo ''
    if [[ $add_another != "yes" ]]; then
        break
    fi
done

echo -e "${GREEN}Configuration updated successfully in $haproxy_config_file${NC}"
  
    # Restart HAProxy service
    systemctl restart haproxy
    echo ''
    read -p "Press Enter to continue..."
}

#Function for loadbalancing
load_balancing() {
clear
# Prompt the user for confirmation
read -p "All your previous configs will be deleted, continue? (yes/no): " confirm
echo ''
# Check user's response
if ! [[ $confirm == "yes" || $confirm == "Yes" || $confirm == "YES" ]]; then
	echo -e "${RED}Operation cancelled by user.${NC}" && sleep 1
	return 1
fi

# Verify if the file exists, if not, create it
if [ ! -f "$haproxy_config_file" ]; then
    touch "$haproxy_config_file"
fi



echo "# HAProxy configuration generated by script" > "$haproxy_config_file"
echo "global" >> "$haproxy_config_file"
echo "    log /dev/log    local0" >> "$haproxy_config_file"
echo "    log /dev/log    local1 notice" >> "$haproxy_config_file"
echo "    chroot /var/lib/haproxy" >> "$haproxy_config_file"
echo "    stats socket /run/haproxy/admin.sock mode 660 level admin" >> "$haproxy_config_file"
echo "    stats timeout 30s" >> "$haproxy_config_file"
echo "    user haproxy" >> "$haproxy_config_file"
echo "    group haproxy" >> "$haproxy_config_file"
echo "    daemon" >> "$haproxy_config_file"
echo "" >> "$haproxy_config_file"
echo "defaults" >> "$haproxy_config_file"
echo "    log     global" >> "$haproxy_config_file"
echo "    mode    tcp" >> "$haproxy_config_file"
echo "    option  tcplog" >> "$haproxy_config_file"
echo "    option  dontlognull" >> "$haproxy_config_file"
echo "    timeout connect 5000ms" >> "$haproxy_config_file"
echo "    timeout client  50000ms" >> "$haproxy_config_file"
echo "    timeout server  50000ms" >> "$haproxy_config_file"
echo "" >> "$haproxy_config_file"

# to display load balancing options
    echo -e "${BLUE}Load balancing options:${NC}"
    echo "1. Round Robin"
    echo "2. Least Connections"
    echo "3. Source IP Hash"
    echo "4. URI Hash"
    read -p "Select the desired load balancing algorithm: " choice
	
    case $choice in
        1) lb_algorithm="roundrobin";;
        2) lb_algorithm="leastconn";;
        3) lb_algorithm="source";;
        4) lb_algorithm="uri";;
        *) echo "Invalid input. Using default load balancing algorithm (roundrobin)."
           lb_algorithm="roundrobin";;
    esac
 
 #Prompt the user for HAProxy bind port   
echo ''
read -p "*. Enter HAProxy bind port for load balancing: " haproxy_bind_port
echo "frontend tcp_frontend" >> "$haproxy_config_file"
echo "    bind *:${haproxy_bind_port}" >> "$haproxy_config_file"
echo "    mode tcp" >> "$haproxy_config_file"
echo "    default_backend tcp_backend" >> "$haproxy_config_file"
echo "" >> "$haproxy_config_file"
echo "backend tcp_backend" >> "$haproxy_config_file"
echo "    mode tcp" >> "$haproxy_config_file"
echo "    balance $lb_algorithm" >> "$haproxy_config_file"

clear
# Prompt the user for corresponding Destination IP and port
server=1
while true; do
	echo ''
    read -p "1. Enter Destination IP address for loadbalancing: " destination_ip
    read -p "2. Enter Destination port for loadbalancing: " destination_port
    
echo "    server server${server} ${destination_ip}:${destination_port} check" >> "$haproxy_config_file"
    
    echo ''
    read -p "Do you want to add another server for load balancing? (yes/no): " add_another

    if [[ $add_another != "yes" ]]; then
        break
    fi
    server=$((server + 1))
    clear
done

echo ''
echo -e "${GREEN}Configuration updated successfully in $haproxy_config_file${NC}"

  
    # Restart HAProxy service
    systemctl restart haproxy
    
    echo ''
    read -p "Press Enter to continue..."
    
}

# Function to destroy tunnel
destroy_tunnel() {
echo ''
# Check if HAProxy service is running
if systemctl is-active --quiet haproxy; then
    echo -e "${RED}Stopping HAProxy service...${NC}\n"
    sleep 1
    # Stop HAProxy service
    systemctl stop haproxy
    echo -e "${GREEN}HAProxy service stopped.${NC}"
else
    echo -e "${YELLOW}HAProxy service is not running.${NC}"
fi

echo ''
# Check if the file exists
if [ -f "$haproxy_config_file" ]; then
    echo -e "${RED}Removing ${haproxy_config_file}...${NC}\n"
    sleep 1
    # Remove the file
    rm "$haproxy_config_file"
    echo -e "${GREEN}$haproxy_config_file removed.${NC}"
else
    echo -e "${YELLOW}$haproxy_config_file does not exist.${NC}"
fi

echo ''
    read -p "Press Enter to continue..."
}

# Function to reset service
reset_service() {
echo -e "\n${YELLOW}Restarting HAProxy service...${NC}\n"
sleep 1
# Restart HAProxy
echo "Restarting HAProxy..."
echo ''
if systemctl restart haproxy ; then
    echo -e "${GREEN}HAProxy restarted successfully.${NC}"
else
    echo -e "${RED}Error: Failed to restart HAProxy.${NC}"
fi

echo ''
read -p "Press Enter to continue..."
}

view_haproxy_log_realtime() {
	clear
    # Define HAProxy log file path
    haproxy_log_file="/var/log/haproxy.log"

    # Check if HAProxy log file exists
    if [ ! -f "$haproxy_log_file" ]; then
        echo "HAProxy log file not found at $haproxy_log_file"
        return 1
    fi

    # Display HAProxy log in real-time
    echo "Displaying real-time HAProxy log ($haproxy_log_file):"
    tail -f "$haproxy_log_file"
}

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[36m'
NC='\033[0m' # No Color


# Function to display menu
display_menu(){
	clear
	show_logo
	display_server_info
	echo "-------------------------------"
	show_haproxy_status
    echo "-------------------------------"
    echo "Menu:"
    echo -e "${GREEN}1. Configure Tunnel (IPv4/v6)${NC}"
    echo -e "${BLUE}2. Configure Loadbalancer (IPv4/v6)${NC}"
    echo -e "${RED}3. Stop HAProxy service and remove configs${NC}"
    echo -e "${YELLOW}4. Restart HAProxy Service${NC}"
    echo -e "5. View HAProxy real-time logs"
    echo "6. Exit"
    echo "-------------------------------"
  }
# Function to read user input
read_option(){
    read -p "Enter your choice: " choice
    case $choice in
        1) multiple_server_menu ;;
        2) load_balancing ;;
        3) destroy_tunnel ;;
        4) reset_service ;;
        5) view_haproxy_log_realtime ;;
        6) echo "Exiting..." && exit ;;
        *) echo -e "${RED}Invalid option!${NC}" && sleep 1 ;;
    esac
}

# Main loop
while true
 do
	display_menu
	read_option
done
