#!/bin/sh
# the next line restarts using emcsh \
exec sudo plat/nonrealtime/bin/iosh "$0" "$@"

# TclTk script for tkemc gui

# Notes
# This script presents a canvas with i/o condition displays
# Based on a Fred Proctor post to emc@nist.gov
#

wm title . "IO"
global array buffer

# create the main window top frame
set top [frame .ioshow]
pack $top

message $top.message1 -text "Shows the condition of parallel port pins." \
   -justify center -aspect 400

set address 0x378

radiobutton $top.radio1 -text 0x378 -variable address -value 0x378 \
    -relief groove -command compute -anchor w -padx 20
radiobutton $top.radio2 -text 0x3BC -variable address -value 0x3BC \
    -relief groove -command compute -anchor w -padx 20
radiobutton $top.radio3 -text 0x278 -variable address -value 0x278 \
    -relief groove -command compute -anchor w -padx 20
button $top.b -text "Toggle Labels" -command {setLabels}
label $top.l -text "  Output        Input    "

button $top.button1 -bg darkgray\
    -font {Helvetica -12 bold} -text CANCEL -command {destroy .}
set c [canvas $top.canvas]
$c configure -height 190 -width 140
label $top.l1 -textvariable thislabelname
pack $top.message1 $top.radio1 $top.radio2 $top.radio3 $top.b $top.l $c $top.l1 $top.button1 -side top -fill x

for {set i 0} {$i < 12} {incr i 1} {
    $c create oval 5 [expr $i * 15 + 5] 15 [expr $i * 15 + 15] -fill green
}
for {set i 0} {$i < 5} {incr i 1} {
    $c create oval 75 [expr $i * 15 + 5] 85 [expr $i * 15 + 15] -fill green
}

# Attempt to set labels for io parport by reading ini file.
# Need the same number of labels as signals
set io_in_sigs {ESTOP_SENSE_INDEX  LUBE_SENSE_INDEX}
set io_in_labels {"estp" "lube" "oth"}
set io_out_sigs {SPINDLE_FORWARD_INDEX  SPINDLE_REVERSE_INDEX \
    MIST_COOLANT_INDEX  FLOOD_COOLANT_INDEX SPINDLE_DECREASE_INDEX \
    SPINDLE_INCREASE_INDEX  ESTOP_WRITE_INDEX  SPINDLE_BRAKE_INDEX \
    SPINDLE_ON_INDEX }
set io_out_labels {"s-fwd" "s-rev" "mist" "flood" "s-dec" "s-inc" "estp" "brak" "spin" "lube" "oth"}

set in_sig_map {"none" "none" "none" "none" "none"}
set i 0
foreach insig $io_in_sigs {
    set pinnum [emc_ini $insig EMCIO]
    set in_sig_map [lreplace $in_sig_map $pinnum $pinnum [lindex $io_in_labels $i]]
    incr i
}

set out_sig_map {"none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none"}
set i 0
foreach outsig $io_out_sigs {
    set pinnum [emc_ini $outsig EMCIO]
    set out_sig_map [lreplace $out_sig_map $pinnum $pinnum [lindex $io_out_labels $i]]
    incr i
}

set labelnames Number

proc setLabels {} {
    global c labelnames thislabelname out_sig_map in_sig_map
    set thislabelname $labelnames
    switch $labelnames {
        Number {
            set leftdef {0 1 2 3 4 5 6 7 8 9 10 11 12}
            set rightdef {0 1 2 3 4 }
            set labelnames Port_Pin
        }
        Port_Pin {
            set leftdef {p2 p3 p4 p5 p6 p7 p8 p9 p1 p14 p16 p17}
            set rightdef {p15 p13 p12 p11 p10}
            set labelnames Port_Name
        }
        Port_Name {
            set leftdef {d0 d1 d2 d3 d4 d5 d6 d7 c0 c1 c2 c3 c4}
            set rightdef {s3 s4 s5 s6 s7}
            set labelnames Stepper
        }
        Stepper {
            set leftdef {a0d a0s a1d a1s a2d a2s a3d a3s a4d a4s a5d a5s}
            set rightdef {"-lm" "+lm" "hom" "prb" "---"}
            set labelnames IO_Signals
        }
        IO_Signals {
            set leftdef $out_sig_map
            set rightdef $in_sig_map
            set labelnames Number
        }
    }
    $c delete labelz
    for {set i 0} {$i < 12} {incr i 1} {
        set label "[lindex $leftdef $i]"
        $c create text 25 [expr $i * 15 + 10] -text $label -anchor w -tag labelz
    }
    for {set i 0} {$i < 5} {incr i 1} {
        set label "[lindex $rightdef $i]"
        $c create text 95 [expr $i * 15 + 10] -text $label -anchor w -tag labelz
    }
}

setLabels

proc compute {} {
    global address buffer
    if {$address == 0x278} {
        set buffer(1) 0x278
        set buffer(2) 0x27A
        set buffer(3) 0x279
    } elseif {$address == 0x378} {
        set buffer(1) 0x378
        set buffer(2) 0x37A
        set buffer(3) 0x379
    } elseif {$address == 0x3BC} {
        set buffer(1) 0x3BC
        set buffer(2) 0x3BE
        set buffer(3) 0x3BD
    } else {
        set address "HUH?"
    }
}

compute

# 'ioShowUpdate' updates the dynamic value repeatedly
proc ioShowUpdate {} {
    global c address buffer

    set value1 [inb $buffer(1)]
    set value2 [inb $buffer(2)]
    set value3 [inb $buffer(3)]
    set value3 [expr $value3 >> 3]

    for {set i 1} {$i <= 8} {incr i 1} {
        if {$value1 % 2} {
            $c itemconfigure $i -fill red
        } else {
            $c itemconfigure $i -fill green
        }
        set value1 [expr $value1 / 2]
    }

    for {set i 9} {$i <= 12} {incr i 1} {
        if {$value2 % 2} {
            $c itemconfigure $i -fill red
        } else {
            $c itemconfigure $i -fill green
        }
        set value2 [expr $value2 / 2]
    }

    for {set i 13} {$i <= 17} {incr i 1} {
        if {$value3 % 2} {
            $c itemconfigure $i -fill red
        } else {
            $c itemconfigure $i -fill green
        }
        set value3 [expr $value3 / 2]
    }

    # schedule this again
    after 100 ioShowUpdate
}

# start it
ioShowUpdate

