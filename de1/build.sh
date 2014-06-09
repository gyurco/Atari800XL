rm -rf build
mkdir build
cp atari800core_de1.vhd build
cp pll.* build
cp atari800core.sdc build
cp hexdecoder.vhd build
cp i2c_loader.vhd build
cp i2sslave.vhdl build
cp sram.vhdl build
cp sync_switches.vhd build
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
