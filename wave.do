onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /lab8_check_tb/KEY
add wave -noupdate /lab8_check_tb/SW
add wave -noupdate /lab8_check_tb/LEDR
add wave -noupdate /lab8_check_tb/CLOCK_50
add wave -noupdate -divider {Top Level}
add wave -noupdate /lab8_check_tb/DUT/clk
add wave -noupdate /lab8_check_tb/DUT/reset
add wave -noupdate /lab8_check_tb/DUT/load_led
add wave -noupdate /lab8_check_tb/DUT/load_sw
add wave -noupdate /lab8_check_tb/DUT/halt
add wave -noupdate /lab8_check_tb/DUT/mem_cmd
add wave -noupdate /lab8_check_tb/DUT/mem_addr
add wave -noupdate /lab8_check_tb/DUT/read_data
add wave -noupdate /lab8_check_tb/DUT/write_data
add wave -noupdate /lab8_check_tb/DUT/dout
add wave -noupdate /lab8_check_tb/DUT/present_state
add wave -noupdate /lab8_check_tb/DUT/msel
add wave -noupdate /lab8_check_tb/DUT/write
add wave -noupdate -divider CPU
add wave -noupdate /lab8_check_tb/DUT/CPU/read_data
add wave -noupdate /lab8_check_tb/DUT/CPU/PC
add wave -noupdate /lab8_check_tb/DUT/CPU/DataAddressOut
add wave -noupdate /lab8_check_tb/DUT/CPU/next_pc
add wave -noupdate /lab8_check_tb/DUT/CPU/datapath_out
add wave -noupdate /lab8_check_tb/DUT/CPU/mem_addr
add wave -noupdate /lab8_check_tb/DUT/CPU/mem_cmd
add wave -noupdate /lab8_check_tb/DUT/CPU/halt
add wave -noupdate /lab8_check_tb/DUT/CPU/instr
add wave -noupdate /lab8_check_tb/DUT/CPU/sximm8
add wave -noupdate /lab8_check_tb/DUT/CPU/sximm5
add wave -noupdate /lab8_check_tb/DUT/CPU/con/present_state
add wave -noupdate /lab8_check_tb/DUT/CPU/con/load_pc
add wave -noupdate -divider FSM
add wave -noupdate /lab8_check_tb/DUT/CPU/con/clk
add wave -noupdate /lab8_check_tb/DUT/CPU/con/reset
add wave -noupdate /lab8_check_tb/DUT/CPU/con/Z
add wave -noupdate /lab8_check_tb/DUT/CPU/con/N
add wave -noupdate /lab8_check_tb/DUT/CPU/con/V
add wave -noupdate /lab8_check_tb/DUT/CPU/con/opcode
add wave -noupdate /lab8_check_tb/DUT/CPU/con/cond
add wave -noupdate /lab8_check_tb/DUT/CPU/con/op
add wave -noupdate /lab8_check_tb/DUT/CPU/con/halt
add wave -noupdate /lab8_check_tb/DUT/CPU/con/loada
add wave -noupdate /lab8_check_tb/DUT/CPU/con/loadb
add wave -noupdate /lab8_check_tb/DUT/CPU/con/loadc
add wave -noupdate /lab8_check_tb/DUT/CPU/con/write
add wave -noupdate /lab8_check_tb/DUT/CPU/con/asel
add wave -noupdate /lab8_check_tb/DUT/CPU/con/bsel
add wave -noupdate /lab8_check_tb/DUT/CPU/con/loads
add wave -noupdate /lab8_check_tb/DUT/CPU/con/reset_pc
add wave -noupdate /lab8_check_tb/DUT/CPU/con/addr_sel
add wave -noupdate /lab8_check_tb/DUT/CPU/con/load_ir
add wave -noupdate /lab8_check_tb/DUT/CPU/con/load_addr
add wave -noupdate /lab8_check_tb/DUT/CPU/con/branch_load
add wave -noupdate /lab8_check_tb/DUT/CPU/con/mem_cmd
add wave -noupdate /lab8_check_tb/DUT/CPU/con/nsel
add wave -noupdate /lab8_check_tb/DUT/CPU/con/vsel
add wave -noupdate -divider REGFILE
add wave -noupdate /lab8_check_tb/DUT/CPU/DP/REGFILE/data_in
add wave -noupdate /lab8_check_tb/DUT/CPU/DP/REGFILE/write
add wave -noupdate /lab8_check_tb/DUT/CPU/DP/REGFILE/hot_readnum
add wave -noupdate /lab8_check_tb/DUT/CPU/DP/REGFILE/R0
add wave -noupdate /lab8_check_tb/DUT/CPU/DP/REGFILE/R1
add wave -noupdate /lab8_check_tb/DUT/CPU/DP/REGFILE/R2
add wave -noupdate /lab8_check_tb/DUT/CPU/DP/REGFILE/R3
add wave -noupdate /lab8_check_tb/DUT/CPU/DP/REGFILE/R4
add wave -noupdate /lab8_check_tb/DUT/CPU/DP/REGFILE/R5
add wave -noupdate /lab8_check_tb/DUT/CPU/DP/REGFILE/R6
add wave -noupdate /lab8_check_tb/DUT/CPU/DP/REGFILE/R7
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1849 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {1839 ps} {2025 ps}
