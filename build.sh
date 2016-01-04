#!/bin/sh

mkdir -p build

pushd build
g++ ../code/osx_handmade.mm -framework Cocoa -g -Wall -o handmade
rm -rf Handmade.app
mkdir -p Handmade.app/Contents/MacOS
mkdir -p Handmade.app/Contents/Resources
cp handmade Handmade.app/Contents/MacOS/handmade
popd
