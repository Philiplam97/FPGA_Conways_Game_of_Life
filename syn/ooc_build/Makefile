PART ?= XC7A35TICSG324-1L #Default part xc7a3t on arty A7
PROJECT ?= game_of_life
TOP ?= arty_top
OUTPUT_DIR ?= $(TOP)_build

.PHONY: all clean synth route

all : clean synth route

synth : $(OUTPUT_DIR)/$(TOP)_synth.dcp
$(OUTPUT_DIR)/$(TOP)_synth.dcp : 
	@mkdir -p $(OUTPUT_DIR)
	@echo "source ../$(PROJECT)_prj.tcl" > synth.tcl
	@echo "read_xdc ooc_timing.xdc -mode out_of_context" >> synth.tcl
# Increase the default loop limit in vivado. This is needed because a big for loop is used to initialise the BRAM content
# and Vivado complains with a "loop limit exceeded" error. 
# tcl command comes from here: https://support.xilinx.com/s/article/58823?language=en_US
	@echo "set_param synth.elaboration.rodinMoreOptions \"rt::set_parameter max_loop_limit 400000\"" >> synth.tcl
	@echo "synth_design -mode out_of_context -flatten_hierarchy rebuilt -top $(TOP) -part $(PART) -assert" >> synth.tcl
	@echo "write_checkpoint -force $(OUTPUT_DIR)/$(TOP)_synth.dcp" >> synth.tcl
	@echo "report_timing_summary -file $(OUTPUT_DIR)/synth_timing_summary.txt" >> synth.tcl
	vivado -mode batch -source synth.tcl -journal $(OUTPUT_DIR)/$(TOP)_synth.jou -log $(OUTPUT_DIR)/$(TOP)_synth.log
	

route : $(OUTPUT_DIR)/$(TOP)_route.dcp
$(OUTPUT_DIR)/$(TOP)_route.dcp : $(OUTPUT_DIR)/$(TOP)_synth.dcp
	@echo "open_checkpoint $(OUTPUT_DIR)/$(TOP)_synth.dcp" > route.tcl
	@echo "opt_design" >> route.tcl
	@echo "place_design" >> route.tcl
	@echo "phys_opt_design" >> route.tcl
	@echo "route_design" >> route.tcl
	@echo "write_checkpoint -force $(OUTPUT_DIR)/$(TOP)_route.dcp" >> route.tcl
	@echo "report_timing_summary -file $(OUTPUT_DIR)/route_timing_summary.txt" >> route.tcl
	@echo "report_timing -sort_by group -max_paths 100 -path_type summary -file $(OUTPUT_DIR)/route_timing.txt" >> route.tcl
	@echo "report_utilization -file $(OUTPUT_DIR)/route_util.txt" >> route.tcl
	vivado -mode batch -source route.tcl -journal $(OUTPUT_DIR)/$(TOP)_route.jou -log $(OUTPUT_DIR)/$(TOP)_route.log

clean:
	rm -rf $(OUTPUT_DIR)