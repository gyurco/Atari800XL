#!/bin/bash

name=Aeon
args=$@
shift

. /home/markw/fpga/xilinx/14.7/ISE_DS/settings64.sh

mkdir -p build
pushd build

# copy source files
cp -p ../*.vhd .
cp -p ../*.vhdl .
cp -p ../pll/* .
cp -p ../../common/a8core/*.vhd .
cp -p ../../common/a8core/*.vhdl .
cp -p ../../common/components/*.vhd .
cp -p ../../common/components/*.vhdl .
cp -p ../../common/zpu/*.vhd .
cp -p ../../common/zpu/*.vhdl .

cp -p ../$name.ucf .
cp -p ../$name.ut .
cp -p ../$name.scr .
cp -p ../$name.prj .

if [ "${args[0]}" != "-xil" ]; then

    echo "Starting Synthesis..."
    xst -ifn $name.scr -ofn $name.srp || exit 1

fi

echo "Starting Translate..."
ngdbuild -nt on -uc $name.ucf $name.ngc $name.ngd || exit 1

echo "Starting Map..."
map -pr b $name.ngd -o $name.ncd $name.pcf || exit 1

echo "Starting Place & Route..."
par -w -ol std $name.ncd $name.ncd $name.pcf || exit 1

echo "Starting Timing Analysis..."
trce -v 10 -o $name.twr $name.ncd $name.pcf || exit 1

echo "Starting Bitgen..."
bitgen $name.ncd $name.bit -w -f $name.ut || exit 1

popd
cp build/$name.bin core/atari800.bin
