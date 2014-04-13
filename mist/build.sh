rm -rf build
mkdir build
cp atari800core_mist.vhd build
cp pll.* build
cp atari800core.sdc build
cp data_io.vhdl build
cp user_io.v build
cp mist_sector_buffer.* build

cd build
../makeqsf ../atari800core.qsf ../../common/a8core ../../common/components

quartus_sh --flow compile atari800core
