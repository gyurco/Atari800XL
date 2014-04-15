#!/bin/bash

echo "---------------------------------------------------------"
echo "Use 'simulate -run' to skip compilation stage."
echo "Use 'simulate -view' to show previous simulation results."
echo "---------------------------------------------------------"

name=Replay

REPLAY_BASE=/home/markw/fpga/svn/replay/src/hw/replay/cores/replay_lib/


. /home/markw/fpga/xilinx/14.7/ISE_DS/settings64.sh

mkdir -p sim
pushd sim

# if we have a WDB file, we can view it if requested (otherwise we remove it)
if [ ! -e $name.wdb -o "$1" != "-view" ]; then

    rm -f $name.wdb

    # if we have a EXE, we can run it if requested (otherwise we remove it)
    if [ ! -e $name.exe -o "$1" != "-run" ]; then

        rm -f $name.exe

        # copy testbench files
        cp -p ../tb/Replay_tb.vhd .
        cp -p ${REPLAY_BASE}/tb/ddr.v .
        cp -p ${REPLAY_BASE}/tb/ddr_parameters.vh .
        cp -p ${REPLAY_BASE}/tb/Replay_I2C_CH7301.vhd .

        # copy source files
        cp -p ${REPLAY_BASE}/rtl/*.vhd .
        cp -p ../source/*.vhd .
        cp -p ../source/*.vhdl .
	cp -p ../../common/a8core/*.vhd .
	cp -p ../../common/a8core/*.vhdl .
	cp -p ../../common/components/*.vhd .
	cp -p ../../common/components/*.vhdl .


        # set up project definition file
        xilperl -p -e 's/^(.+)/vhdl work $1/;' ../$name.prj > $name.prj
        cat ../${name}_tb.prj >> $name.prj


        # verbose & no multthreading - fallback in case of problems
        # fuse -v 1 -mt off -incremental -prj %name%.prj -o %name%.exe -t %name%

        fuse -timeprecision_vhdl 1fs -incremental -prj $name.prj -o $name.exe -t ${name}_tb || exit 1
        # fuse --mt off -prj %name%.prj -o %name%.exe -t %name%_tb

        # Check for the EXE again, independent of the errorlevel of fuse...
        [ -e $name.exe ] || echo "No simulation executable created"


    fi

    # Open the iSIM GUI and run the simulation
    ./$name.exe -gui -f ../$name.cmd -wdb $name.wdb -log $name.log -view ../$name.wcfg || exit 1


else

    # Only start the viewer on an existing wave configuration (from an old simulation)
    isimgui -view ../$name.wcfg || exit 1

fi

popd
