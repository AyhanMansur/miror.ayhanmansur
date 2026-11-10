#!/usr/bin/env bash
# Installs the PasarGuard panel on Ubuntu 22.04, 24.04, or 26.04 from an offline mirror. The panel runs as the
# pasarguard/panel Docker container, and the Docker engine is installed from the mirror too. The database is
# SQLite. Every download is checked against the sha256 value in this script.
#
# The installer asks for each value when a terminal is attached. A value that is already set in the
# environment is not asked for:
#   PANEL_HOST            host name or IP address that browsers use (required; the certificate is made for it)
#   PANEL_TLS             internal (default: a CA made here), file (your certificate), or http (no TLS)
#   PANEL_TLS_CERT_FILE   PEM certificate with the full chain (PANEL_TLS=file)
#   PANEL_TLS_KEY_FILE    PEM private key (PANEL_TLS=file)
#   PANEL_SSL_CA_TYPE     public (a certificate from a public CA) or private (self-signed or internal); PANEL_TLS=file
#   PANEL_PORT            port for the panel (default 8000)
#   PANEL_ADMIN_USER      administrator username (required)
#   PANEL_ADMIN_PASSWORD  its password, asked twice and hidden (at least 8 characters)
#   NONINTERACTIVE=1      never prompt; values that are not set take their defaults
set -euo pipefail
# The files this script writes must be readable by the containers, whatever the caller's umask.
umask 022

INSTALL_DIR=/opt/pasarguard
DATA_DIR=/var/lib/pasarguard
PANEL_TAG="v5.4.1"
PANEL_IMAGE="pasarguard/panel:$PANEL_TAG"
POSTGRES_IMAGE="postgres:17.11"
TIMESCALEDB_IMAGE="timescale/timescaledb:2.30.2-pg17"
MYSQL_IMAGE="mysql:8.4.11"
MARIADB_IMAGE="mariadb:11.8.9"
PGBOUNCER_IMAGE="edoburu/pgbouncer:v1.26.1-p0"
MIRROR_FILES="http://188.213.67.196:8080/files"
declare -A MIRROR_SHA256=(
  ["apt/22.04/amd64/docker/containerd_2.2.1-0ubuntu1~22.04.2_amd64.deb"]="08e309f0fb8ae6f798dc80e54f10e152c8dad6ee16ca6627805382fbb56cb5f1"
  ["apt/22.04/amd64/docker/docker-compose-v2_2.40.3+ds1-0ubuntu1~22.04.1_amd64.deb"]="9f57bd34ecc356030dc447521411e334a956f2be318e4d5f99b914e4e3595d11"
  ["apt/22.04/amd64/docker/docker.io_29.1.3-0ubuntu3~22.04.2_amd64.deb"]="e2336d2596d18d6e1ae0cb80ae569a86019674b1b995c40a0c734be8081f275e"
  ["apt/22.04/amd64/docker/iptables_1.8.7-1ubuntu5.2_amd64.deb"]="a14fe8043d9032bc134626e64a9d008ab77d63ebb17d4a37f1f1f7c64c76792d"
  ["apt/22.04/amd64/docker/libip4tc2_1.8.7-1ubuntu5.2_amd64.deb"]="4553f8a7089312da5e8ffcae9db70c0ff54858d23e6892db7bfcaac2449d235d"
  ["apt/22.04/amd64/docker/libip6tc2_1.8.7-1ubuntu5.2_amd64.deb"]="76cdfc9065400fa58b233957691ee31e278ae20ed555f8f9e0329d4123b62153"
  ["apt/22.04/amd64/docker/libjansson4_2.13.1-1.1build3_amd64.deb"]="4af5e5f18d6a5a701ecad452449494a21004307cac18b9369e26345986de5d4d"
  ["apt/22.04/amd64/docker/libmnl0_1.0.4-3build2_amd64.deb"]="e0ed2e88526830896a9efcef75a3d019b40cdac5a56d6605c426296979708f4a"
  ["apt/22.04/amd64/docker/libnetfilter-conntrack3_1.0.9-1_amd64.deb"]="49a31bd83385cfcb630194b9bcf119af681f08a65c86a437423e344e6b4bc806"
  ["apt/22.04/amd64/docker/libnfnetlink0_1.0.1-3build3_amd64.deb"]="9c7b2e9fa8f60bd1d0a85d5082cdec10ec1aa7be3ad8c0e4265c28cc8e72ec9a"
  ["apt/22.04/amd64/docker/libnftables1_1.0.2-1ubuntu3.1_amd64.deb"]="c23880032dcf0a6f7afd12c599230d226240ff829153cc2e5b4b09ce7f6080b3"
  ["apt/22.04/amd64/docker/libnftnl11_1.2.1-1build1_amd64.deb"]="a2c19952be8ca65e3464773009490701a0a49e1ef984d9140158371f909f2606"
  ["apt/22.04/amd64/docker/libxtables12_1.8.7-1ubuntu5.2_amd64.deb"]="c2e99be5d2f06ce776883c3d11dbe58f1c735e2ad9acd9ea2faa584829eddb16"
  ["apt/22.04/amd64/docker/netbase_6.3_all.deb"]="480bbd894069e5da7a25f070ea0ebaded7f64bdd34a119558cc2fe7137762a79"
  ["apt/22.04/amd64/docker/runc_1.3.4-0ubuntu1~22.04.1_amd64.deb"]="1551d41d027969e141805f9687adcba746c332fa64e3c7ceb9261f842a33ff31"
  ["apt/22.04/arm64/docker/containerd_2.2.1-0ubuntu1~22.04.2_arm64.deb"]="3e839948d49a7d3952c42730a72b9863ed6b9f5de0854e766a8997f590be7361"
  ["apt/22.04/arm64/docker/docker-compose-v2_2.40.3+ds1-0ubuntu1~22.04.1_arm64.deb"]="914f90262b19e9367838f4516868f96921bcce6c93f82a4ba3e86441ebe3e329"
  ["apt/22.04/arm64/docker/docker.io_29.1.3-0ubuntu3~22.04.2_arm64.deb"]="ee6547e7b281ba747803680b10423b961781bbf8c6795ebe594eb8fd2f6f714b"
  ["apt/22.04/arm64/docker/iptables_1.8.7-1ubuntu5.2_arm64.deb"]="9d88e2931ea8c7d2d566e0f5c97f28af95c5e84a620ceeecb574bb9661ed8f99"
  ["apt/22.04/arm64/docker/libip4tc2_1.8.7-1ubuntu5.2_arm64.deb"]="7cd2c4ada6fab830b421a83ea90edda2b4cd257f169062338618828d56875654"
  ["apt/22.04/arm64/docker/libip6tc2_1.8.7-1ubuntu5.2_arm64.deb"]="d9af8651dd6f2017a822ab469680b05a03457376ba70222e6633c4652be3b112"
  ["apt/22.04/arm64/docker/libjansson4_2.13.1-1.1build3_arm64.deb"]="ad820b78a6f23a4a444b8bb97987c419949e9db6e1c01a7408f61e292ecff793"
  ["apt/22.04/arm64/docker/libmnl0_1.0.4-3build2_arm64.deb"]="225e80ab05283fca43a3d6c717d33f92703893c4fb725a3c4c6c6ced536c31e2"
  ["apt/22.04/arm64/docker/libnetfilter-conntrack3_1.0.9-1_arm64.deb"]="a10d7730122adc40ad41ca9f4aed3c30506e9fc2e67b537536ebeef9264b68f2"
  ["apt/22.04/arm64/docker/libnfnetlink0_1.0.1-3build3_arm64.deb"]="5bc00880ab301fef48bebdfd4435c7e4ef40364175fa035f936aeebe2b3c2b86"
  ["apt/22.04/arm64/docker/libnftables1_1.0.2-1ubuntu3.1_arm64.deb"]="5b84096b3bd3e43f26fde4c7623b9497d1e7b1be84f3ba145ca81b0d2e363664"
  ["apt/22.04/arm64/docker/libnftnl11_1.2.1-1build1_arm64.deb"]="9335b6383d301b952a1a5aa5e39c77159d6451106d54bb8f37eb2e4931a0b35b"
  ["apt/22.04/arm64/docker/libxtables12_1.8.7-1ubuntu5.2_arm64.deb"]="1e224fa12afd5bf4c8b5afe1803c6af04fd296ecd081fdd6a2df0e8dbe2027e1"
  ["apt/22.04/arm64/docker/netbase_6.3_all.deb"]="480bbd894069e5da7a25f070ea0ebaded7f64bdd34a119558cc2fe7137762a79"
  ["apt/22.04/arm64/docker/runc_1.3.4-0ubuntu1~22.04.1_arm64.deb"]="dfbc7e3f9fe4f3e4dcc93e36c8974e9fa80685541f64720648bb6ba275bb9adc"
  ["apt/24.04/amd64/docker/adduser_3.137ubuntu1_all.deb"]="542aff2395eb912a56833e11a78076342779689d8fede7adcf08d1d6b0d0cd8b"
  ["apt/24.04/amd64/docker/containerd_2.2.1-0ubuntu1~24.04.3_amd64.deb"]="459a0184cc631c17eb4a625392f749fa753627b4ddba196919e0666a6206d92a"
  ["apt/24.04/amd64/docker/docker-compose-v2_2.40.3+ds1-0ubuntu1~24.04.1_amd64.deb"]="192f3df16d0c832e1cbf2362889da56522267835cfb19541241b3dd0ed964039"
  ["apt/24.04/amd64/docker/docker.io_29.1.3-0ubuntu3~24.04.2_amd64.deb"]="bd5c22d42d4ce3021958b7a8d627701597f61a1a9867ba83fe3c841f04991e3a"
  ["apt/24.04/amd64/docker/iptables_1.8.10-3ubuntu2_amd64.deb"]="d341e8ffc42ca035f5aa0fd9a798c8d2b2edb019225dc11f4dac16edf9c57840"
  ["apt/24.04/amd64/docker/libip4tc2_1.8.10-3ubuntu2_amd64.deb"]="eb381f8ff0469534df3f1b146c3eb8baa6e36f8cfcdf2e3e039398322930d0a4"
  ["apt/24.04/amd64/docker/libip6tc2_1.8.10-3ubuntu2_amd64.deb"]="b98b88eb6aa14a902ea1aebc3b12ddd140572545ae1fc6428cb0868c31671d05"
  ["apt/24.04/amd64/docker/libjansson4_2.14-2build2_amd64.deb"]="0cf79113f5d193ce9af2be2ff4b2c3b30dd4e55a0b6c47f7d28f6c849ff3aa60"
  ["apt/24.04/amd64/docker/libmnl0_1.0.5-2build1_amd64.deb"]="5170658bf0eaf54a8c7d53061ca6b47a6cf33a83543a75fa521de7046cb7197a"
  ["apt/24.04/amd64/docker/libnetfilter-conntrack3_1.0.9-6build1_amd64.deb"]="6d32a4c4618eb7d6c0d989591d28637a9acdfa86dfe22e42e9ac9cc25d882a97"
  ["apt/24.04/amd64/docker/libnfnetlink0_1.0.2-2build1_amd64.deb"]="f557a287af2ca00df5dbf632c6b77d77479139ffb51c83e3de9766eb609b5d63"
  ["apt/24.04/amd64/docker/libnftables1_1.0.9-1ubuntu0.1_amd64.deb"]="fcaee001747a6adaa0cd9337fef437b3aa7a7a6d5246b62fbd4784d3d6a5009e"
  ["apt/24.04/amd64/docker/libnftnl11_1.2.6-2build1_amd64.deb"]="e5bde5c9cbb95082700011f0b7ef2c0a41900b0a9fd7434f6e90448e2a7b4e50"
  ["apt/24.04/amd64/docker/libxtables12_1.8.10-3ubuntu2_amd64.deb"]="c94063499d1b0b336f39607107efb7de95d52a5d4e7e6a9368a5f7308f05b714"
  ["apt/24.04/amd64/docker/netbase_6.4_all.deb"]="8cdbc9c3dca01e660759bf9d840f72e45ac72faf5d19ca1faecacaf6a60c1a87"
  ["apt/24.04/amd64/docker/runc_1.3.4-0ubuntu1~24.04.1_amd64.deb"]="6ddd64ed7ef1693dd95620a2b1148a4187ef4fe0819c3c3049fad9385ecfd5dc"
  ["apt/24.04/arm64/docker/adduser_3.137ubuntu1_all.deb"]="542aff2395eb912a56833e11a78076342779689d8fede7adcf08d1d6b0d0cd8b"
  ["apt/24.04/arm64/docker/containerd_2.2.1-0ubuntu1~24.04.3_arm64.deb"]="e12495f100f025750ca91c07bab3a58c674afb1576fe55516608a8daa4d067bd"
  ["apt/24.04/arm64/docker/docker-compose-v2_2.40.3+ds1-0ubuntu1~24.04.1_arm64.deb"]="65d112c150fa212d9fb58890a2009a5d91de567450cc81b4a99da114c7c347fd"
  ["apt/24.04/arm64/docker/docker.io_29.1.3-0ubuntu3~24.04.2_arm64.deb"]="fb0b4f8f4738d3d610b511f50808abd49376ee715a81364e7dbd8a2c60c580d6"
  ["apt/24.04/arm64/docker/iptables_1.8.10-3ubuntu2_arm64.deb"]="cbaacdb34f19a9b29f569205cdbf1e5851f63fde60777c5cf539a2b46c0c2fc7"
  ["apt/24.04/arm64/docker/libip4tc2_1.8.10-3ubuntu2_arm64.deb"]="e692da5dffee228ed346474a6e9e21511acbb7329bc304b4ae6dbbc25b2831a2"
  ["apt/24.04/arm64/docker/libip6tc2_1.8.10-3ubuntu2_arm64.deb"]="4438956b281410ee6d58ce59d1f9588e30f4abf7167e110fdb4f26a99fa5dee7"
  ["apt/24.04/arm64/docker/libjansson4_2.14-2build2_arm64.deb"]="a9d513eae76f4efb1c7370413bd21634fcfc0955e103d26af95f298af6c90abd"
  ["apt/24.04/arm64/docker/libmnl0_1.0.5-2build1_arm64.deb"]="9442f15a4bbc6148e527045adaf85c86ae3ffe159176d6a5f3b471b49150e470"
  ["apt/24.04/arm64/docker/libnetfilter-conntrack3_1.0.9-6build1_arm64.deb"]="7b152f919dbd3ffd9ca3ac95d96fdac0cdd139656eb284a0abbc46fce6063301"
  ["apt/24.04/arm64/docker/libnfnetlink0_1.0.2-2build1_arm64.deb"]="c7c64d90793ce4d7df262aad50d99eb45ca848fa9421f1bccb22665c350bdb2f"
  ["apt/24.04/arm64/docker/libnftables1_1.0.9-1ubuntu0.1_arm64.deb"]="69f16c2f161ddfd196a00d7dbcf52a25821a5eadcca07a8ddd03f05dede148d0"
  ["apt/24.04/arm64/docker/libnftnl11_1.2.6-2build1_arm64.deb"]="678792e1aa102892b594e0ee13ee93b763011674bddba800a3974a68a83c6ed1"
  ["apt/24.04/arm64/docker/libxtables12_1.8.10-3ubuntu2_arm64.deb"]="72cd6add0f8eaaa45f44dd5c0903df083ab3847091d0633b4e46e8f80443718a"
  ["apt/24.04/arm64/docker/netbase_6.4_all.deb"]="8cdbc9c3dca01e660759bf9d840f72e45ac72faf5d19ca1faecacaf6a60c1a87"
  ["apt/24.04/arm64/docker/runc_1.3.4-0ubuntu1~24.04.1_arm64.deb"]="725a27bbdd5f58d7059ed25d88f14f2d45f6a1ce089585eddc715e04d4a3f79f"
  ["apt/26.04/amd64/docker/adduser_3.153ubuntu1_all.deb"]="78de3c5c3ec5657bcbdc10c2b2bcd9cedd78e6814182566f1522af422b26d3ce"
  ["apt/26.04/amd64/docker/containerd_2.2.2-0ubuntu1.1_amd64.deb"]="25f1410e781533bf19d22aa9181c6b57043c005cc30b635edf8a2afebe590fc0"
  ["apt/26.04/amd64/docker/docker-compose-v2_2.40.3+ds1-0ubuntu1_amd64.deb"]="fb8bbea5614c65cbdf426a7fd13bfeaf0f777a8f4d62758fbbfa4f051be330da"
  ["apt/26.04/amd64/docker/docker.io_29.1.3-0ubuntu4.1_amd64.deb"]="7a77548bd669f232ec8852092623303be32c55538401ff047b4d1e0bb5ea721d"
  ["apt/26.04/amd64/docker/iptables_1.8.11-2ubuntu3_amd64.deb"]="187b16f9375f53ce6a1618a29de52bb177b620589ada29e4a3e25de5d594e66f"
  ["apt/26.04/amd64/docker/libip4tc2_1.8.11-2ubuntu3_amd64.deb"]="be25148d60125f6866dfa7940f3f1371fff4b0e8a1a9500780ad50cb8aaa0895"
  ["apt/26.04/amd64/docker/libip6tc2_1.8.11-2ubuntu3_amd64.deb"]="3d9fdb3171f1167ab3f5182de11db63bcd27aae71838618f3d46806b3134428e"
  ["apt/26.04/amd64/docker/libjansson4_2.14-2build4_amd64.deb"]="1dc986ac3cf112384919d1a339a952e8a86bede9890a4489c016fdc266a036ca"
  ["apt/26.04/amd64/docker/libmnl0_1.0.5-3build1_amd64.deb"]="ab5e2781b0e2a2155cf154c658a2e6cf419d95a28c3121aefb159df6453102e5"
  ["apt/26.04/amd64/docker/libnetfilter-conntrack3_1.1.1-1_amd64.deb"]="facfd45a7cf6bab8ef30adbe693d6486f22e5253263f9d53b4e70b53f768970e"
  ["apt/26.04/amd64/docker/libnfnetlink0_1.0.2-3build1_amd64.deb"]="e76b638fef2c1ebf78260972a52c4716df5752b29a952aeddc0c091a74f179c2"
  ["apt/26.04/amd64/docker/libnftables1_1.1.6-1_amd64.deb"]="0e5abb5719052d9f12aadf91a3f3d5192a2e85d035ee81d07c3055a0f79d8b8f"
  ["apt/26.04/amd64/docker/libnftnl11_1.3.1-1_amd64.deb"]="a2f4d4a4ce3fac7e473c8de60a3d8948a58e9850cd8e2ced17263aa73dda7199"
  ["apt/26.04/amd64/docker/libxtables12_1.8.11-2ubuntu3_amd64.deb"]="e21126e0544e3b795633fb5b06bb7f2b9a493ebc5ab07b007db0f7f68c0a0aed"
  ["apt/26.04/amd64/docker/netbase_6.5build1_all.deb"]="f008e39aada379d64166153d5e37ccc4f18b3e334babb9e32c4da9b4396ee733"
  ["apt/26.04/amd64/docker/runc_1.4.0-0ubuntu1_amd64.deb"]="7282e0d92acb54eefb57f84849ab8b0102fdc5a64459a95194101718b283ceff"
  ["apt/26.04/arm64/docker/adduser_3.153ubuntu1_all.deb"]="78de3c5c3ec5657bcbdc10c2b2bcd9cedd78e6814182566f1522af422b26d3ce"
  ["apt/26.04/arm64/docker/containerd_2.2.2-0ubuntu1.1_arm64.deb"]="28b1fb480b71110d6b7de3ec9768b529f0056e564061cbb39a56bca840f4301f"
  ["apt/26.04/arm64/docker/docker-compose-v2_2.40.3+ds1-0ubuntu1_arm64.deb"]="17d4e94e9387d8276df43e9031f933aed825234c14c2d815c29a4a4ec11f543e"
  ["apt/26.04/arm64/docker/docker.io_29.1.3-0ubuntu4.1_arm64.deb"]="bbae502879eff3c76fdccc3e5fb850298fe3ea328cec74be4923d7a78b288c46"
  ["apt/26.04/arm64/docker/iptables_1.8.11-2ubuntu3_arm64.deb"]="9bd09e64fe6ddb0a1c4b8a79becdc02ef17655c3cfd5cc750c0523a8e5044681"
  ["apt/26.04/arm64/docker/libip4tc2_1.8.11-2ubuntu3_arm64.deb"]="59dce7c6db3edc1b60ef61730932470d9906e03249d837c0a18e6f75e9bb0912"
  ["apt/26.04/arm64/docker/libip6tc2_1.8.11-2ubuntu3_arm64.deb"]="af9da146906c2685304e4fd14c74a026204a712284a81e310c439aa91a5a5b9d"
  ["apt/26.04/arm64/docker/libjansson4_2.14-2build4_arm64.deb"]="ac36a808bb47c2f21337c131b5ae2510ced2efdcfe8a471073d335f4e9ad5098"
  ["apt/26.04/arm64/docker/libmnl0_1.0.5-3build1_arm64.deb"]="323031cd4c6d38d1473d9b2314785688d88cf216d941e2f5a0073a66a6dfc567"
  ["apt/26.04/arm64/docker/libnetfilter-conntrack3_1.1.1-1_arm64.deb"]="8f911d2b9d3f303159f22283979804a83a733d9438cb99a108ab92500287257b"
  ["apt/26.04/arm64/docker/libnfnetlink0_1.0.2-3build1_arm64.deb"]="2a10983ed6ecdb688ab95ed8e39424f68e4c291596b5841330a9d5e95295c492"
  ["apt/26.04/arm64/docker/libnftables1_1.1.6-1_arm64.deb"]="9c2756281092b2152b6caeef08262568b1c191f6234e893668a72d9a14c2d690"
  ["apt/26.04/arm64/docker/libnftnl11_1.3.1-1_arm64.deb"]="e4a5df487f49cd366f1d9c25b540fe0a44edfc2d7d468bb827da7f683efa1618"
  ["apt/26.04/arm64/docker/libxtables12_1.8.11-2ubuntu3_arm64.deb"]="c4ff09c24441448755d774f48f4e422a58efb516f6c3805dd59177f5eb06d492"
  ["apt/26.04/arm64/docker/netbase_6.5build1_all.deb"]="f008e39aada379d64166153d5e37ccc4f18b3e334babb9e32c4da9b4396ee733"
  ["apt/26.04/arm64/docker/runc_1.4.0-0ubuntu1_arm64.deb"]="5a89a8b31dbc92ab0c977ac3348ee9fe7a7c884d0ec5b81912d9901d8d898661"
  ["pasarguard/db/linux-amd64/edoburu_pgbouncer-v1.26.1-p0.tar.gz"]="f93d5a78370a17167a1940eb4abb4a8f1f6c26e638e15764a23fd4482b5a001c"
  ["pasarguard/db/linux-amd64/mariadb-11.8.9.tar.gz"]="942ac2f87b395ab0264c844cb693aecb8ec7c5436b3540510de36372716dbead"
  ["pasarguard/db/linux-amd64/mysql-8.4.11.tar.gz"]="c457b07aede251d8db239fca7c875f08076b9dba753791bd564adceb308e7a78"
  ["pasarguard/db/linux-amd64/postgres-17.11.tar.gz"]="b4fb48a4f751f479c1ea1b9a44cadc9539c2ed0c3b1af50043c3a369b02a69b0"
  ["pasarguard/db/linux-amd64/timescale_timescaledb-2.30.2-pg17.tar.gz"]="7c65668bac8bbc7f05851f9f4ba8eed87425d5730443f7c239c2a3f37309efbb"
  ["pasarguard/linux-amd64/node-v0.5.4.tar.gz"]="5d9ce78c5f7a620886bc1e5b1fec84b6a8150a6efd793a59b3ba2b4a75e04a35"
  ["pasarguard/linux-amd64/panel-v5.4.1.tar.gz"]="11162c789760eaa537e0a1b10d33e66a25cfb7de0ad67a74f5e9fd7cef6c4bcd"
  ["pasarguard/linux-arm64/node-v0.5.4.tar.gz"]="f3cfda05158f84c4077d0565d20d3554f379bd1bfe01be5e88ca93d3b6de31a6"
  ["pasarguard/linux-arm64/panel-v5.4.1.tar.gz"]="51cea96badb830130e0c084b4da65c0c4aaabe07553b3858f29c16695800639e"
)

die() { echo "error: $*" >&2; exit 1; }
log() { echo "==> $*"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

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
    # ask_secret <VAR> <question>: keeps VAR when it is set, otherwise asks twice on the terminal, hidden.
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
    # port_free <port>: stops when another program already listens on that TCP port.
    ss -ltnH "sport = :$1" | grep -q . && die "TCP port $1 is already in use"
    return 0
}

detect_ipv4() {
    hostname -I 2>/dev/null | tr ' ' '\n' | grep -v ':' | grep . | head -n 1 || true
}

env_value() {
    # env_value <text>: writes the text as a quoted value for the .env file, escaping quotes and backslashes.
    local v="$1"
    v="${v//\\/\\\\}"
    v="${v//\"/\\\"}"
    printf '"%s"' "$v"
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
for tool in curl sha256sum systemctl ss awk openssl gunzip useradd; do
    command -v "$tool" >/dev/null 2>&1 || die "$tool is required"
done
[ ! -e "$INSTALL_DIR/docker-compose.yml" ] || die "the PasarGuard panel is already installed in $INSTALL_DIR; remove that directory to reinstall"

ask PANEL_HOST "host name or IP address that browsers use" "$(detect_ipv4)"
[ -n "$PANEL_HOST" ] || die "PANEL_HOST is required"
[[ "$PANEL_HOST" =~ ^[A-Za-z0-9.-]+$ ]] || die "PANEL_HOST may contain only letters, digits, dots, and dashes"
ask PANEL_TLS "TLS mode: internal (a CA made here), file (your certificate), or http (no TLS)" "internal"
case "$PANEL_TLS" in
    internal) PANEL_SSL_CA_TYPE=private ;;
    file)
        ask PANEL_TLS_CERT_FILE "path to the certificate file (PEM, with the full chain)" ""
        ask PANEL_TLS_KEY_FILE "path to the private key file (PEM)" ""
        ask PANEL_SSL_CA_TYPE "certificate type: public (from a public CA) or private (self-signed or internal)" "public"
        [ -r "$PANEL_TLS_CERT_FILE" ] || die "cannot read the certificate file $PANEL_TLS_CERT_FILE"
        [ -r "$PANEL_TLS_KEY_FILE" ] || die "cannot read the key file $PANEL_TLS_KEY_FILE"
        openssl x509 -in "$PANEL_TLS_CERT_FILE" -noout >/dev/null 2>&1 || die "$PANEL_TLS_CERT_FILE is not a certificate"
        openssl pkey -in "$PANEL_TLS_KEY_FILE" -noout >/dev/null 2>&1 || die "$PANEL_TLS_KEY_FILE is not a private key"
        [ "$(openssl x509 -in "$PANEL_TLS_CERT_FILE" -noout -pubkey | openssl pkey -pubin -outform der | sha256sum)" = \
          "$(openssl pkey -in "$PANEL_TLS_KEY_FILE" -pubout -outform der | sha256sum)" ] || die "the certificate and the key do not match"
        [ "$PANEL_SSL_CA_TYPE" = public ] || [ "$PANEL_SSL_CA_TYPE" = private ] || die "PANEL_SSL_CA_TYPE must be public or private"
        ;;
    http)
        echo "warning: HTTP only. Browsers block the microphone and camera on this address; the panel login is not encrypted." >&2
        ;;
    *) die "PANEL_TLS must be internal, file, or http" ;;
esac
ask_port PANEL_PORT "port for the panel" "8000"
port_free "$PANEL_PORT"
if [ "$PANEL_TLS" = http ]; then
    PANEL_URL="http://$PANEL_HOST:$PANEL_PORT"
else
    PANEL_URL="https://$PANEL_HOST:$PANEL_PORT"
fi
ask PANEL_DATABASE "database: sqlite (default), postgresql, timescaledb, mysql, or mariadb" "sqlite"
case "$PANEL_DATABASE" in
    sqlite|postgresql|timescaledb|mysql|mariadb) ;;
    *) die "PANEL_DATABASE must be sqlite, postgresql, timescaledb, mysql, or mariadb" ;;
esac
if [ "$PANEL_DATABASE" != sqlite ] && [ "$ARCH" != amd64 ]; then
    die "the $PANEL_DATABASE images are only in the amd64 bundle; use sqlite on $ARCH"
fi
READY_TRIES=120
if [ "$PANEL_DATABASE" != sqlite ]; then READY_TRIES=300; fi
ask PANEL_ADMIN_USER "owner account username (3-128 letters, digits, - _ @ .)" ""
[ -n "$PANEL_ADMIN_USER" ] || die "PANEL_ADMIN_USER is required"
[[ "$PANEL_ADMIN_USER" =~ ^[a-zA-Z0-9_@.-]{3,128}$ ]] || die "PANEL_ADMIN_USER may use only letters, digits, - _ @ . (3 to 128 characters)"
[[ "$PANEL_ADMIN_USER" =~ [-_@.]{2} ]] && die "PANEL_ADMIN_USER cannot have two special characters in a row"
ask_secret PANEL_ADMIN_PASSWORD "password for $PANEL_ADMIN_USER (12+ characters, 2 digits, 2 uppercase, 2 lowercase, 1 special character from !@#\$%^&*()-_=+[]{}|;:,.<>?/~\`; no double quote)"
admin_pw="${PANEL_ADMIN_PASSWORD:-}"
# The same rules as the panel's own password check, so that a password is refused here and not at the end.
[ "$(printf '%s' "$admin_pw" | wc -c)" -le 72 ] || die "the password is longer than 72 bytes"
[ "${#admin_pw}" -ge 12 ] || die "the password must have at least 12 characters"
[ "$(printf '%s' "$admin_pw" | tr -cd '0-9' | wc -c)" -ge 2 ] || die "the password must have at least 2 digits"
[ "$(printf '%s' "$admin_pw" | LC_ALL=C tr -cd 'A-Z' | wc -c)" -ge 2 ] || die "the password must have at least 2 uppercase letters"
[ "$(printf '%s' "$admin_pw" | LC_ALL=C tr -cd 'a-z' | wc -c)" -ge 2 ] || die "the password must have at least 2 lowercase letters"
printf '%s' "$admin_pw" | grep -q '[][!@#$%^&*()_=+{}|;:,.<>?/~`-]' || die "the password must have one special character"
[[ "$admin_pw" == *\"* ]] && die "the password cannot contain a double quote"
[[ "${admin_pw,,}" == *"${PANEL_ADMIN_USER,,}"* ]] && die "the password cannot contain the username"

install_docker() {
    # Installs the Docker engine and its compose plugin from the mirror, unless both already work.
    if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        log "Docker is already installed"
        return 0
    fi
    log "installing Docker from the mirror"
    mkdir -p "$TMP/docker"
    local debs=() key name prefix="apt/$VERSION_ID/$ARCH/docker/"
    for key in "${!MIRROR_SHA256[@]}"; do
        case "$key" in
            "$prefix"*)
                name="${key#"$prefix"}"
                mirror_fetch "$key" "$TMP/docker/$name"
                debs+=("$TMP/docker/$name")
                ;;
        esac
    done
    [ "${#debs[@]}" -gt 0 ] || die "this bundle has no Docker packages for Ubuntu $VERSION_ID $ARCH"
    # dpkg checks dependencies in the order it unpacks, so a package can fail on one pass and succeed on the next.
    for _ in 1 2 3; do
        if DEBIAN_FRONTEND=noninteractive dpkg -i --force-confold "${debs[@]}" >/dev/null 2>&1; then
            break
        fi
    done
    systemctl enable --now docker >/dev/null 2>&1 || systemctl start docker || true
    docker info >/dev/null 2>&1 || die "Docker did not start; check: journalctl -u docker"
    docker compose version >/dev/null 2>&1 || die "the Docker compose plugin did not install"
}

log "installing Docker"
install_docker

log "loading the panel image from the mirror"
mirror_fetch "pasarguard/linux-$ARCH/panel-$PANEL_TAG.tar.gz" "$TMP/panel.tar.gz"
gunzip -c "$TMP/panel.tar.gz" | docker load >/dev/null
rm -f "$TMP/panel.tar.gz"
docker image inspect "$PANEL_IMAGE" >/dev/null 2>&1 || die "the panel image $PANEL_IMAGE did not load"

db_key() {
    # db_key <image reference>: the mirror's path for a database image, named the way the bundle names it.
    local safe="${1//\//_}"
    safe="${safe//:/-}"
    echo "pasarguard/db/linux-$ARCH/$safe.tar.gz"
}

load_db_image() {
    # load_db_image <image reference>: loads one database image from the mirror.
    local ref="$1"
    mirror_fetch "$(db_key "$ref")" "$TMP/db.tar.gz"
    gunzip -c "$TMP/db.tar.gz" | docker load >/dev/null
    rm -f "$TMP/db.tar.gz"
    docker image inspect "$ref" >/dev/null 2>&1 || die "the image $ref did not load"
}

case "$PANEL_DATABASE" in
    postgresql) log "loading the PostgreSQL images from the mirror"; load_db_image "$POSTGRES_IMAGE"; load_db_image "$PGBOUNCER_IMAGE" ;;
    timescaledb) log "loading the TimescaleDB images from the mirror"; load_db_image "$TIMESCALEDB_IMAGE"; load_db_image "$PGBOUNCER_IMAGE" ;;
    mysql) log "loading the MySQL image from the mirror"; load_db_image "$MYSQL_IMAGE" ;;
    mariadb) log "loading the MariaDB image from the mirror"; load_db_image "$MARIADB_IMAGE" ;;
esac

log "creating the folders"
install -d -m 0755 -o root -g root "$INSTALL_DIR"
install -d -m 0750 -o root -g root "$DATA_DIR" "$DATA_DIR/tls"

case "$PANEL_TLS" in
    internal)
        log "creating the private certificate authority and the server certificate"
        openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
            -keyout "$DATA_DIR/tls/ca.key" -out "$DATA_DIR/tls/ca.crt" -days 3650 -subj "/CN=PasarGuard private CA" \
            -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" >/dev/null 2>&1
        if [[ "$PANEL_HOST" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then SAN="IP:$PANEL_HOST"; else SAN="DNS:$PANEL_HOST"; fi
        openssl req -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
            -keyout "$DATA_DIR/tls/server.key" -out "$TMP/server.csr" -subj "/CN=$PANEL_HOST" \
            -addext "subjectAltName=$SAN" >/dev/null 2>&1
        openssl x509 -req -in "$TMP/server.csr" -CA "$DATA_DIR/tls/ca.crt" -CAkey "$DATA_DIR/tls/ca.key" -CAcreateserial \
            -out "$DATA_DIR/tls/server.crt" -days 800 -copy_extensions copyall >/dev/null 2>&1
        rm -f "$DATA_DIR/tls/ca.srl"
        chmod 0600 "$DATA_DIR/tls/ca.key"
        chmod 0644 "$DATA_DIR/tls/ca.crt"
        ;;
    file)
        install -m 0644 "$PANEL_TLS_CERT_FILE" "$DATA_DIR/tls/server.crt"
        install -m 0600 "$PANEL_TLS_KEY_FILE" "$DATA_DIR/tls/server.key"
        ;;
esac

DB_NAME="pasarguard"
DB_USER="pasarguard"
DB_PASSWORD=""
MYSQL_ROOT_PASSWORD=""
if [ "$PANEL_DATABASE" != sqlite ]; then
    DB_PASSWORD=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24 || true)
    MYSQL_ROOT_PASSWORD=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24 || true)
fi
case "$PANEL_DATABASE" in
    sqlite) DB_URL="sqlite+aiosqlite:////var/lib/pasarguard/db.sqlite3" ;;
    postgresql|timescaledb) DB_URL="postgresql+asyncpg://$DB_USER:$DB_PASSWORD@127.0.0.1:6432/$DB_NAME" ;;
    mysql|mariadb) DB_URL="mysql+asyncmy://$DB_USER:$DB_PASSWORD@127.0.0.1:3306/$DB_NAME" ;;
esac

log "writing the panel settings"
{
    echo "UVICORN_HOST = \"0.0.0.0\""
    echo "UVICORN_PORT = $PANEL_PORT"
    echo "SQLALCHEMY_DATABASE_URL = \"$DB_URL\""
    if [ "$PANEL_DATABASE" != sqlite ]; then
        echo "DB_NAME = \"$DB_NAME\""
        echo "DB_USER = \"$DB_USER\""
        echo "DB_PASSWORD = \"$DB_PASSWORD\""
    fi
    if [ "$PANEL_DATABASE" = mysql ] || [ "$PANEL_DATABASE" = mariadb ]; then
        echo "MYSQL_ROOT_PASSWORD = \"$MYSQL_ROOT_PASSWORD\""
    fi
    if [ "$PANEL_TLS" != http ]; then
        echo "UVICORN_SSL_CERTFILE = \"$DATA_DIR/tls/server.crt\""
        echo "UVICORN_SSL_KEYFILE = \"$DATA_DIR/tls/server.key\""
        echo "UVICORN_SSL_CA_TYPE = \"$PANEL_SSL_CA_TYPE\""
    fi
} >"$INSTALL_DIR/.env"
chmod 0600 "$INSTALL_DIR/.env"

write_compose() {
    # write_compose: the panel's Compose file, with the database service for the chosen engine.
    local svc image
    case "$PANEL_DATABASE" in
    sqlite)
        cat >"$INSTALL_DIR/docker-compose.yml" <<COMPOSE
services:
  pasarguard:
    image: $PANEL_IMAGE
    restart: always
    env_file: .env
    network_mode: host
    volumes:
      - $DATA_DIR:$DATA_DIR
COMPOSE
        ;;
    postgresql|timescaledb)
        if [ "$PANEL_DATABASE" = postgresql ]; then svc=postgresql; image="$POSTGRES_IMAGE"; else svc=timescaledb; image="$TIMESCALEDB_IMAGE"; fi
        cat >"$INSTALL_DIR/docker-compose.yml" <<COMPOSE
services:
  pasarguard:
    image: $PANEL_IMAGE
    restart: always
    env_file: .env
    network_mode: host
    volumes:
      - $DATA_DIR:$DATA_DIR
    depends_on:
      pgbouncer:
        condition: service_healthy

  $svc:
    image: $image
    restart: always
    command: postgres -c max_connections=400 -c shared_buffers=512MB -c work_mem=16MB
    environment:
      POSTGRES_DB: \${DB_NAME}
      POSTGRES_USER: \${DB_USER}
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - /var/lib/postgresql/pasarguard:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -q -d \${DB_NAME} -U \${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - pg_backend

  pgbouncer:
    image: $PGBOUNCER_IMAGE
    restart: always
    environment:
      DB_HOST: $svc
      DB_PORT: 5432
      DB_USER: \${DB_USER}
      DB_PASSWORD: \${DB_PASSWORD}
      DB_NAME: \${DB_NAME}
      LISTEN_PORT: 6432
      POOL_MODE: transaction
      MAX_CLIENT_CONN: 600
      DEFAULT_POOL_SIZE: 50
      RESERVE_POOL_SIZE: 25
      AUTH_TYPE: scram-sha-256
      LOG_CONNECTIONS: 0
      LOG_DISCONNECTIONS: 0
      LOG_POOLER_ERRORS: 0
      VERBOSE: 0
    ports:
      - "127.0.0.1:6432:6432"
    depends_on:
      $svc:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "pgrep -f pgbouncer > /dev/null"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    networks:
      - pg_backend

networks:
  pg_backend:
    driver: bridge
COMPOSE
        ;;
    mysql|mariadb)
        if [ "$PANEL_DATABASE" = mysql ]; then svc=mysql; image="$MYSQL_IMAGE"; else svc=mariadb; image="$MARIADB_IMAGE"; fi
        if [ "$svc" = mysql ]; then
            health='["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "-u", "${DB_USER}", "--password=${DB_PASSWORD}"]'
            tune='      - --general_log=0
      - --skip-log-bin'
        else
            health='["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]'
            tune='      - --general_log=0'
        fi
        cat >"$INSTALL_DIR/docker-compose.yml" <<COMPOSE
services:
  pasarguard:
    image: $PANEL_IMAGE
    restart: always
    env_file: .env
    network_mode: host
    volumes:
      - $DATA_DIR:$DATA_DIR
    depends_on:
      $svc:
        condition: service_healthy

  $svc:
    image: $image
    network_mode: host
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      MYSQL_ROOT_HOST: "%"
      MYSQL_DATABASE: \${DB_NAME}
      MYSQL_USER: \${DB_USER}
      MYSQL_PASSWORD: \${DB_PASSWORD}
    command:
      - --bind-address=127.0.0.1
      - --character_set_server=utf8mb4
      - --collation_server=utf8mb4_unicode_ci
      - --host-cache-size=0
      - --innodb-open-files=1024
      - --innodb-buffer-pool-size=256M
$tune
    volumes:
      - /var/lib/mysql/pasarguard:/var/lib/mysql
    healthcheck:
      test: $health
      start_period: 10s
      interval: 5s
      timeout: 5s
      retries: 55
COMPOSE
        ;;
    esac
}
write_compose

log "starting the panel container"
(cd "$INSTALL_DIR" && docker compose -p pasarguard up -d >/dev/null)

log "waiting for the panel (the first start creates the database)"
ready=no
for _ in $(seq 1 "$READY_TRIES"); do
    code=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 5 --resolve "$PANEL_HOST:$PANEL_PORT:127.0.0.1" "$PANEL_URL/" || true)
    if [ "$code" != 000 ] && [ "${code:-999}" -lt 500 ]; then
        ready=yes
        break
    fi
    sleep 2
done
[ "$ready" = yes ] || die "the panel did not answer at $PANEL_URL; check: cd $INSTALL_DIR && docker compose -p pasarguard logs"

# The panel makes its first admin (the owner) from a one-time key that the panel's CLI prints. The installer asks the
# setup API to make the owner with the username and password you entered, and then checks that the login works.
log "creating the owner account"
temp_key=$(cd "$INSTALL_DIR" && docker compose -p pasarguard exec -T pasarguard pasarguard-cli generate-temp-key 2>/dev/null \
    | sed 's/\x1b\[[0-9;]*m//g' | grep -o 'Temp key: [A-Za-z0-9_=-]*' | awk '{print $3}' | head -n 1 || true)
[ -n "$temp_key" ] || die "could not make a one-time key for the owner account; check: cd $INSTALL_DIR && docker compose -p pasarguard logs"
json_pw="${admin_pw//\\/\\\\}"
umask 077
printf '%s' "$admin_pw" >"$TMP/password.txt"
printf '{"key":"%s","username":"%s","password":"%s"}' "$temp_key" "$PANEL_ADMIN_USER" "$json_pw" >"$TMP/owner.json"
code=$(curl -sk -o "$TMP/owner-response.json" -w '%{http_code}' --max-time 60 --resolve "$PANEL_HOST:$PANEL_PORT:127.0.0.1" \
    -H 'Content-Type: application/json' -d @"$TMP/owner.json" "$PANEL_URL/api/setup/owner" || true)
umask 022
[ "$code" = 201 ] || die "could not create the owner account (HTTP $code): $(head -c 300 "$TMP/owner-response.json" 2>/dev/null)"
code=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 60 --resolve "$PANEL_HOST:$PANEL_PORT:127.0.0.1" \
    --data-urlencode "username=$PANEL_ADMIN_USER" --data-urlencode "password@$TMP/password.txt" "$PANEL_URL/api/admin/token" || true)
[ "$code" = 200 ] || die "the owner account was created, but its login failed (HTTP $code)"

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    log "opening the panel port in ufw"
    ufw allow "$PANEL_PORT/tcp" >/dev/null
fi

DB_SUMMARY="SQLite in $DATA_DIR/db.sqlite3"
if [ "$PANEL_DATABASE" != sqlite ]; then
    DB_SUMMARY="$PANEL_DATABASE on 127.0.0.1 (PostgreSQL and TimescaleDB through PgBouncer on port 6432; MySQL and MariaDB on port 3306); settings in $INSTALL_DIR/.env"
fi

cat <<DONE

The PasarGuard panel is running at $PANEL_URL/
Owner account: $PANEL_ADMIN_USER (the username and password you entered)
Database: $DB_SUMMARY
DONE
if [ "$PANEL_TLS" = internal ]; then
    echo "Browsers must trust the local CA certificate: $DATA_DIR/tls/ca.crt"
fi
if [ "$PANEL_TLS" = http ]; then
    echo "HTTP only: the login is not encrypted, and browsers block calls on this address."
fi
echo "Logs: cd $INSTALL_DIR && docker compose -p pasarguard logs -f"
