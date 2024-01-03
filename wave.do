onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_tasks::test
add wave -noupdate -format Analog-Step -height 84 -max 11653.000000000002 -min -11969.0 -radix decimal /Equalizer_tb/iDUT/fir_lft_chnnl
add wave -noupdate -format Analog-Step -height 85 -max 44160.0 -min 20000.0 -radix unsigned /Equalizer_tb/duty_infered_lft
add wave -noupdate /Equalizer_tb/counter_vld_lft
add wave -noupdate -format Analog-Step -height 84 -max 16185.0 -min -12556.0 -radix decimal /Equalizer_tb/iDUT/fir_rght_chnnl
add wave -noupdate -format Analog-Step -height 85 -max 44160.0 -min 20000.0 -radix unsigned /Equalizer_tb/duty_infered_rght
add wave -noupdate /Equalizer_tb/counter_vld_rght
add wave -noupdate /Equalizer_tb/amplitude_vld_lft
add wave -noupdate /Equalizer_tb/amplitude_vld_rght
add wave -noupdate -expand /Equalizer_tb/buttons
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {220433054 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 262
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 2
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {242942842 ns}
