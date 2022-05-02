set src_dir [file join [file dirname [info script]] .. src]
set scripts_dir [file join [file dirname [info script]] .. scripts]

read_vhdl -vhdl2008 [file join $src_dir bram_shift_reg.vhd]
read_vhdl -vhdl2008 [file join $src_dir game_of_life.vhd]
read_vhdl -vhdl2008 [file join $src_dir VGA VGA.vhd]
read_vhdl -vhdl2008 [file join $src_dir common debouncer.vhd]
read_vhdl -vhdl2008 [file join $src_dir common sync_2FF.vhd]
read_vhdl -vhdl2008 [file join $src_dir arty_top.vhd]

add_files -norecurse [file join $scripts_dir bram_init.txt]