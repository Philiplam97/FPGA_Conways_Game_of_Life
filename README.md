# FPGA_Conways_Game_of_Life
Conway's Game of Life implemented on an Arty A7 with a VGA 640x480 60Hz output. Computations are done in real time at the pixel rate.

The test patterns located in `scripts/test_patterns`  are downloaded from http://www.radicaleye.com/lifepage/patterns/contents.html

## Usage
Requires:
- Python 3+ (with NumPy)
- Vivado (tested with 2021.2)
- Modelsim/Questa (for the simulation only)
- GNU Make

This project uses the VGA PMOD plugged in the JB and JC ports on the Arty A7. If you are rolling your own DAC/VGA connector, you should use the same ports/pins or update the constraints file `syn/Arty-A7-35-Master.xdc`.

To program the FPGA, connect the Arty A7 to the PC via the USB port, cd to `syn` and type
```
make program PATTERN=oscspn3
```
The other pattern saved in this repository is `aqua25b`. If you wish to try another pattern, download one from the link posted above (or get one in the standard .lif format) and place it in the `scripts/test_patterns` directory. Then simply pass through the pattern name to the Makefile with the command line variable `PATTERN=<filename>`