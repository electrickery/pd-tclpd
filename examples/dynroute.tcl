package require Tclpd 0.3.0
package require TclpdLib 0.20

# dynroute: dynamically route messages based on first element
# non-matching arguments are sent to last inlet
# constructor: <float>   specify the number of outlets (default: 1)
# send commands to the right inlet
# available commands:
# add <atom> <float>     route selector <atom> to output number <float>
# remove <atom> <float>  remove previously created routing
# clear

proc+ dynroute::constructor {self args} {
    pd::add_inlet $self list

    set @num_outlets [pd::arg 0 int]
    if {$@num_outlets < 0} {set @num_outlets 2}

    for {set i 0} {$i < $@num_outlets} {incr i} {
        pd::add_outlet $self list
    }

    set @routing {}
}

proc+ dynroute::0_list {self args} {
    set sel [pd::arg 0 any]
    set out [expr {$@num_outlets-1}]
    catch {set out [dict get $@routing $sel]}
    pd::outlet $self $out list $args
}

proc+ dynroute::1_add {self args} {
    if { [llength $args] < 2 } {
        return -code error "add requires two arguments <any> <int>."
    }
    set sel [pd::arg 0 any]
    set out [pd::arg 1 int]
    if {$out < 0 || $out >= $@num_outlets} {
        return -code error "error: add: outlet number out of range"
    }
    dict set @routing $sel $out
}

proc+ dynroute::1_remove {self args} {
    if { [llength $args] < 2 } {
        return -code error "remove requires two arguments <any> <int>."
    }
    set sel [pd::arg 0 any]
    set out [pd::arg 1 int]
    if {$out < 0 || $out >= $@num_outlets} {
        return -code error "error: remove: outlet number out of range"
    }
    catch {dict unset @routing $sel $out}
}

proc+ dynroute::1_clear {self} {
    set @routing {}
}

proc+ dynroute::1_status {self} {
    dict for {key value} $@routing {
        pd::post "$key: $value"
    }
}

pd::class dynroute
