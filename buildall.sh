export ORIGPATH=${PATH}

function max2 {
   while [ `jobs | wc -l` -ge 2 ]
   do
      sleep 5
   done
}

export PATH=${ORIGPATH}:/home/markw/fpga/altera/13.0sp1/quartus/bin
cd de1
max2; ./build.sh ALL &
cd ../chameleon
max2; ./build.sh ALL &
cd ../replay
max2; ./build.sh > build.log 2> build.err &
cd ../mist
max2; ./build.sh ALL &
cd ../mcc216
max2; ./build.sh ALL &
cd ../mcctv
max2; ./build.sh ALL &
cd ../papilioduo
max2; ./build.sh ALL &
cd ../mist_5200
max2; ./build.sh ALL &
cd ../de1_5200
max2; ./build.sh ALL &
cd ../mcc216_5200
max2; ./build.sh ALL &
cd ../mcctv_5200
max2; ./build.sh ALL &


export PATH=${ORIGPATH}:/home/markw/fpga/altera/14.0/quartus/bin:/home/markw/fpga/altera/14.0/quartus/sopc_builder/bin/
cd ../sockit
max2; ./build.sh &

export PATH=${ORIGPATH}
unset ORIGPATH

