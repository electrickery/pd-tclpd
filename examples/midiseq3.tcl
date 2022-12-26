package require Tclpd 0.3.0
package require TclpdLib 0.20

proc+ midiseq3::constructor {self args} {
    # add second inlet
    pd::add_inlet $self list ;# 1

    # add outlet
    pd::add_outlet $self float ;# 0
    pd::add_outlet $self float ;# 1
    pd::add_outlet $self float ;# 2

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

proc+ midiseq3::0_list {self args} {
    
    set key   [pd::arg 0 float]
    set value [pd::arg 1 float]
    set channel [pd::arg 2 float]

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
#    foreach i $@sequenceList {
#        puts "listItem: $i"    
#    }
#    puts "----"
}

proc+ midiseq3::1_bang {self} {
    if {$@currentKey != ""} {
        pd::outlet $self 2 float $@currentKey
        pd::outlet $self 1 float 0
        pd::outlet $self 0 float $@channel
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
    pd::outlet $self 2 float $key
    pd::outlet $self 1 float $@outVelocity
    pd::outlet $self 0 float $@channel
} 

pd::class midiseq3
