package require Tclpd 0.3.0
package require TclpdLib 0.20

# counting averager - calculates and outputs the 
# average of all incoming values between the bangs. 
# F.J. Kraan, 2013-12-25
# 

proc+ countingAveragerTcl::constructor {self args} {
    pd::add_inlet $self float

    set @num_outlets 2
    for {set i 0} {$i < $@num_outlets} {incr i} {
        pd::add_outlet $self float
    }

    set @config [dict create counter 0 average 0]
}

proc+ countingAveragerTcl::0_float {self args} {
    set inlet0Value [pd::arg 0 float]
    set previousCounter [dict get $@config counter]
    set counter [expr ($previousCounter + 1.)]
    dict set @config counter $counter
    set average [dict get $@config average]

    set inputFactor   [expr (1. / $counter)]
    set averageFactor [expr ($previousCounter / $counter)]

    set inputPart   [expr ($inputFactor   * $inlet0Value)]
    set averagePart [expr ($averageFactor * $average)]

    set average [expr ($inputPart + $averagePart)]
    dict set @config average $average

    pd::outlet $self 0 float $average
    pd::outlet $self 1 float $counter
}

proc+ countingAveragerTcl::0_bang {self args} {
    dict set @config counter 0
    dict set @config average 0
    pd::outlet $self 0 float 0
    pd::outlet $self 1 float 0
}

proc+ countingAveragerTcl::1_bang {self args} {
    dict set @config counter 0
    dict set @config average 0
}

pd::class countingAveragerTcl
