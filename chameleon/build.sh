rm -rf build
mkdir build
cp atari800core_chameleon.vhd build
cp pll.* build
cp atari800core.sdc build
cp atari800core.cdf build
cp chameleon_* build

mkdir build/common
mkdir build/common/a8core
mkdir build/common/components
cp ../common/a8core/* ./build/common/a8core
cp ../common/components/* ./build/common/components

cd build
../makeqsf ../atari800core.qsf ./common/a8core ./common/components 

quartus_sh --flow compile atari800core
