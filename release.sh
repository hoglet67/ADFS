#!/bin/bash

./build.sh

VERSION=157

mkdir -p releases

release=releases/adfs_${VERSION}_$(date +"%Y%m%d_%H%M").zip
cd build
zip -qr ../${release} *
cd ..
unzip -l ${release}
