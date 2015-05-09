#!/bin/bash

args=$@
shift

. /home/markw/fpga/xilinx/14.7/ISE_DS/settings64.sh

export XILINX_DSP
export LD_LIBRARY_PATH
export XILINX_EDK
export PATH
export XILINX_PLANAHEAD
export XILINX

which xst

./build.pl ${args}

