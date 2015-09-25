#!/bin/bash

export ORIGPATH=${PATH}

function max3 {
   while [ `jobs | wc -l` -ge 3 ]
   do
      sleep 1
   done
}

export PATH=${ORIGPATH}:/home/markw/fpga/altera/13.0sp1/quartus/bin
cd de1
max3; ./build.sh ALL &
cd ../chameleon
max3; ./build.sh ALL &
cd ../replay
max3; ./build.sh > build.log 2> build.err &
cd ../mist
max3; ./build.sh ALL &
cd ../mcc216
max3; ./build.sh ALL &
cd ../mcctv
max3; ./build.sh ALL &
cd ../papilioduo
max3; ./build.sh ALL &
cd ../aeon_lite
max3; ./build.sh ALL &
cd ../mist_5200
max3; ./build.sh ALL &
cd ../de1_5200
max3; ./build.sh ALL &
cd ../mcc216_5200
max3; ./build.sh ALL &
cd ../mcctv_5200
max3; ./build.sh ALL &


export PATH=${ORIGPATH}:/home/markw/fpga/altera/15.0/quartus/bin:/home/markw/fpga/altera/15.0/quartus/sopc_builder/bin/
cd ../sockit
max3; ./build.sh &

export PATH=${ORIGPATH}
unset ORIGPATH

