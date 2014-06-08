rm -rf build
mkdir build
cp atari800core_mist.vhd build
cp pll.* build
cp atari800core.sdc build
cp data_io.vhdl build
cp user_io.v build
cp mist_sector_buffer.* build
cp zpu_rom.vhdl build
mkdir build/common
mkdir build/common/a8core
mkdir build/common/components
mkdir build/common/zpu
cp ../common/a8core/* ./build/common/a8core
cp ../common/components/* ./build/common/components
cp ../common/zpu/* ./build/common/zpu

cd build
../makeqsf ../atari800core.qsf ./common/a8core ./common/components ./common/zpu

quartus_sh --flow compile atari800core
