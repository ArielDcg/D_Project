set_device -name GW5A-25A GW5A-LV25MG121NC1/I0

add_file constraints/sipeed_tang_primer_25k.cst
add_file constraints/sipeed_tang_primer_25k.sdc
add_file -type verilog paint_top.v
add_file -type verilog mouse_rx.v
add_file -type verilog uart.v
add_file -type verilog count.v
add_file -type verilog ctrl_panel.v
add_file -type verilog memory.v
add_file -type verilog comp.v
add_file -type verilog lsr.v
add_file -type verilog mux.v
add_file -type verilog ctrl_paint.v

set_option -use_mspi_as_gpio 1
set_option -use_i2c_as_gpio 1
set_option -use_ready_as_gpio 1
set_option -use_done_as_gpio 1
set_option -use_cpu_as_gpio 1
set_option -rw_check_on_ram 1
set_option -top_module paint_top
run all
