export PATH=${PATH}:/home/markw/fpga/altera/13.0sp1/quartus/bin
#export PATH=${PATH}:/home/markw/fpga/altera/14.0/quartus/bin
cd de1
./build.sh ALL > build.log 2> build.err&
cd ../chameleon
./build.sh ALL > build.log 2> build.err&
cd ../replay
./build.sh > build.log 2> build.err&
cd ../mist
./build.sh ALL > build.log 2> build.err&
cd ../mcc216
./build.sh ALL &
cd ../mcctv
./build.sh ALL &
cd ../mist_5200
./build.sh ALL > build.log 2> build.err&
cd de1_5200
./build.sh ALL > build.log 2> build.err&

# TODO variations?
# TODO SOCkit

