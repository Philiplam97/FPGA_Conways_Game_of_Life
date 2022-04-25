# add_files -norecurse [file dirname [info script]]/../src/chirp_gen/scripts/chirp_rom_data.txt

read_vhdl -vhdl2008 [file dirname [info script]]/../src/bram_shift_reg.vhd
read_vhdl -vhdl2008 [file dirname [info script]]/../src/VGA/VGA.vhd
read_vhdl -vhdl2008 [file dirname [info script]]/../src/game_of_life.vhd


