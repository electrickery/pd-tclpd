#!/usr/bin/env tclsh
#
# pdParse.tcl - Parses pd patch files. The goal it to make editing 
# possible. Based on 
# http://puredata.info/Members/pierpower/Favorites/fileformat
# fjkraan@electrickery.nl, 2022012-27
# version 0.6

# pdParse.tcl currently parses a Pd patch and puts each line in a list
# with an 'item-locator' prefixed. The item locator is the combination
# of the patch number and object number, separated by a dot. Non-object
# items have "--" as object number, as they do not count. Some 
# indentation is added, but this is just presentation. 
# The list is created to make a future streaming editor for pd-patches
# possible, as removing objects and fix the connections can now be done
# on a line-by-line basis.

# ToDo: - get rid of the 'global lines lines' as it shouldn't be needed.

if {$argc < 1} {
    error "Usage: pdParse.tcl fileName \[removePattern\]"
}
set file   [open [lindex $argv 0] r]
set object [lindex $argv 1]

proc fixRestoreObjNumber {lines objCount} {
	# fixes the object number. The #X restore is detected in the 
	# subpatch but it should have an object number from one level
	# higher. Hence this kludge.
	set lastLine [lindex $lines end]
	if {[regexp -- "\#X restore" $lastLine]} {
		regsub {\?\?} $lastLine $objCount lastLine
	}
	return $lastLine
}

proc parseCanvas {parentNo oldSpaces} {
	set spaces " $oldSpaces"
	global file file
	global lines lines
	global number number
	incr number 
	set myNumber $number
	set objCount 0
	while {[gets $file line] >= 0} {
	    # constructing complete lines
	    set lastChar [string index $line end]
	    while {![string equal $lastChar \;]} {
		set lineAppendix ""
		gets $file lineAppendix
		set line "$line\n$lineAppendix"
		set lastChar [string index $line end]
	    } 
	    # parsing the lines
	    # end sub patch handler, a #X special case
	    if {[regexp -- "\#X restore" $line]} {
		lappend lines "${parentNo},??: $line"
		return $lines
	    }
	    # start sub patch handler
	    if {[regexp -- \#N $line]} {
		lappend lines "${myNumber},--: $line"
		set lines [parseCanvas $myNumber $spaces]
		set newLine [fixRestoreObjNumber $lines $objCount]
		set lines [lreplace $lines end end $newLine]
		incr objCount
		continue
	    }
	    # normal object lines handler
	    if {[regexp -- \#X $line]} {
		if { [regexp -- {\#X connect} $line] } {
			lappend lines "${myNumber},--: $line"
		} else {
			lappend lines "${myNumber},$objCount: $line"
			incr objCount
		}
	    }
	    # array contents handler
	    if {[regexp -- \#A $line]} {
		lappend lines "${myNumber},--: $line"
	    }
	}
	return $lines
}

proc addSpace { spaces } {
	return "$spaces "
}

proc removeSpace { spaces } {
	return [string replace $spaces end end]
}

#N canvas     [x_pos] [y_pos]
#X floatatom  [x_pos] [y_pos]
#X msg        [x_pos] [y_pos]
#X obj        [x_pos] [y_pos]
#X restore    [x_pos] [y_pos]
#X symbolatom [x_pos] [y_pos]
#X text       [x_pos] [y_pos]
proc recordMatch { line } {
	set lineAsList [split $line " "]
	set chunk_element "[lindex $lineAsList 1] [lindex $lineAsList 2]"
	set coordinateObjects { {\#X floatatom} {\#X msg} {\#X obj} {\#X restore} {\#X symbolatom} {\#X text} }
	foreach object $coordinateObjects {
		if {[string match $object $chunk_element]} {
			return 1
		}
	}
	return 0
}

proc getDictValue { dictionary key default } {
	if { [dict exists $dictionary $key] } {
		return [dict get $dictionary  $key]
	} else {
		return $default
	}
}

set number -1

set lines {}

set lines [parseCanvas $number ""]

#close $file

set spaces ""

if {[string match $object ""]} {
#puts "===================== indenting lister ====================="
# list items from $lines. format <patchNo>.<objectNo>: <objectSpecification> 
	foreach item  $lines {
		if {[regexp -- "\#X restore" $item]} {
			set spaces [removeSpace $spaces]
		}
		puts "${spaces}$item"
		if {[regexp -- "\#N canvas" $item]} {
			set spaces [addSpace $spaces]
		}
	}
}

set patchNum  ""
set objectNum ""
set outObjectNum ""
set inObjectNum ""
set resultList {}
set minXPerPatch {}
set minYPerPatch {}

if {![string match $object ""]} {
#	puts "===================== find and ... ====================="
	set minX ""
	set minY ""
	set maxX ""
	set maxY ""
	foreach line $lines {
		if {[recordMatch $line] == 1} {
#			puts "found match: $line"
			set lineAsList [split $line " "]
			set patchNoObjNo [lindex $lineAsList 0]
#			puts "-->'[regexp {^(\d+),} $patchNoObjNo]'"
			regexp {^(\d+),} $patchNoObjNo all patchNo
			set xCoor [lindex $lineAsList 3]
			set yCoor [lindex $lineAsList 4]
			set minX [getDictValue $minXPerPatch $patchNo ""]
			set minY [getDictValue $minYPerPatch $patchNo ""]
#			puts "p,x,y: $patchNo:$xCoor, $yCoor"
			if { $minX == "" || $minX > $xCoor } { set minX $xCoor }
			if { $minY == "" || $minY > $yCoor } { set minY $yCoor }
			dict set minXPerPatch $patchNo $minX
			dict set minYPerPatch $patchNo $minY
		}
	}
#	dict for {key value} $minXPerPatch {
#		puts "patch $key, minX: $value, minY [dict get $minYPerPatch $key]"
#	}
	foreach line $lines {
#		puts "$line"
		if {[recordMatch $line] == 1} {
			set lineAsList [split $line " "]
			set patchNoObjNo [lindex $lineAsList 0]
			regexp {^(\d+),} $patchNoObjNo all patchNo
			set xCoor [lindex $lineAsList 3]
			set yCoor [lindex $lineAsList 4]
			set xOffset [getDictValue $minXPerPatch $patchNo ""]
			set yOffset [getDictValue $minYPerPatch $patchNo ""]
			if { ![string match $xOffset ""] } {
				set lineAsList [lreplace $lineAsList 3 3 [expr ($xCoor - $xOffset)]]
				set lineAsList [lreplace $lineAsList 4 4 [expr ($yCoor - $yOffset)]]
#				puts "  correction: $xCoor - $xOffset = [lindex $lineAsList 3], $yCoor - $yOffset = [lindex $lineAsList 4]"
				set line [join $lineAsList]
#				puts $line
			}
		}
		lappend resultList $line
	}
}

if {![string match $object ""]} {
#puts "===================== result lister ====================="
	foreach item $resultList {
	#	puts $item
		puts [join [lreplace [split $item] 0 0]]
	}
}


