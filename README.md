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

## Design
To determine the value of a cell for the next generation, we need access to the neighbouring 8 cells. Essentially this is a sliding 3x3 window operation, similar to what is needed in 2D convolution. We can do this efficiently in hardware with 3 shift registers, connected together as shown in the image below. The top two shift registers buffer one row each (or more accurately, the frame width - 3 number of cells) and are implemented by chaining SRL32s. The bottom shift register is much larger, buffering up all the other cells in the grid. This one is implemented using BRAMs. 

The output is taken as the centre value of the window, the 9 registers, and the next cell state is calculated and written back into the bottom shift register.


<p align="center">
  <img width="800"  src="https://github.com/Philiplam97/FPGA_Conways_Game_of_Life/blob/master/game_of_life_diagram.jpg?raw=true">
</p>


### Resource Utilisation
Total resource utilisation is shown in the table below. This is the whole design, including the VGA driver. 
|LUTs|Registers|BRAMs| 
|---|---|---|
|127 |99|10|

## Video Demonstration
Click on the picture below to watch a Youtube video showing some of the starting test patterns tested with this design.

[![Watch the video](https://img.youtube.com/vi/R8WKaXE9jXU/hqdefault.jpg)](https://youtu.be/R8WKaXE9jXU)

