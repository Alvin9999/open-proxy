#!/bin/bash
# auth : gfw-breaker
# desc : startup script for VPS	deployment

yum install -y git

git clone https://github.com/gfw-breaker/open-proxy.git

cd open-proxy

## site list as parameters
bash install.sh google wiki



