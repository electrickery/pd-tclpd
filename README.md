# Tclpd library

This repository is a clone of the Pd-extended SVN repository at 
https://sourceforge.net/p/pure-data/svn/HEAD/tree/trunk/externals/loaders/tclpd/, 
created via the https://git.puredata.info/cgit/ SVN-to-GIT repository 
by IOhannes m zmoelnig.

The main purpose for this fork is to add a more modern build system which 
allows creating easy distributions for multiple platforms. But some 
updating of documentation and help-files will also occur.

<p align="center"><img src="bitmap.tcl.png">

## Objects

        bitmap.tcl       - bitmap graphical object; an interactive two-dimensional binary matrix 
        colorpicker.tcl  - helper object for the properties object
        dynreceive.tcl   - dynreceive object; a message receive object, with dynamic receive symbol
        dynroute.tcl     - dynroute object; dynamic routing of key-value sets based on key-output assignments
        helloWorld.tcl   - helloWorld; simple demo object demonstrating a basic object in Tcl
        list_change.tcl  - list_change object; demonstrated Tcl list operations and Pd-Tcl list interfacing 
        logPost.tcl      - demo object for Pd logpost API
        properties.tcl   - helper object for graphical Tcl/Tk objects, for controlling the objects properties
        slider2.tcl      - slider2 graphical object; a reimplementation of the slider object

## Helper routines

Tclpd makes all definitions in m_pd.h and g_canvas.h available to Tcl/Tk 
code via the swig library (https://www.swig.org/). In addition the 
following procedures are made available (tclpd.tcl):

    proc error_msg {m} {
    proc add_inlet {self sel} {
    proc add_outlet {self {sel {}}} {
    proc outlet {self numInlet selector args} {    # used inside class for outputting some value
    proc read_class_options {classname options} {
    proc class {classname args} {                  # this handles the pd::class definition
    proc guiclass {classname args} {
    proc post {args} {                             # wrapper to post() withouth vargs
    proc args {} {
    proc arg {n {assertion any}} {
    proc default_arg {n assertion defval} {
    proc strip_selectors {pdlist} {                # converts a pd list to a Tcl list
    proc add_selector {s} {                        # a Tcl string to a pd symbol
    proc add_selectors {tcllist} {                 # converts a Tcl list to a pd list
    proc strip_empty {tcllist} {
    proc add_empty {tcllist} {
    proc guiproc {name argz body} {                # mechanism for uploading procs to gui interp, without the hassle of escaping [encoder]
    proc get_binbuf {self} {



Fred Jan Kraan, 
fjkraan@electrickery.nl,
2022-12-22
