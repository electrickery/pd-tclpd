# TCL objectized library for PD api
# by Federico Ferri <mescalinum@gmail.com> - (C) 2007-2011

package provide TclpdLib 0.19

package require Tcl 8.5
package require Tclpd 0.2.3

set verbose 0

namespace eval :: {
    proc proc+ {name arglist body} {
        set body2 [concat "global _;" [regsub -all @(\\\$?\[\\w\\?\]+) $body _(\$self:\\1)]]
        uplevel #0 [list proc $name $arglist $body2]
    }
}

namespace eval ::pd {
    proc error_msg {m} {
        return "pdlib: [uplevel {lindex [info level 0] 0}]: error: $m"
    }

    proc add_inlet {self sel} {
        if $::verbose {post [info level 0]}
        variable _
        tclpd_add_proxyinlet [tclpd_get_instance $self]
    }

    proc add_outlet {self {sel {}}} {
        if $::verbose {post [info level 0]}
        variable _
        if {$sel == {}} {
            set o [outlet_new [tclpd_get_object $self] [null_symbol]]
        } else {
            if {[lsearch -exact {bang float list symbol} $sel] == -1} {
                return -code error [error_msg "unsupported selector: $sel"]
            }
            set o [outlet_new [tclpd_get_object $self] [gensym $sel]]
        }
        lappend _($self:x_outlet) $o
        return $o
    }

    # used inside class for outputting some value
    proc outlet {self n sel args} {
        if $::verbose {post [info level 0]}
        variable _
        set outlet [lindex $_($self:x_outlet) $n]
        switch -- $sel {
            float {
                set v [lindex $args 0]
                outlet_float $outlet $v
            }
            symbol {
                set v [lindex $args 0]
                outlet_symbol $outlet $v
            }
            list {
                set v [lindex $args 0]
                set sz [llength $v]
                set aa [new_atom_array $sz]
                for {set i 0} {$i < $sz} {incr i} {
                    set_atom_array $aa $i [lindex $v $i]
                }
                outlet_list $outlet [gensym "list"] $sz $aa
                delete_atom_array $aa $sz
            }
            bang {
                outlet_bang $outlet
            }
            default {
                set v [lindex $args 0]
                set sz [llength $v]
                set aa [new_atom_array $sz]
                for {set i 0} {$i < $sz} {incr i} {
                    set_atom_array $aa $i [lindex $v $i]
                }
                outlet_anything $outlet [gensym $sel] $sz $aa
                delete_atom_array $aa $sz
            }
        }
    }

    proc read_class_options {classname options} {
        set patchable_flag 1
        set noinlet_flag 0

        foreach {k v} $options {
            switch -- $k {
                -patchable {
                    if {$v != 0 && $v != 1} {
                        return -code error [error_msg "-patchable must be 0/1"]
                    }
                    set patchable_flag $v
                }
                -noinlet {
                    if {$v != 0 && $v != 1} {
                        return -code error [error_msg "-noinlet must be 0/1"]
                    }
                    set noinlet_flag $v
                }
                default {
                    return -code error [error_msg "unknown option: $k"]
                }
            }
        }

        proc ::${classname}::dispatcher {self function args} "
            if {\$function == \"method\"} {
                set inlet \[lindex \$args 0\]
                set selector \[lindex \$args 1\]
                set argsr \[lrange \$args 2 end\]
                set i_s ::${classname}::\${inlet}_\${selector}
                set i_a ::${classname}::\${inlet}_anything
                if {\[info procs \$i_s\] != {}} {
                    uplevel \[linsert \$argsr 0 \$i_s \$self\]
                } elseif {\[info procs \$i_s\] == {} && \[info procs \$i_a\] != {}} {
                    uplevel \[linsert \$argsr 0 \$i_a \$self \[pd::add_selector \$selector\]\]
                } else {
                    return -code error \"${classname}: no such method: \$i_s\"
                }
            } elseif {\$function == \"widgetbehavior\"} {
                set subfunction \[lindex \$args 0\]
                set argsr \[lrange \$args 1 end\]
                uplevel \[linsert \$argsr 0 ::${classname}::\${function}_\${subfunction} \$self]
            } else {
                uplevel \[linsert \$args 0 ::${classname}::\$function \$self\]
            }
        "

	# some dummy function to suppress eventual errors if they are not deifned:
	proc ::${classname}::0_loadbang {self} {}

        # TODO: c->c_gobj = (typeflag >= CLASS_GOBJ)
        set flag [expr {
            8 * ($noinlet_flag != 0) +
            3 * ($patchable_flag != 0)
        }]

        return $flag
    }

    # this handles the pd::class definition
    proc class {classname args} {
        if $::verbose {post [lrange [info level 0] 0 end-1]}

        set flag [read_class_options $classname $args]

        # this wraps the call to class_new()
        tclpd_class_new $classname $flag
    }

    proc guiclass {classname args} {
        if $::verbose {post [lrange [info level 0] 0 end-1]}

        set flag [read_class_options $classname $args]

        # this wraps the call to class_new()
        tclpd_guiclass_new $classname $flag
    }

    # wrapper to post() withouth vargs
    proc post {args} {
        poststring2 [concat {*}$args]
    }

    proc args {} {
        return [uplevel 1 "llength \$args"]
    }

    proc arg {n {assertion any}} {
        upvar 1 args up_args
        set up_args_len [llength $up_args]
        if {$n < 0 || $n >= $up_args_len} {
            return -code error "fatal: argument $n out of range"
        }
        set v [lindex $up_args $n]
        set i 0
        if {[llength $v] != 2} {
            return -code error "fatal: malformed atom: $v (full args: $up_args)"
        }
        foreach {selector value} $v {break}
        if {$assertion == {int}} {
            set assertion {float}
            set i 1
        }
        if {$assertion != {any}} {
            if {$selector != $assertion} {
                return -code error "arg #$n is $selector, must be $assertion"
            }
        }
        if {$assertion == {float} && $i && $value != int($value)} {
            return -code error "arg #$n is float, must be int"
        }
        if {$assertion == {float} && $i} {
            return [expr {int($value)}]
        } else {
            return $value
        }
    }

    proc default_arg {n assertion defval} {
        if {$n < [uplevel "pd::args"]} {
            return [uplevel "pd::arg $n $assertion"]
        } else {
            return $defval
        }
    }

    proc strip_selectors {pdlist} {
        set r {}
        foreach atom $pdlist {
            if {[llength $atom] != 2} {
                return -code error "Malformed pd list!"
            }
            lappend r [lindex $atom 1]
        }
        return $r
    }

    proc add_selector {s} {
        return [list [lindex {float symbol} [catch {expr $s}]] $s]
    }

    proc add_selectors {tcllist} {
        set r {}
        foreach i $tcllist {
            lappend r [add_selector $i]
        }
        return $r
    }

    proc strip_empty {tcllist} {
        set r {}
        foreach i $tcllist {
            if {$i == "empty"} {lappend r {}} {lappend r $i}
        }
        return $r
    }

    proc add_empty {tcllist} {
        set r {}
        foreach i $tcllist {
            if {$i == {}} {lappend r "empty"} {lappend r $i}
        }
        return $r
    }

    # mechanism for uploading procs to gui interp, without the hassle of escaping [encoder]
    proc guiproc {name argz body} {
        # upload the decoder
        sys_gui "proc guiproc {name argz body} {set map {}; for {set i 0} {\$i < 256} {incr i} {lappend map %\[format %02x \$i\] \[format %c \$i\]}; foreach x {name argz body} {set \$x \[string map \$map \[set \$x\]\]}; uplevel \[list proc \$name \$argz \$body\]}\n"
        # build the mapping
        set map {}
        for {set i 0} {$i < 256} {incr i} {
            set chr [format %c $i]
            set hex [format %02x $i]
            if {[regexp {[^A-Za-z0-9]} $chr]} {lappend map $chr %$hex}
        }
        # encode data
        foreach x {name argz body} {set $x [string map $map [set $x]]}
        # upload proc
        sys_gui "guiproc $name $argz $body\n"
    }

    proc get_binbuf {self} {
        set binbuf [tclpd_get_object_binbuf $self]
        set len [binbuf_getnatom $binbuf]
        set result {}
        for {set i 0} {$i < $len} {incr i} {
            set atom [tclpd_binbuf_get_atom $binbuf $i]
            set selector [atom_type_string $atom]
            set value {?}
            if {$selector == "float"} {
                set value [atom_float_value $atom]
            } elseif {$selector == "symbol"} {
                set value [atom_symbol_value $atom]
            }
            lappend result [list $selector $value]
        }
        return $result
    }
}

