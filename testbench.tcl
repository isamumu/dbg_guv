# quit any existing simulations
quit -sim

# create the default work library
vlib work

# compile the verilog source code in the parent folder

#vlog datapath.sv
#vlog testbench.sv

#vlog testbench_control.sv
#vlog control_FSM.sv
#vlog control_datapath_tb.sv

vlog dbg_guv_tb.sv
vlog axis_governor.sv
vlog control_FSM.sv
vlog datapath.sv
vlog dbg_guv.sv

# vlog *.sv

#vsim -novopt testbench
#vsim -novopt testbench_control
vsim -novopt dbg_guv_tb

# adds all the signals in the ‘DUT’ instance
add wave /* 
add wave -group CTRL /dbg_guv_tb/U1/U2/*
add wave -group DATA /dbg_guv_tb/U1/U1/*
# run for a specific amount of time
run 100us 