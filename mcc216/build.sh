rm -rf build
mkdir build
cp atari800core_mcc.vhd build
cp pll.* build
cp sdram_ctrl_3_ports.v build
cp atari800core.sdc build

cd build
../makeqsf ../atari800core.qsf ../../common/a8core ../../common/components

quartus_sh --flow compile atari800core
