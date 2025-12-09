TARGET = paint_top
TOP    = paint_top

COMM_OBJS += paint_top.v
COMM_OBJS += mouse_rx.v
COMM_OBJS += uart.v
COMM_OBJS += count.v 
COMM_OBJS += ctrl_panel.v
COMM_OBJS += memory.v
COMM_OBJS += comp.v
COMM_OBJS += lsr.v
COMM_OBJS += mux.v
COMM_OBJS += ctrl_paint.v

TCL_SCRIPT = auto_generated.tcl
GOWIN_BOARD=primer_25k

ifeq ($(GOWIN_BOARD),nano_20k)
    DEVICE = GW2AR-LV18QN88C8/I7
    FAMILY = GW2AR-18C
else ifeq ($(GOWIN_BOARD),primer_25k)
    DEVICE = GW5A-LV25MG121NC1/I0
    FAMILY = GW5A-25A
else
    $(error GOWIN_BOARD=$(GOWIN_BOARD) no válido. Usa: nano_20k o primer_25k)
endif

all: configure_tang_primer_25k

del_tcl_script:
	rm -rf $(TCL_SCRIPT)

$(TCL_SCRIPT): del_tcl_script
	@echo "set_device -name $(FAMILY) $(DEVICE)" > $@
	@echo "" >> $@
ifeq ($(GOWIN_BOARD),nano_20k)
	@echo "add_file constraints/sipeed_tang_nano_20k.cst" >> $@
	@echo "add_file constraints/sipeed_tang_nano_20k.sdc" >> $@
else ifeq ($(GOWIN_BOARD),primer_25k)
	@echo "add_file constraints/sipeed_tang_primer_25k.cst" >> $@
	@echo "add_file constraints/sipeed_tang_primer_25k.sdc" >> $@
endif
	@for file in $(COMM_OBJS); do \
		echo "add_file -type verilog $$file" >> $@; \
	done
	@echo "" >> $@
	@echo "set_option -use_mspi_as_gpio 1" >> $@
ifeq ($(GOWIN_BOARD),nano_20k)
	@echo "set_option -use_sspi_as_gpio 1" >> $@
else ifeq ($(GOWIN_BOARD),primer_25k)
	@echo "set_option -use_i2c_as_gpio 1" >> $@
endif
	@echo "set_option -use_ready_as_gpio 1" >> $@
	@echo "set_option -use_done_as_gpio 1" >> $@
ifeq ($(GOWIN_BOARD),primer_25k)
	@echo "set_option -use_cpu_as_gpio 1" >> $@
endif
	@echo "set_option -rw_check_on_ram 1" >> $@
	@echo "set_option -top_module $(TOP)" >> $@
	@echo "run all" >> $@

clean_gowin:
	rm -rf impl

configure_tang_nano_20k: clean_gowin $(TCL_SCRIPT)
	gw_sh $(TCL_SCRIPT)
	openFPGALoader --cable ft2232 --bitstream ./impl/pnr/project.fs

configure_tang_primer_25k: $(TCL_SCRIPT)
	gw_sh $(TCL_SCRIPT)
	openFPGALoader --cable ft2232 --bitstream ./impl/pnr/project.fs

clean:
	rm -rf impl $(TCL_SCRIPT)
