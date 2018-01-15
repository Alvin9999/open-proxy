#!/bin/bash


NGINX_VERSION=1.13.3 
PCRE_VERSION=8.41 
ZLIB_VERSION=1.2.11
NGX_CONF_DIR=/usr/local/nginx/conf

## install common tools
yum install -y gcc wget vim gcc-c++ 


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
make -j4 && make install 
cd ..


## configure
server_ip=$(ifconfig | grep "inet addr" | sed -n 1p | cut -d':' -f2 | cut -d' ' -f1)
for cfg in $(ls sites/*); do
	sed -i "s/local_server_ip/$server_ip/g" $cfg
	site=$(basename $cfg)
	sed "/## sites/a\\\\t\\tinclude $site;" $cfg
done
mv sites/* $NGX_CONF_DIR
cp *.conf $NGX_CONF_DIR

chmod +x nginx && cp nginx /etc/init.d 
chkconfig nginx on
service nginx start


