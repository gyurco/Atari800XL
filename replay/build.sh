#!/bin/bash

name=Replay
args=$@
shift

embed_roms=0


. /home/markw/altera/xilinx/ise/14.7/ISE_DS/settings32.sh

if [ $embed_roms = 1 ]; then
    pushd sdcard
    cat lb1.cpu lb2.cpu lb3.cpu lb4.cpu lb5.cpu lb6.cpu lb10.vid lb9.vid lb7.cpu lb8.cpu > ../rom_stripe.bin
    cat 10-1.vid >> ../rom_stripe.bin
    dd if=/dev/zero bs=2016 count=1 >> ../rom_stripe.bin
    cat 10-3.vid >> ../rom_stripe.bin
    dd if=/dev/zero bs=2016 count=1 >> ../rom_stripe.bin
    cat 10-2.vid >> ../rom_stripe.bin
    dd if=/dev/zero bs=2016 count=1 >> ../rom_stripe.bin
    popd
fi

mkdir -p build
pushd build

cp -p ../../replay_lib/rtl/*.vhd .
cp -p ../source/*.v* .

cp -p ../$name.ucf .
cp -p ../$name.ut .
cp -p ../$name.scr .
cp -p ../$name.prj .
if [ $embed_roms = 1 ]; then
    cp -p ../roms.bmm .
fi


if [ "${args[0]}" != "-xil" ]; then

    echo "Starting Synthesis..."
    xst -ifn $name.scr -ofn $name.srp || exit 1

fi

echo "Starting Translate..."
if [ $embed_roms = 1 ]; then
    ngdbuild -nt on -uc $name.ucf -bm roms.bmm $name.ngc $name.ngd || exit 1
else
    ngdbuild -nt on -uc $name.ucf $name.ngc $name.ngd || exit 1
fi

echo "Starting Map..."
map -pr b $name.ngd -o $name.ncd $name.pcf || exit 1

echo "Starting Place & Route..."
par -w -ol std $name.ncd $name.ncd $name.pcf || exit 1

echo "Starting Timing Analysis..."
trce -v 10 -o $name.twr $name.ncd $name.pcf || exit 1

echo "Starting Bitgen..."
bitgen $name.ncd $name.bit -w -f $name.ut || exit 1

if [ $embed_roms = 1 ]; then
    echo "Annotating ROM contents to bit file..."
    data2mem -bm roms_bd.bmm -bt $name.bit -bd ../rom_stripe.bin -o b loader.bit || exit 1
    promgen -u 0 loader.bit -p bin -w -b -o atari800.bin || exit 1

    popd
    cp build/atari800.bin sdcard/atari800.bin
else
    popd
    cp build/$name.bin sdcard/atari800.bin
fi
