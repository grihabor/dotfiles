#!/bin/bash

# https://www.makeuseof.com/install-bluez-latest-version-on-ubuntu/

mkdir /tmp/bluez
curl -L -o /tmp/bluez/bluez-5.66.tar.xz \
    http://www.kernel.org/pub/linux/bluetooth/bluez-5.66.tar.xz
(
    cd /tmp/bluez || exit 1
    tar xf bluez-5.66.tar.xz
    cd bluez-5.66 || exit 1
    ./configure
    make
    sudo make install
)
