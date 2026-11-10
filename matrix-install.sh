#!/usr/bin/env bash
# Installs a Matrix server on Ubuntu 22.04, 24.04, or 26.04 from an offline mirror. It installs Synapse (the
# server), Element Web (the browser client, for chat on any device), Caddy (HTTPS), and coturn (the TURN
# server that relays calls when a participant is behind NAT). Every download is checked against the sha256
# value in this script.
#
# The installer asks for each value when a terminal is attached. A value that is already set in the
# environment is not asked for:
#   MATRIX_PUBLIC_HOST     host name or IP address that clients use (required)
#   MATRIX_TLS             internal (default: a CA made here), file (your certificate), or http (no TLS)
#   MATRIX_TLS_CERT_FILE   PEM certificate with the full chain (MATRIX_TLS=file)
#   MATRIX_TLS_KEY_FILE    PEM private key (MATRIX_TLS=file)
#   MATRIX_HTTPS_PORT      HTTPS port for the chat, Element and calls (default 443; not used with MATRIX_TLS=http)
#   MATRIX_HTTP_PORT       HTTP port: redirects to HTTPS, or serves the chat with MATRIX_TLS=http (default 80)
#   MATRIX_TURN_PORT       TURN port for calls, UDP and TCP (default 3478)
#   MATRIX_RELAY_RANGE     UDP ports that coturn relays calls on, as min-max (default 49152-65535)
#   MATRIX_REGISTRATION    open (default: anyone can sign up) or closed
#   MATRIX_ADMIN_USER      administrator account to create (empty: none)
#   MATRIX_ADMIN_PASSWORD  its password, asked twice and hidden (at least 8 characters)
#   NONINTERACTIVE=1       never prompt; values that are not set take their defaults
#
# Calls need HTTPS: browsers allow the microphone and the camera only on a secure page. With
# MATRIX_TLS=http the chat still works, and calls do not.
set -euo pipefail
# The files this script writes must be readable by the service user, whatever the caller's umask.
umask 022

INSTALL_DIR=/opt/matrix
DATA_DIR=/opt/matrix/data
SVC_USER=matrix-synapse
MIRROR_FILES="http://188.213.67.196:8080/files"
declare -A MIRROR_SHA256=(
  ["apt/22.04/amd64/turn/coturn_4.5.2-3.1~ubuntu22.04.1_amd64.deb"]="d59559bad7aebba7777bd4a8f66e355aebe75927d0f71f4f8dc6c6b522755acc"
  ["apt/22.04/amd64/turn/libevent-core-2.1-7_2.1.12-stable-1ubuntu0.2_amd64.deb"]="6d2f5e6d338d0eea7dd21d701e5f8cd4b44efb1287dbcb84b6f0342ae3be492f"
  ["apt/22.04/amd64/turn/libevent-extra-2.1-7_2.1.12-stable-1ubuntu0.2_amd64.deb"]="060beeb5d7bc6663b4dfe9b6f905cd587b472ad5818881fecd37736b5374af7e"
  ["apt/22.04/amd64/turn/libevent-openssl-2.1-7_2.1.12-stable-1ubuntu0.2_amd64.deb"]="d169557acfb8a785b5482afc37ea6ebb68fd4da4ea07d63162b0369caa2e2459"
  ["apt/22.04/amd64/turn/libevent-pthreads-2.1-7_2.1.12-stable-1ubuntu0.2_amd64.deb"]="a96f28db4a73f5c6edef5080ee3bc51e4d53ea203d9294b716e0850c13b67b69"
  ["apt/22.04/amd64/turn/libhiredis0.14_0.14.1-2_amd64.deb"]="eb382ba7f1955d111a3b6a70e465d1d8accf995106315b4b9562378c328b411f"
  ["apt/22.04/amd64/turn/libmysqlclient21_8.0.46-0ubuntu0.22.04.4_amd64.deb"]="ad7b6f491ca0f41fe9651ff03b39576c12d08d57417b575cc3b36a3fc493b815"
  ["apt/22.04/amd64/turn/libpq5_14.24-0ubuntu0.22.04.1_amd64.deb"]="79f9af127350c5bbf4c1722ebc4aa7d31ae4fd71b0404e501f7a76ed65709e0d"
  ["apt/22.04/amd64/turn/libreadline8_8.1.2-1_amd64.deb"]="51fd16f608efa710c987e4b071ffba0bec63a9ac8e55eddd5770f5e5252edc09"
  ["apt/22.04/amd64/turn/libsqlite3-0_3.37.2-2ubuntu0.8_amd64.deb"]="6e22b1e8d375fed6a1d52cad5887e762b6cdeaba137595e726c95486968dfab5"
  ["apt/22.04/amd64/turn/mysql-common_5.8+1.0.8_all.deb"]="1e4e9c090c71333a6f83c2d3021866e77a21df914cd2af40bf2892054f97ed35"
  ["apt/22.04/amd64/turn/netbase_6.3_all.deb"]="480bbd894069e5da7a25f070ea0ebaded7f64bdd34a119558cc2fe7137762a79"
  ["apt/22.04/amd64/turn/readline-common_8.1.2-1_all.deb"]="a78d02935f6107a12d3d349c25ce4f92fcdcbf6b65e37f1f5a13a9054b5b9e94"
  ["apt/22.04/amd64/turn/sqlite3_3.37.2-2ubuntu0.8_amd64.deb"]="76626c2071bd7da459c04494e2f0d563661fa27b121d6f492266e2c9e993c930"
  ["apt/22.04/amd64/turn/telnet_0.17-44build1_amd64.deb"]="96daeef97f2a42d64aa8fec930340835655cd9df3f105613ca7a7405ba9b51be"
  ["apt/22.04/arm64/turn/coturn_4.5.2-3.1~ubuntu22.04.1_arm64.deb"]="7125ab6a60ee46366dc5589fa51ea1d34c0c251e0023b49589fd7df9e970f0f7"
  ["apt/22.04/arm64/turn/libevent-core-2.1-7_2.1.12-stable-1ubuntu0.2_arm64.deb"]="28f401c4f73d48b55acb99a304a562b1de30dc0bf98a0d4b2f618b16835aebf8"
  ["apt/22.04/arm64/turn/libevent-extra-2.1-7_2.1.12-stable-1ubuntu0.2_arm64.deb"]="55657976ac9099f483ed6566f8efcc7c751692d0f8709c154528ffcf1b890e9c"
  ["apt/22.04/arm64/turn/libevent-openssl-2.1-7_2.1.12-stable-1ubuntu0.2_arm64.deb"]="6103e7a180c67e73316579c6d07653aed3b4437d3fc2d64f2feda762771097a2"
  ["apt/22.04/arm64/turn/libevent-pthreads-2.1-7_2.1.12-stable-1ubuntu0.2_arm64.deb"]="266144fc37f6eea1eeef6a9c62a606573421f33760efdbbf826668b452573311"
  ["apt/22.04/arm64/turn/libhiredis0.14_0.14.1-2_arm64.deb"]="b0b2426887ec8121cb03ebf74f65a6b52601d3a70630112d11380eb8991e1183"
  ["apt/22.04/arm64/turn/libmysqlclient21_8.0.46-0ubuntu0.22.04.4_arm64.deb"]="6e2304a58f01deb20715962c7e92669fd67638e750225511e4a7017d396eb63e"
  ["apt/22.04/arm64/turn/libpq5_14.24-0ubuntu0.22.04.1_arm64.deb"]="61950dd6c8ed2e1ec994bcbdb4634cf590549d42a58d28cc40cced60eec52078"
  ["apt/22.04/arm64/turn/libreadline8_8.1.2-1_arm64.deb"]="54291f2dd185d3a759227b31b7de4269e495a084fdad89e24a9cc4d0d20888a7"
  ["apt/22.04/arm64/turn/libsqlite3-0_3.37.2-2ubuntu0.8_arm64.deb"]="0bb81a51a7a56aa66a6bf981e6a4dc4040b1873dc2fc29e8834c977585068e9c"
  ["apt/22.04/arm64/turn/mysql-common_5.8+1.0.8_all.deb"]="1e4e9c090c71333a6f83c2d3021866e77a21df914cd2af40bf2892054f97ed35"
  ["apt/22.04/arm64/turn/netbase_6.3_all.deb"]="480bbd894069e5da7a25f070ea0ebaded7f64bdd34a119558cc2fe7137762a79"
  ["apt/22.04/arm64/turn/readline-common_8.1.2-1_all.deb"]="a78d02935f6107a12d3d349c25ce4f92fcdcbf6b65e37f1f5a13a9054b5b9e94"
  ["apt/22.04/arm64/turn/sqlite3_3.37.2-2ubuntu0.8_arm64.deb"]="01dffd103ea5ca52e32a57b3f6d314e7f3955bdd08a3b10466d2b7a1eb674e99"
  ["apt/22.04/arm64/turn/telnet_0.17-44build1_arm64.deb"]="f2ccdff102afda667241e844ecb0a058f78809aaf2cdcce9956fd48371f4635f"
  ["apt/24.04/amd64/turn/adduser_3.137ubuntu1_all.deb"]="542aff2395eb912a56833e11a78076342779689d8fede7adcf08d1d6b0d0cd8b"
  ["apt/24.04/amd64/turn/coturn_4.6.1-1build4_amd64.deb"]="4c14eb45b96b23b63a912afc1f54657a1c9c67b52b582ff45b3427cc3c182604"
  ["apt/24.04/amd64/turn/inetutils-telnet_2_2.5-3ubuntu4.2_amd64.deb"]="078ee4e769e8462727000570e25595b4e61b4caa9d58f0668bd3948637419faf"
  ["apt/24.04/amd64/turn/libevent-core-2.1-7t64_2.1.12-stable-9ubuntu2.2_amd64.deb"]="2a5264b572f5fe50fc9d63e115d308c79b9fb746d13cc55b5ea1f0f01a78daa7"
  ["apt/24.04/amd64/turn/libevent-extra-2.1-7t64_2.1.12-stable-9ubuntu2.2_amd64.deb"]="0cb0db6b496baa12252451d63516df02981fbb5adbe523a82983a6c3bffda747"
  ["apt/24.04/amd64/turn/libevent-openssl-2.1-7t64_2.1.12-stable-9ubuntu2.2_amd64.deb"]="d2d3e4bb39e969574117006217fbb34c33c66d40e0973205bcb637d9306a3aed"
  ["apt/24.04/amd64/turn/libevent-pthreads-2.1-7t64_2.1.12-stable-9ubuntu2.2_amd64.deb"]="0adf5bc30f0326ad4aa36541f4dfa4a0d5f42c5564f74c0112caf8b3c13a7fbb"
  ["apt/24.04/amd64/turn/libhiredis1.1.0_1.2.0-6ubuntu3_amd64.deb"]="912a25553f29a47d1524c0b58a3c5bff2d067109da2adae9fa9c4fb15efaa568"
  ["apt/24.04/amd64/turn/libmysqlclient21_8.0.46-0ubuntu0.24.04.4_amd64.deb"]="830f21eb986cca5b9fb46c258a7d081a95cb8ebfde142bac3e9b7b5fb6418dbc"
  ["apt/24.04/amd64/turn/libpq5_16.15-0ubuntu0.24.04.1_amd64.deb"]="3f96dd36bcd7841172c1ead4965da20a193bb9ccf9a93a3f5a3ac7f56369dbb1"
  ["apt/24.04/amd64/turn/libreadline8t64_8.2-4build1_amd64.deb"]="563977a16df03b611f5239cc1e9a0426e86479fcc616b5c9e200ea32063119e5"
  ["apt/24.04/amd64/turn/libsqlite3-0_3.45.1-1ubuntu2.8_amd64.deb"]="b1190bb72359f5fcc47406aa46065eaf4f1ca208085c51224a52b04bedc0b4bb"
  ["apt/24.04/amd64/turn/mysql-common_5.8+1.1.0build1_all.deb"]="2a9ed286f4a78849bb0231b11a9ababf8c8694667caf986cd2563a6b67f939bc"
  ["apt/24.04/amd64/turn/netbase_6.4_all.deb"]="8cdbc9c3dca01e660759bf9d840f72e45ac72faf5d19ca1faecacaf6a60c1a87"
  ["apt/24.04/amd64/turn/readline-common_8.2-4build1_all.deb"]="879bfd7f8a9bc4c0f7cdc777cdd8bc6de5f8c4a2ac80c060322a1b22f13504bb"
  ["apt/24.04/amd64/turn/sqlite3_3.45.1-1ubuntu2.8_amd64.deb"]="78493e56909614ec1d588c9fae1739a704d9e1a6ff65509b1f06c3e4d53ed0c3"
  ["apt/24.04/amd64/turn/telnet_0.17+2.5-3ubuntu4.2_all.deb"]="df0bb0964156d1eca3ca5bee0ffa09089f8ac880038ee33e210b45f2337f3e95"
  ["apt/24.04/arm64/turn/adduser_3.137ubuntu1_all.deb"]="542aff2395eb912a56833e11a78076342779689d8fede7adcf08d1d6b0d0cd8b"
  ["apt/24.04/arm64/turn/coturn_4.6.1-1build4_arm64.deb"]="d2bf51369fe77077080ef59a3e1849e292756fc04a6469182cea75fa923acc46"
  ["apt/24.04/arm64/turn/inetutils-telnet_2_2.5-3ubuntu4.2_arm64.deb"]="86ba9e5901422b311fa89b363d809e615248f8d340dfcffb0bd04d586f61df31"
  ["apt/24.04/arm64/turn/libevent-core-2.1-7t64_2.1.12-stable-9ubuntu2.2_arm64.deb"]="2fff3280ca73b151af50f29057b56b050465df23c255ece6f8cd83103c6fc711"
  ["apt/24.04/arm64/turn/libevent-extra-2.1-7t64_2.1.12-stable-9ubuntu2.2_arm64.deb"]="78e14cce30015511f623d9374c2b3d2ebbd480ff772f62d05126ee743a45956c"
  ["apt/24.04/arm64/turn/libevent-openssl-2.1-7t64_2.1.12-stable-9ubuntu2.2_arm64.deb"]="248753764524982173e11f731d929fc420356045b26cb5ba0ec20f31361df246"
  ["apt/24.04/arm64/turn/libevent-pthreads-2.1-7t64_2.1.12-stable-9ubuntu2.2_arm64.deb"]="07f2eb4ba77055429b24d10fce941a378197b9d4fcac44fb99fef187cede9e7b"
  ["apt/24.04/arm64/turn/libhiredis1.1.0_1.2.0-6ubuntu3_arm64.deb"]="378a26e4425a5de22fac07d94c7f98525b0638f790b3ee13c04c2b4438bcf3e1"
  ["apt/24.04/arm64/turn/libmysqlclient21_8.0.46-0ubuntu0.24.04.4_arm64.deb"]="3044e9126fed3377d0e5a306c4b89ca781903df711c5af4cc2fe72dd1eddbf13"
  ["apt/24.04/arm64/turn/libpq5_16.15-0ubuntu0.24.04.1_arm64.deb"]="055539466b14c305fbfe48a5fbfe7242d3fea3ab0bc3b9ab1b9d7c8da6548048"
  ["apt/24.04/arm64/turn/libreadline8t64_8.2-4build1_arm64.deb"]="7f46b2f3ca588cd2f05d2cfb6844017309760b4201105cdfda4b339f9e6c69da"
  ["apt/24.04/arm64/turn/libsqlite3-0_3.45.1-1ubuntu2.8_arm64.deb"]="85925089ef6820a5b6ed80bb490d187465e49687c388333895680fda54e3ee06"
  ["apt/24.04/arm64/turn/mysql-common_5.8+1.1.0build1_all.deb"]="2a9ed286f4a78849bb0231b11a9ababf8c8694667caf986cd2563a6b67f939bc"
  ["apt/24.04/arm64/turn/netbase_6.4_all.deb"]="8cdbc9c3dca01e660759bf9d840f72e45ac72faf5d19ca1faecacaf6a60c1a87"
  ["apt/24.04/arm64/turn/readline-common_8.2-4build1_all.deb"]="879bfd7f8a9bc4c0f7cdc777cdd8bc6de5f8c4a2ac80c060322a1b22f13504bb"
  ["apt/24.04/arm64/turn/sqlite3_3.45.1-1ubuntu2.8_arm64.deb"]="ced8d1e467584a3d96b89b79d1b8342b173966db21f9acedae8f568ca7f85147"
  ["apt/24.04/arm64/turn/telnet_0.17+2.5-3ubuntu4.2_all.deb"]="df0bb0964156d1eca3ca5bee0ffa09089f8ac880038ee33e210b45f2337f3e95"
  ["apt/26.04/amd64/turn/adduser_3.153ubuntu1_all.deb"]="78de3c5c3ec5657bcbdc10c2b2bcd9cedd78e6814182566f1522af422b26d3ce"
  ["apt/26.04/amd64/turn/coturn_4.6.1-2build2_amd64.deb"]="eef2144efb4dc872816506d798f97e69bd3dcaba1a3c64d84ee14f40e6cd7e4a"
  ["apt/26.04/amd64/turn/inetutils-telnet_2_2.7-2ubuntu1.1_amd64.deb"]="176bb3938b13bb885cf0cbe600b4d91f41f1638ade3e67416b310c77a70fe2bf"
  ["apt/26.04/amd64/turn/libevent-core-2.1-7t64_2.1.12-stable-10ubuntu0.2_amd64.deb"]="234686b4ff695c2a1c937282ef4e8e2e37abef8a064dfa8a6eaa365ab6a45400"
  ["apt/26.04/amd64/turn/libevent-extra-2.1-7t64_2.1.12-stable-10ubuntu0.2_amd64.deb"]="a20c1772dacf449cb100ce3e79aa7203f9431aeeec8e3c472cfa8783d34ad52c"
  ["apt/26.04/amd64/turn/libevent-openssl-2.1-7t64_2.1.12-stable-10ubuntu0.2_amd64.deb"]="d6936b7e34362743da215ce1218a8fd993db8cbed8411a24e2488b2aee4a411d"
  ["apt/26.04/amd64/turn/libevent-pthreads-2.1-7t64_2.1.12-stable-10ubuntu0.2_amd64.deb"]="a181c67e594c2c01524d00e39d922615d72feea59d810a34455f5c908b6253a9"
  ["apt/26.04/amd64/turn/libhiredis1.1.0_1.2.0-6ubuntu4_amd64.deb"]="d01417ced1b484e5a39903280e4d704b9399ad8dc574a7209eaa2292e570cbfe"
  ["apt/26.04/amd64/turn/libmysqlclient24_8.4.11-0ubuntu0.26.04.1_amd64.deb"]="d183043ad76ae04f823791993d36792abfa4f5e650013af9ad4520ea4312ea1a"
  ["apt/26.04/amd64/turn/libpq5_18.6-0ubuntu0.26.04.1_amd64.deb"]="7e9199f54290b04a28e9f136207624ca30b0988d613159977fd84e8b4467e0a4"
  ["apt/26.04/amd64/turn/libreadline8t64_8.3-4_amd64.deb"]="260b3333e9f714252593b83fb31d2571097b64d337d0d7100aae7349029821fc"
  ["apt/26.04/amd64/turn/libsqlite3-0_3.46.1-9ubuntu0.3_amd64.deb"]="ff4b5a1e7c028a4bcc30076e4d8197aad1a910df44f4dc8dcf253e9ee9a3a367"
  ["apt/26.04/amd64/turn/mysql-common_5.8+1.1.1ubuntu2_all.deb"]="81bbfdaa72e41f9e89800ede3c157382c30b3031d338085e326e069372640bf6"
  ["apt/26.04/amd64/turn/netbase_6.5build1_all.deb"]="f008e39aada379d64166153d5e37ccc4f18b3e334babb9e32c4da9b4396ee733"
  ["apt/26.04/amd64/turn/readline-common_8.3-4_all.deb"]="53cdc5a963bbdda938f8996496a5e78bcf484e6e41a2ef2c0f8cf566808f71f5"
  ["apt/26.04/amd64/turn/sqlite3_3.46.1-9ubuntu0.3_amd64.deb"]="e577fe01329894b3ade9a51787265985f7dc9eb8c8612657dd77353bdd55dc9a"
  ["apt/26.04/amd64/turn/telnet_0.17+2.7-2ubuntu1.1_all.deb"]="5bb2efaa1cf34dbbcc853404bfc64598d7e6e4c7ac783fd289742be156ced4f6"
  ["apt/26.04/arm64/turn/adduser_3.153ubuntu1_all.deb"]="78de3c5c3ec5657bcbdc10c2b2bcd9cedd78e6814182566f1522af422b26d3ce"
  ["apt/26.04/arm64/turn/coturn_4.6.1-2build2_arm64.deb"]="9c5427894529457ecd99986538d0f700837e3559264b2f33e73378a62a7fd906"
  ["apt/26.04/arm64/turn/inetutils-telnet_2_2.7-2ubuntu1.1_arm64.deb"]="9bc7f28bba37ead3e3ca4679ad609fc88f0b416980ca9eaedf5864050e6a2c4e"
  ["apt/26.04/arm64/turn/libevent-core-2.1-7t64_2.1.12-stable-10ubuntu0.2_arm64.deb"]="b592fc20f7db7e9ec4a3b1648a2c8cf43e87bb8656b23bbc82532b808d4b8a1b"
  ["apt/26.04/arm64/turn/libevent-extra-2.1-7t64_2.1.12-stable-10ubuntu0.2_arm64.deb"]="cce8fb61d2272b0099685dcfc3ab8c1a05f41e35c4c938ad6bf487ae9450ee24"
  ["apt/26.04/arm64/turn/libevent-openssl-2.1-7t64_2.1.12-stable-10ubuntu0.2_arm64.deb"]="8191b765aff725fa1a24785790b329eaa966356a2d6328bb87a0e2a5f0f0ab4c"
  ["apt/26.04/arm64/turn/libevent-pthreads-2.1-7t64_2.1.12-stable-10ubuntu0.2_arm64.deb"]="9120ca273e302e18f68dc81d0d3c4f33746d84c1a8afe36970df2ccc7fbce04e"
  ["apt/26.04/arm64/turn/libhiredis1.1.0_1.2.0-6ubuntu4_arm64.deb"]="8be1ed6eadfde675dd621bc651b2eae6807f391088ee6793210d7f21ec6930b6"
  ["apt/26.04/arm64/turn/libmysqlclient24_8.4.11-0ubuntu0.26.04.1_arm64.deb"]="f623848ceb10bdddb993f387e9935585816cd41067cdb61ca33773d3437bc3dd"
  ["apt/26.04/arm64/turn/libpq5_18.6-0ubuntu0.26.04.1_arm64.deb"]="36dd76e7d375e31fc427a3727772f7b9f1ff6a9389d4d704f1f4beafb2b7fe72"
  ["apt/26.04/arm64/turn/libreadline8t64_8.3-4_arm64.deb"]="743fbc80917aba8d9361e6305eeea92b08935f4403c6b4feb7ef3e195d1bf90f"
  ["apt/26.04/arm64/turn/libsqlite3-0_3.46.1-9ubuntu0.3_arm64.deb"]="c79eb1e82eeb3509af1a9792a5758ff3c4fed4b69bc8cd7c5871adafc30c19a9"
  ["apt/26.04/arm64/turn/mysql-common_5.8+1.1.1ubuntu2_all.deb"]="81bbfdaa72e41f9e89800ede3c157382c30b3031d338085e326e069372640bf6"
  ["apt/26.04/arm64/turn/netbase_6.5build1_all.deb"]="f008e39aada379d64166153d5e37ccc4f18b3e334babb9e32c4da9b4396ee733"
  ["apt/26.04/arm64/turn/readline-common_8.3-4_all.deb"]="53cdc5a963bbdda938f8996496a5e78bcf484e6e41a2ef2c0f8cf566808f71f5"
  ["apt/26.04/arm64/turn/sqlite3_3.46.1-9ubuntu0.3_arm64.deb"]="7dd311d9c20996bcbf52d97fc74b70c0c64c94f67a07dc4c4ddfdcd6ee09e781"
  ["apt/26.04/arm64/turn/telnet_0.17+2.7-2ubuntu1.1_all.deb"]="5bb2efaa1cf34dbbcc853404bfc64598d7e6e4c7ac783fd289742be156ced4f6"
  ["caddy/linux-amd64/caddy"]="678ade3bfc088749c81a681adc603333ee0bb023b6a6cfe3c0f58bef8ff854e9"
  ["caddy/linux-arm64/caddy"]="0019d864a2cdee41c3675cb2a26185833c5d9540a48f5a6729142c0413461b60"
  ["matrix/linux-amd64/matrix-runtime.tar.gz"]="d7268ff506394ea4b21aa0ff2c090fdc184032053a9f2460105b6a5b831ed7ac"
  ["matrix/linux-arm64/matrix-runtime.tar.gz"]="5b04ad3974810c736102c39e27dddec993d55074c1f59ca29af55bccd7f452d1"
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

ask_secret() {
    # ask_secret <VAR> <question>: keeps VAR when it is already set, otherwise asks twice on the terminal, hidden.
    local var="$1" question="$2" first="" second=""
    if [ -n "${!var:-}" ]; then
        return 0
    fi
    if [ "${NONINTERACTIVE:-0}" = 1 ] || [ ! -r /dev/tty ]; then
        return 0
    fi
    read -r -s -p "$question: " first </dev/tty || true
    echo >&2
    read -r -s -p "repeat it: " second </dev/tty || true
    echo >&2
    [ "$first" = "$second" ] || die "the two passwords do not match"
    printf -v "$var" '%s' "$first"
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
        echo "$1://$MATRIX_PUBLIC_HOST"
    else
        echo "$1://$MATRIX_PUBLIC_HOST:$2"
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
for tool in curl sha256sum systemctl ss awk openssl dpkg useradd; do
    command -v "$tool" >/dev/null 2>&1 || die "$tool is required"
done
[ ! -e "$INSTALL_DIR/python" ] || die "Matrix is already installed in $INSTALL_DIR; remove that directory to reinstall"

ask MATRIX_PUBLIC_HOST "host name or IP address that clients use" ""
[ -n "$MATRIX_PUBLIC_HOST" ] || die "MATRIX_PUBLIC_HOST is required"
[[ "$MATRIX_PUBLIC_HOST" =~ ^[A-Za-z0-9.-]+$ ]] || die "MATRIX_PUBLIC_HOST may contain only letters, digits, dots, and dashes"
ask MATRIX_TLS "TLS mode: internal (a CA made here), file (your certificate), or http (no TLS)" "internal"
case "$MATRIX_TLS" in
    internal) ;;
    file)
        ask MATRIX_TLS_CERT_FILE "path to the certificate file (PEM, with the full chain)" ""
        ask MATRIX_TLS_KEY_FILE "path to the private key file (PEM)" ""
        [ -r "$MATRIX_TLS_CERT_FILE" ] || die "cannot read the certificate file $MATRIX_TLS_CERT_FILE"
        [ -r "$MATRIX_TLS_KEY_FILE" ] || die "cannot read the key file $MATRIX_TLS_KEY_FILE"
        openssl x509 -in "$MATRIX_TLS_CERT_FILE" -noout >/dev/null 2>&1 || die "$MATRIX_TLS_CERT_FILE is not a certificate"
        openssl pkey -in "$MATRIX_TLS_KEY_FILE" -noout >/dev/null 2>&1 || die "$MATRIX_TLS_KEY_FILE is not a private key"
        [ "$(openssl x509 -in "$MATRIX_TLS_CERT_FILE" -noout -pubkey | openssl pkey -pubin -outform der | sha256sum)" = \
          "$(openssl pkey -in "$MATRIX_TLS_KEY_FILE" -pubout -outform der | sha256sum)" ] || die "the certificate and the key do not match"
        ;;
    http)
        echo "warning: HTTP only. The chat works, but browsers block calls on this address." >&2
        ;;
    *) die "MATRIX_TLS must be internal, file, or http" ;;
esac

if [ "$MATRIX_TLS" = http ]; then
    ask_port MATRIX_HTTP_PORT "HTTP port for the chat" "80"
    port_free "$MATRIX_HTTP_PORT" tcp
    BASE=$(url_for http "$MATRIX_HTTP_PORT")
else
    ask_port MATRIX_HTTPS_PORT "HTTPS port for the chat, Element and calls" "443"
    ask_port MATRIX_HTTP_PORT "HTTP port that redirects to HTTPS" "80"
    [ "$MATRIX_HTTPS_PORT" != "$MATRIX_HTTP_PORT" ] || die "the HTTPS and HTTP ports must differ"
    port_free "$MATRIX_HTTPS_PORT" tcp
    port_free "$MATRIX_HTTP_PORT" tcp
    BASE=$(url_for https "$MATRIX_HTTPS_PORT")
fi

ask_port MATRIX_TURN_PORT "TURN port for calls, UDP and TCP" "3478"
port_free "$MATRIX_TURN_PORT" tcp
port_free "$MATRIX_TURN_PORT" udp
ask MATRIX_RELAY_RANGE "UDP ports that coturn relays calls on (min-max)" "49152-65535"
[[ "$MATRIX_RELAY_RANGE" =~ ^([0-9]+)-([0-9]+)$ ]] || die "MATRIX_RELAY_RANGE must look like 49152-65535"
RELAY_MIN="${BASH_REMATCH[1]}"
RELAY_MAX="${BASH_REMATCH[2]}"
[ "$RELAY_MIN" -ge 1024 ] && [ "$RELAY_MAX" -le 65535 ] && [ "$RELAY_MIN" -lt "$RELAY_MAX" ] \
    || die "the relay range must lie inside 1024-65535, with the smaller number first"

ask MATRIX_REGISTRATION "registration: open (anyone can sign up) or closed" "open"
case "$MATRIX_REGISTRATION" in
    open|closed) ;;
    *) die "MATRIX_REGISTRATION must be open or closed" ;;
esac
ask MATRIX_ADMIN_USER "administrator username (empty: create none)" ""
if [ -n "$MATRIX_ADMIN_USER" ]; then
    [[ "$MATRIX_ADMIN_USER" =~ ^[a-z0-9._=/-]+$ ]] || die "the administrator username may use lowercase letters, digits, and . _ = / -"
    ask_secret MATRIX_ADMIN_PASSWORD "password for the administrator $MATRIX_ADMIN_USER (at least 8 characters)"
    admin_pw="${MATRIX_ADMIN_PASSWORD:-}"
    [ "${#admin_pw}" -ge 8 ] || die "the administrator password must have at least 8 characters"
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

log "creating the service user and the folders"
id "$SVC_USER" >/dev/null 2>&1 || useradd --system --home-dir "$DATA_DIR" --shell /usr/sbin/nologin "$SVC_USER"
install -d -m 0755 -o root -g root "$INSTALL_DIR" "$INSTALL_DIR/bin"
install -d -m 0750 -o "$SVC_USER" -g "$SVC_USER" "$DATA_DIR" "$DATA_DIR/caddy" "$DATA_DIR/tls"

log "fetching and unpacking the Matrix runtime (Python, Synapse, Element Web)"
mirror_fetch "matrix/linux-$ARCH/matrix-runtime.tar.gz" "$TMP/matrix-runtime.tar.gz"
tar -C "$INSTALL_DIR" -xzf "$TMP/matrix-runtime.tar.gz"
[ -x "$INSTALL_DIR/python/bin/python3" ] || die "the runtime has no Python"

log "fetching and checking Caddy for linux/$ARCH"
mirror_fetch "caddy/linux-$ARCH/caddy" "$TMP/caddy"
install -m 0755 -o root -g root "$TMP/caddy" "$INSTALL_DIR/bin/caddy"
"$INSTALL_DIR/bin/caddy" version >/dev/null || die "caddy does not run on this system"

log "installing coturn from the mirror"
mkdir -p "$TMP/debs"
debs=()
prefix="apt/$VERSION_ID/$ARCH/turn/"
for key in "${!MIRROR_SHA256[@]}"; do
    case "$key" in
        "$prefix"*)
            name="${key#"$prefix"}"
            mirror_fetch "$key" "$TMP/debs/$name"
            debs+=("$TMP/debs/$name")
            ;;
    esac
done
[ "${#debs[@]}" -gt 0 ] || die "this bundle has no coturn packages for Ubuntu $VERSION_ID $ARCH"
# dpkg checks dependencies in the order it unpacks, so a package can fail on one pass and succeed on the next.
for _ in 1 2 3; do
    if DEBIAN_FRONTEND=noninteractive dpkg -i --force-confold "${debs[@]}" >/dev/null 2>&1; then
        break
    fi
done
dpkg -s coturn 2>/dev/null | grep -q "Status: install ok installed" || die "coturn did not install"

TURN_SECRET=$(openssl rand -hex 32)

log "writing the Synapse configuration"
PY="$INSTALL_DIR/python/bin/python3"
rm -f "$DATA_DIR/homeserver.yaml"
# The log file that generate-config writes is relative to the working directory, so run it from the data directory.
(cd "$DATA_DIR" && "$PY" -m synapse.app.homeserver --server-name "$MATRIX_PUBLIC_HOST" --config-path "$DATA_DIR/homeserver.yaml" \
    --data-directory "$DATA_DIR" --generate-config --report-stats=no >/dev/null)
MATRIX_BASE="$BASE" MATRIX_HOST="$MATRIX_PUBLIC_HOST" TURN_SECRET="$TURN_SECRET" MATRIX_REG="$MATRIX_REGISTRATION" \
TURN_PORT="$MATRIX_TURN_PORT" \
"$PY" - "$DATA_DIR/homeserver.yaml" <<'PY'
import os
import sys

import yaml

path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    cfg = yaml.safe_load(f)
host = os.environ["MATRIX_HOST"]
turn_port = os.environ["TURN_PORT"]
# One listener, on loopback. Caddy receives the browsers' requests and passes them on.
cfg["listeners"] = [{
    "port": 8008,
    "bind_addresses": ["127.0.0.1"],
    "type": "http",
    "tls": False,
    "x_forwarded": True,
    "resources": [{"names": ["client"], "compress": False}],
}]
cfg["public_baseurl"] = os.environ["MATRIX_BASE"] + "/"
cfg["enable_registration"] = os.environ["MATRIX_REG"] == "open"
cfg["enable_registration_without_verification"] = True
cfg["report_stats"] = False
# The TURN settings let Synapse hand every user short-lived credentials for the coturn server.
cfg["turn_uris"] = ["turn:%s:%s?transport=udp" % (host, turn_port), "turn:%s:%s?transport=tcp" % (host, turn_port)]
cfg["turn_shared_secret"] = os.environ["TURN_SECRET"]
cfg["turn_user_lifetime"] = "1d"
cfg["max_upload_size"] = "50M"
with open(path, "w", encoding="utf-8") as f:
    yaml.safe_dump(cfg, f, sort_keys=False)
PY
# generate-config ran as root, so it made the signing key and the log config; the service user must own them.
chown -R "$SVC_USER:$SVC_USER" "$DATA_DIR"
chmod 0640 "$DATA_DIR/homeserver.yaml"

if [ "$MATRIX_TLS" = file ]; then
    install -m 0644 -o "$SVC_USER" -g "$SVC_USER" "$MATRIX_TLS_CERT_FILE" "$DATA_DIR/tls/server.crt"
    install -m 0600 -o "$SVC_USER" -g "$SVC_USER" "$MATRIX_TLS_KEY_FILE" "$DATA_DIR/tls/server.key"
fi

log "writing the Element Web settings and the Caddy configuration"
cat > "$INSTALL_DIR/element/config.json" <<JSON
{
  "default_server_config": {
    "m.homeserver": {
      "base_url": "$BASE",
      "server_name": "$MATRIX_PUBLIC_HOST"
    }
  },
  "disable_guests": true,
  "brand": "Element"
}
JSON
case "$MATRIX_TLS" in
    internal) SITE="$BASE"; TLS_LINE="tls internal" ;;
    file) SITE="$BASE"; TLS_LINE="tls $DATA_DIR/tls/server.crt $DATA_DIR/tls/server.key" ;;
    http) SITE="$BASE"; TLS_LINE="" ;;
esac
# Clients that connect to an IP address send no SNI, so Caddy needs a default name to choose the certificate.
DEFAULT_SNI=""
HTTP_PORT_LINE=""
if [ "$MATRIX_TLS" != http ]; then
    DEFAULT_SNI="	default_sni $MATRIX_PUBLIC_HOST"
    HTTP_PORT_LINE="	http_port $MATRIX_HTTP_PORT"
fi
cat > "$INSTALL_DIR/Caddyfile" <<CADDY
{
	admin off
$DEFAULT_SNI
$HTTP_PORT_LINE
}

$SITE {
	$TLS_LINE
	encode zstd gzip
	header X-Content-Type-Options nosniff
	handle /_matrix/* {
		reverse_proxy 127.0.0.1:8008
	}
	handle /_synapse/* {
		reverse_proxy 127.0.0.1:8008
	}
	handle {
		root * $INSTALL_DIR/element
		try_files {path} /index.html
		file_server
	}
}
CADDY

log "configuring coturn"
cat > /etc/turnserver.conf <<TURN
# Written by the Matrix installer. Synapse signs short-lived credentials with the same shared secret.
listening-ip=0.0.0.0
listening-port=$MATRIX_TURN_PORT
realm=$MATRIX_PUBLIC_HOST
use-auth-secret
static-auth-secret=$TURN_SECRET
no-tls
no-dtls
no-cli
no-tlsv1
no-tlsv1_1
fingerprint
min-port=$RELAY_MIN
max-port=$RELAY_MAX
TURN
if [ -f /etc/default/coturn ]; then
    sed -i 's/^#*TURNSERVER_ENABLED=.*/TURNSERVER_ENABLED=1/' /etc/default/coturn
else
    echo "TURNSERVER_ENABLED=1" > /etc/default/coturn
fi

log "installing the systemd services"
cat >/etc/systemd/system/matrix-synapse.service <<UNIT
[Unit]
Description=Matrix Synapse homeserver
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$SVC_USER
Group=$SVC_USER
WorkingDirectory=$DATA_DIR
ExecStart=$INSTALL_DIR/python/bin/python3 -m synapse.app.homeserver --config-path $DATA_DIR/homeserver.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
cat >/etc/systemd/system/matrix-caddy.service <<UNIT
[Unit]
Description=Caddy for the Matrix server (HTTPS and Element Web)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$SVC_USER
Group=$SVC_USER
Environment=XDG_DATA_HOME=$DATA_DIR/caddy XDG_CONFIG_HOME=$DATA_DIR/caddy/config
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
ExecStart=$INSTALL_DIR/bin/caddy run --config $INSTALL_DIR/Caddyfile --adapter caddyfile
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now matrix-synapse.service matrix-caddy.service
systemctl enable coturn.service >/dev/null 2>&1 || true
systemctl restart coturn.service

log "waiting for the Matrix API (the first start creates the database)"
if [ "$MATRIX_TLS" = http ]; then WEB_PORT="$MATRIX_HTTP_PORT"; else WEB_PORT="$MATRIX_HTTPS_PORT"; fi
ready=no
for _ in $(seq 1 180); do
    if curl -fsSk --resolve "$MATRIX_PUBLIC_HOST:$WEB_PORT:127.0.0.1" "$BASE/_matrix/client/versions" >/dev/null 2>&1; then
        ready=yes
        break
    fi
    sleep 2
done
[ "$ready" = yes ] || die "the Matrix API did not answer at $BASE; check: journalctl -u matrix-synapse -u matrix-caddy"

ADMIN_NOTE=""
if [ -n "$MATRIX_ADMIN_USER" ]; then
    log "creating the administrator $MATRIX_ADMIN_USER"
    if "$INSTALL_DIR/python/bin/register_new_matrix_user" -c "$DATA_DIR/homeserver.yaml" \
        -u "$MATRIX_ADMIN_USER" -p "$MATRIX_ADMIN_PASSWORD" -a >/dev/null 2>&1; then
        ADMIN_NOTE="Administrator: $MATRIX_ADMIN_USER (the server name is $MATRIX_PUBLIC_HOST)"
    else
        echo "warning: the administrator account was not created (it may already exist)" >&2
    fi
fi

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    log "opening the web, TURN and relay ports in ufw"
    if [ "$MATRIX_TLS" = http ]; then
        ufw allow "$MATRIX_HTTP_PORT/tcp" >/dev/null
    else
        ufw allow "$MATRIX_HTTPS_PORT/tcp" >/dev/null
        ufw allow "$MATRIX_HTTP_PORT/tcp" >/dev/null
    fi
    ufw allow "$MATRIX_TURN_PORT" >/dev/null
    ufw allow "$RELAY_MIN:$RELAY_MAX/udp" >/dev/null
fi

cat <<DONE

Matrix is running at $BASE
Element Web (chat on any device with a browser): $BASE/
Registration: $MATRIX_REGISTRATION
${ADMIN_NOTE}
Calls relay through coturn on port $MATRIX_TURN_PORT (UDP and TCP) and the relay range $RELAY_MIN-$RELAY_MAX (UDP).
DONE
if [ "$MATRIX_TLS" = internal ]; then
    echo "Browsers and apps must trust the local CA certificate: $DATA_DIR/caddy/caddy/pki/authorities/local/root.crt"
fi
if [ "$MATRIX_TLS" = http ]; then
    echo "HTTP only: the chat works, but browsers block calls on this address."
fi
echo "Logs: journalctl -u matrix-synapse -u matrix-caddy -u coturn"
