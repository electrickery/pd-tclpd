package require Tclpd 0.3.0
package require TclpdLib 0.20

# Hello World example

#proc+ differs from the standard Tcl proc in that variables are shared 
# for all proc+'s with the same namespace, helloWorld:: in this case.

set object helloWorld

# The box and one inlet is default created for each object
proc+ helloWorld::constructor {self args} {
    pd::add_outlet $self list ;# outlet 0
    set @message { Hello World!}
}


proc+ helloWorld::0_bang {self args} {
    pd::outlet $self 0 list [pd::add_selectors [list HelloWorld]]
    pd::post $@message
}


proc+ helloWorld::0_anything {self args} {
    set @message [pd::strip_selectors $args]
    pd::outlet $self 0 $@message
}

# Define the class in pd.
pd::class helloWorld

