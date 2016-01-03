#!/bin/sh

mkdir -p build

pushd build
g++ ../code/osx_handmade.mm -framework Cocoa -g -o handmade
rm -rf Handmade.app
mkdir -p Handmade.app/Contents/MacOS
mkdir -p Handmade.app/Contents/Resources
mv handmade Handmade.app/Contents/MacOS/handmade
popd
