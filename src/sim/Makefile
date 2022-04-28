PRJ_DIR = $(shell pwd)/../../
SRC_DIR = $(shell pwd)/../

VHDL_SOURCES = \
$(SRC_DIR)/bram_shift_reg.vhd \
$(SRC_DIR)/game_of_life.vhd \
$(SRC_DIR)/sim/game_of_life_tb.vhd

VCOM_ARGS = -2008 -check_synthesis
WAVES=0
.PHONY: all comp sim clean

all: comp sim check_output

clean: 
	rm -rf work
	rm -f bram_init_sim.txt
	
bram_init_sim.txt: 
	python $(PRJ_DIR)/scripts/parse_test_pattern.py --mode random --height 480 --width 640  --out_fn ./bram_init_sim.txt
	
comp: 
	vcom $(VCOM_ARGS) $(VHDL_SOURCES)

sim: bram_init_sim.txt
	@rm -f runsim.do
ifeq ($WAVES,1)
	@echo "log -recursive /*" >> runsim.do
endif
	@echo "run -all" >> runsim.do
	@echo "quit" >> runsim.do
	vsim work.game_of_life_tb -gG_BRAM_INIT_FILE_PATH='"bram_init_sim.txt"' -do runsim.do

check_output:
	@echo ""; echo "======================================================================"
	@echo ""; echo "Checking simulation output..."
	python $(PRJ_DIR)/scripts/check_tb_output.py --height 480 --width 640  --bram_init_path ./bram_init_sim.txt --sim_out_path sim_output.txt
