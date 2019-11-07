#!/bin/sh

# TODO: put makself file in git repo with permissions
chmod +x makeself-2.4.0.run
./makeself-2.4.0.run
mkdir build
cp -r utils build/utils
cp -r $1 build/$1
./makeself-2.4.0/makeself.sh ./build $1.recipe "$2" ./$1/run.sh
rm -r makeself-2.4.0
rm -r build
