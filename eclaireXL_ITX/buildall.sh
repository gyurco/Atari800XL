#!/bin/bash

function max3 {
   while [ `jobs | wc -l` -ge 3 ]
   do
      sleep 1
   done
}
max3; ./build.sh A2EBA_SVIDEO_NTSC &
max3; ./build.sh A2EBA_SVIDEO_PAL &
max3; ./build.sh A2EBA_VGA50 &
max3; ./build.sh A2EBA_VGA60 &
max3; ./build.sh A2EBArom_SVIDEO_NTSC &
max3; ./build.sh A2EBArom_SVIDEO_PAL &
max3; ./build.sh A2EBArom_VGA50 &
max3; ./build.sh A2EBArom_VGA60 &
