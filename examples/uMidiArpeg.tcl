package require Tclpd 0.3.0
package require TclpdLib 0.20

set objectName uMidiArpeg

proc+ ${objectName}::constructor {self args} {
    # add second inlet
    pd::add_inlet $self list ;# 1

    # add outlet
    pd::add_outlet $self list ;# 0

    # initialises the key list
    set @sequenceList {}

    # create pointer and sets it to the 'empty' position
    set @index -1

    # default velocity
    set @outVelocity 64

    # default channel
    set @channel 1

    # current key
    set @currentKey ""
}

proc+ ${objectName}::0_list {self args} {
    
    set key   [pd::arg 0 float]
    set value [pd::arg 1 float]
#    set channel [pd::arg 2 float]  ; # not used

    if {$value == 0.0} {
        set found [lsearch $@sequenceList $key]
        set @sequenceList [lreplace $@sequenceList $found $found]
        if {[llength $@sequenceList] == 0} {
            set @index -1
        }
    } else {
        if {[lsearch $@sequenceList $key] > -1} {return}
        lappend @sequenceList $key
    }
}

proc+ ${objectName}::1_bang {self} {
    if {$@currentKey != ""} {
        pd::outlet $self 0 list [pd::add_selectors [list $@currentKey 0 $@channel]]
        set @currentKey ""
    }
    set slLength [llength $@sequenceList]
    if {$slLength == 0} {return}
    if {$slLength <= $@index} {
        set @index -1
    }
    incr @index
    # checks the index points to a valid element
    if {$slLength <= $@index} { set @index 0 }
    set key [expr int([lindex $@sequenceList $@index])]
    set @currentKey $key
    pd::outlet $self 0 list [pd::add_selectors [list $@currentKey $@outVelocity $@channel]]
} 

proc+ ${objectName}::1_list {self args} {
    if {[pd::arg 0 float] < 0 && [pd::arg 0 float] > 127} { return }
    if {[pd::arg 1 float] < 0 && [pd::arg 1 float] > 16} { return }
    set @outVelocity [pd::arg 0 float] 
    set @channel     [pd::arg 1 float]
}

proc+ ${objectName}::1_float {self args} {
    if {[pd::arg 0 float] < 0 && [pd::arg 0 float] > 127} { return }
    set @outVelocity [pd::arg 0 float]
}

proc+ ${objectName}::0_bang {self args} {
    if {$@currentKey ne ""} {
        pd::outlet $self 0 list [pd::add_selectors [list $@currentKey 0 $@channel]]
    }
}

pd::class ${objectName}
