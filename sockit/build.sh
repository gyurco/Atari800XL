rm -rf build
mkdir build
cp atari800core_sockit.vhdl build
cp altiobuf.* build
cp altiobufo.* build
cp pll_pal.* build
cp avalon_a* build
cp -r pll_pal build
cp -r pll_pal_sim build
cp atari800core.sdc build
cp atari800core.qpf build
cp atari_hps.qsys build
cp i2* build

mkdir build/common
mkdir build/common/a8core
mkdir build/common/components
mkdir build/common/zpu
cp ../common/a8core/* ./build/common/a8core
cp ../common/components/* ./build/common/components
cp ../common/zpu/* ./build/common/zpu

cd build
../makeqsf ../atari800core.qsf ./common/a8core ./common/components ./common/zpu

ip-generate atari_hps.qsys --file-set=QUARTUS_SYNTH --standard-reports > qsys.log 2> qsys.err
quartus_sh --flow compile atari800core > build.log 2> build.err
quartus_cpf --convert ../output_file.cof
