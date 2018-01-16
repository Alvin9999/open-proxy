#!/bin/bash
# auth : gfw-breaker

sites=$(echo $(ls sites) | sed 's/\\n/ /')
for s in $*; do
    if [[ " $sites " =~ " $s " ]]; then
		targets="$s $targets"
	fi
done
if [ $# -eq 0 ]; then
	targets=$sites
fi
echo "you are going to install proxy for following sites:" $targets
sleep 2


NGINX_VERSION=1.13.3 
PCRE_VERSION=8.41 
ZLIB_VERSION=1.2.11
NGX_CONF_DIR=/usr/local/nginx/conf

## install common tools
yum install -y gcc wget vim gcc-c++ openssl-devel


## download
wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
wget "http://linux.stanford.edu/pub/exim/pcre/pcre-${PCRE_VERSION}.tar.gz"
wget "http://zlib.net/zlib-${ZLIB_VERSION}.tar.gz"


## install
tar xzf nginx-${NGINX_VERSION}.tar.gz && \
tar xzf pcre-${PCRE_VERSION}.tar.gz && \
tar xzf zlib-${ZLIB_VERSION}.tar.gz

cd nginx-${NGINX_VERSION} && \
./configure \
	--with-http_sub_module	\
	--with-http_ssl_module	\
	--with-http_realip_module  \
	--with-http_addition_module  \
	--with-http_sub_module  \
	--with-http_dav_module  \
	--with-http_flv_module  \
	--with-http_mp4_module \
	--with-http_gunzip_module  \
	--with-http_gzip_static_module \
	--with-http_random_index_module \
	--with-http_secure_link_module  \
	--with-http_stub_status_module  \
	--with-http_auth_request_module  \
	--with-threads  \
	--with-stream  \
	--with-stream_ssl_module \
	--with-http_slice_module \
	--with-mail  \
	--with-mail_ssl_module  \
	--with-file-aio  \
	--with-http_v2_module  \
	--with-pcre=../pcre-${PCRE_VERSION} \
	--with-zlib=../zlib-${ZLIB_VERSION}
if [ $? -ne 0 ]; then
	echo "failed to compile nginx and modules, please check the installation log"
	exit 1
fi

make -j4 && make install 
cd ..


## configure
server_ip=$(ifconfig | grep "inet addr" | sed -n 1p | cut -d':' -f2 | cut -d' ' -f1)
for site in $targets; do
	sed -i "s/local_server_ip/$server_ip/g" sites/$site
	sed -i "/## sites/a\\\\tinclude $site;" nginx.conf
	cp sites/$site $NGX_CONF_DIR
done
cp *.conf $NGX_CONF_DIR

chmod +x nginx && cp nginx /etc/init.d 
chkconfig nginx on
service nginx restart


## disable iptables temparorily for testing, should enable and add rules to it in production
service iptables stop
chkconfig iptables off


## print proxy information
function get_field(){
	local site="$1"
	local key="$2"
	local value=$(grep $key sites/$site | sed -n 1p | awk '{print $2}' | sed 's/;//')
	echo $value
}

echo -e "\nProxy information:\n" 
for s in $targets; do
	org_url=$(get_field $s proxy_pass)
	proxy_port=$(get_field $s listen)
	echo -e "http://$server_ip:$proxy_port\t->\t$org_url"
done
echo



