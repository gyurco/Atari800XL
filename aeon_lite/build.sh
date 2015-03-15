#!/bin/bash

name=Aeon
args=$@
shift

. /home/markw/fpga/xilinx/14.7/ISE_DS/settings64.sh

mkdir -p build
pushd build

# copy source files
cp -p ../pll/* .
cp -p ../../common/a8core/*.vhd .
cp -p ../../common/a8core/*.vhdl .
cp -p ../../common/components/*.vhd .
cp -p ../../common/components/*.vhdl .
cp -p ../../common/zpu/*.vhd .
cp -p ../../common/zpu/*.vhdl .
#rm -f delay_line.vhdl
cp -p ../*.vhd .
cp -p ../*.vhdl .
cp -p ../*.xst .

cp -p ../$name.ucf .
cp -p ../$name.ut .
cp -p ../$name.scr .
cp -p ../$name.prj .

mkdir -p xst/projnav.tmp/

echo "Starting Synthesis"
xst -intstyle ise -ifn $name.xst -ofn $name.syr

echo "Starting NGD"
ngdbuild -intstyle ise -dd _ngo -nt timestamp -i -p xc6slx9-tqg144-3 $name.ngc $name.ngd

echo "Starting Map..."
map -intstyle ise -p xc6slx9-tqg144-3 -w -logic_opt off -ol high -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -mt off -detail -ir off -pr off -lc off -power off -o $name_map.ncd $name.ngd $name.pcf

echo "Starting Place & Route..."
par -w -intstyle ise -ol high -mt off $name_map.ncd $name.ncd $name.pcf

echo "Starting Timing Analysis..."
trce -intstyle ise -v 3 -s 3 -n 3 -fastpaths -xml $name.twx $name.ncd -o $name.twr $name.pcf

echo "Starting Bitgen..."
bitgen -intstyle ise -f $name.ut $name.ncd

popd
cp build/$name.bin core/atari800.bin
