export PATH=${PATH}:/home/markw/fpga/altera/13.0sp1/quartus/bin
cd de1
./build.sh > build.log 2> build.err&
cd ../replay
./build.sh > build.log 2> build.err&
cd ../mist
./build.sh > build.log 2> build.err&
cd ../mcc216
./build.sh > build.log 2> build.err&
