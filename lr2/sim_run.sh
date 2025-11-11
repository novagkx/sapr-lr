#!/bin/bash
echo "Compiling..."
iverilog -g2012 -o tb.bin rtl/apb_slave_v2.sv tb/tb_apb_v2.sv
if [ $? -eq 0 ]; then
  echo "Compilation OK, running simulation:"
  vvp tb.bin
else
  echo "Compilation failed!"
fi
echo "Simulation finished."
