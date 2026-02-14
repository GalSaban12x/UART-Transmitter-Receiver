# a possible do (*.TCL) script to run the UART transmitter simulation
vcom receiver.vhd
vcom tb_receiver.vhd
vsim tb_receiver
restart -force
noview *
add wave resetN
add wave clk
add wave                 /tb_receiver/eut/rxs
add wave                 /tb_receiver/eut/present_state
add wave                 /tb_receiver/eut/dcount_clr
add wave                 /tb_receiver/eut/dcount_ena
add wave -radix unsigned /tb_receiver/eut/dcount
add wave                 /tb_receiver/eut/eoc
add wave                 /tb_receiver/eut/te
add wave -radix unsigned /tb_receiver/eut/tcount
add wave                 /tb_receiver/eut/t1
add wave                 /tb_receiver/eut/t2
add wave                 /tb_receiver/eut/shift_ena

add wave  dout_new
add wave  dout_ready
add wave  read_dout






add wave                 dout
add wave -radix ascii    dout
run 990000 ns
puts "choosing a zoom-full timing range:"
wave zoomfull
#.wave.tree zoomfull ;# with some versions of modelsim
echo "---------------------- END OF SCRIPT ------------------------"
echo "The time now is $now [ string trim $resolution 01 ] "

