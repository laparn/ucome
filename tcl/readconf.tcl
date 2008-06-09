# Generic configuration file parser 
# $Id: readconf.tcl,v 1.2 2001/01/11 17:09:02 canaliadmin Exp $
#
# All blank lines and lines begining with `#' or `;' are discarded.
# Each line must contain a key and a value separated by a `='.
# You can begin a section either with the syntax `section=something' or with
# the syntax `[something]'.
#
# Notes: 
#  - keys are not case sensitive
#  - a key must be a sequence of alphanumeric charaters or underscores
#

proc ReadConf { file var } {
    upvar $var va ;

    if [catch {open $file r} fileid] {
		error "readconf.tcl - ReadConf - $file type doesn't seem to be supported"
	return -code error
    } else {
	ReadConfChannel $fileid va ;
	close $fileid
    }
}


proc ReadConfChannel { fileid var } {
    upvar $var conf
    
    set line 0
    set prog ""
    set conf(order) ""
    while {![eof $fileid]} {
	incr line
	set data [string trim [gets $fileid]]

	
	# discard all blank lines
	# comments can begin with a '#' or a ';'
	if {![regexp "^\#|^\;|^\[ \t]*$" $data]} {
	    
	    # parse the line to find a new section
	    if [regsub {^\[ *([^\[]+)\]$} $data {section=\1} data] {
		set data [string trim $data]
	    }
	    # parse the line to find the keyword and the value
	    regexp "(\[a-zA-Z0-9_]+)\[ \t]*=\[ \t]*(.+)" $data trash key val
	    if [catch {

		# the keyword is not case sensitive: converted to lower case
		set key [string tolower [string trim $key]]
		set val [string trim $val]

		# if the key is 'section' then begin a new section
		if {$key == "section"} {
		    set prog $val					    
		} else {
		    if {$prog == ""} {
				error "readconf.tcl - ReadConfChannel - Error in configuration file, line $line - $data : missing `prog'  key"
				#exit 1
		    } else {
			# if the same key is found more than 1 time in a
			# section, then the value is appended
			if [info exist conf($prog.$key)] {
			    set data "$conf($prog.$key) $val"
			    regsub {\\n} $data "
" data
			    OrderedSet conf $prog.$key $data
			} else {
			    OrderedSet conf $prog.$key $val
			}
		    }
		}
		##		    puts ":$key:$val:"
	    } error] {
			error "readconf.tcl - ReadConfChannel - Error while parsing file, line $line - $data - : $error"
			#exit 1
	    }
	} else {
	    ##		puts "# skip"
	}
    }		     
}


proc ReadConfString { content var} {
    upvar $var conf
    
    set line 0
    set prog ""
    set conf(order) ""
    foreach current_line [split $content "\n"] {
        incr line
        set data [string trim $current_line]
        
        # discard all blank lines
        # comments can begin with a '#' or a ';'
        if {![regexp "^\#|^\;|^\[ \t]*$" $data]} {
            
            # parse the line to find a new section
            if [regsub {^\[ *([^\[]+)\]$} $data {section=\1} data] {
                set data [string trim $data]
            }
            # parse the line to find the keyword and the value
            regexp "(\[a-zA-Z0-9_]+)\[ \t]*=\[ \t]*(.+)" $data trash key val
            if [catch {

                # the keyword is not case sensitive: converted to lower case
                set key [string tolower [string trim $key]]
                set val [string trim $val]

                # if the key is 'section' then begin a new section
                if {$key == "section"} {
                    set prog $val                                           
                } else {
                    if {$prog == ""} {
                        error "Error in configuration string  , line $line - \"$data\" : missing `prog' key" 
                    } else {
                        # if the same key is found more than 1 time in a
                        # section, then the value is appended
                        if [info exist conf($prog.$key)] {
                            set data "$conf($prog.$key) $val"
                            regsub {\\n} $data "
" data
                            OrderedSet conf $prog.$key $data
                        } else {
                            OrderedSet conf $prog.$key $val
                        }
                    }
                }
                ##                  puts ":$key:$val:"
            } error] {
                error "Error in configuration file  , line $line - \"$data\" : $error"
            }
        } else {
            ##          puts "# skip"
        }
    }                
}

#
# Set a value in an array but keep track of the order
#
proc OrderedSet { array field val } {
    upvar $array ar

    lappend1 ar(order) $field
    set ar($field) $val
}

#
# Remove a value
#
proc RemoveValue { array val } {
    upvar $array ar

    if { [info exists ar($val)]} {
	unset ar($val)
    }
    set tmp_order [list]
    foreach item $ar(order) {
	if { $item != $val } {
	    lappend1 tmp_order $item
	}
    }
    set ar(order) $tmp_order

}


#
# Get the section's name from an array item
#
proc GetSection { var } {
    return [string range $var 0 [expr [string last . $var]-1 ]]
}

#
# Get the key's name from an array item
#
proc GetKey { var } {
    return [string range $var [expr [string last . $var]+1 ] end ]
}

#
# Get the list of the sections in a config array
#
proc GetSectionList { arr } {
    upvar $arr idb

    set l {}
    foreach { i trash } [array get idb *] {
	lappend1 l [GetSection $i]
    }    
    return $l
}

#
# Get the list of the sections in a config array
# the list reflects the order in which the variables have been set.
#
proc OrderedGetSectionList { arr } {
    upvar $arr idb

    set l {}
    foreach i $idb(order) {
	lappend1 l [GetSection $i]
    }    
    return $l
}

#
# Get all item from a section in a array without section name
#
proc GetItemFromSection { var section res} {
    upvar $var va;
    upvar $res re;

    catch {unset re};
    foreach item [array names va "$section.*"] {
	if [string equal  [GetSection $item] $section ] {
	    if [expr [string equal [GetKey $item] action ] == 0] {
		set re([GetKey $item]) $va($item);
	    }
	}
    }
}

#
# Get name of section x in OrderedGetSectionList
#
proc GetNameSectionNumber { arr x } {
    upvar $arr ar
    set list [OrderedGetSectionList ar]
    return [lindex $list $x]
}

#
# Get number of section in OrderedGetSectionList
#
proc GetNumberOfSection { arr } {
    upvar $arr ar
    set list [OrderedGetSectionList ar]
    return [llength $list]
}

#
# Get the list of the name in a config array
# similar to `array get' but the order is kept intact
#
proc OrderedArrayGet { arr { pattern * } } {
    upvar $arr idb

    set l {}
    foreach i $idb(order) {
	if [string match $pattern $i] {
	    lappend l $i
	    lappend l $idb($i)
	}
    }    
    return $l
}

#
# Append to the list if it's unique
#
proc lappend1 { listvar item } {
    upvar $listvar list

    if {[info exists list]} {
	if {[lsearch -exact $list $item] == -1} {
	    lappend list $item
	}
    } else {
	set list $item
    }
}


###################

# 
# Generic configuration file writer v0.90
#
# Can rebuild a configuration file read with ReadConf 
#
# Notes: 
#  - keys are not case sensitive
#  - a key must be a sequence of alphanumeric charaters or underscores
#
proc WriteConf { { file ./config } var { comments "" } } {
    upvar $var conf

    # try to save the old configuration file
    #if [file exists $file] {
#	set date [clock format [clock seconds] -format %m%d%y%H%M%S]
#	catch {file rename $file $file.$date}
#    }
    if [catch {open $file w 0664 } fileid] {
	puts stderr $fileid
	return -code error
    } else {
	puts $fileid "
# $comments
# 
# File Automatically generated by WriteConf [clock format [clock seconds]]
#
"
	# write each section
	foreach section [OrderedGetSectionList conf] {
	    # puts "\[ $section \]"
	    puts $fileid "\[ $section \]"
	    foreach {var val} [OrderedArrayGet conf $section.*] {
		puts $fileid "[GetKey $var]\t= $val"
		# puts "[GetKey $var]\t= $val"
	    }
	    puts $fileid ""
	}
	close $fileid
    }
}

#
# remove all section appearing in the old config array 
# from the new config array
#
proc RemoveDupConf { new old } {
    upvar $new n
    upvar $old o
    
    foreach sect [OrderedGetSectionList o] {
	foreach { i trash } [array get n $sect.*] {
	    set idx [lsearch $n(order) $i]
	    if {$idx != -1} {
		# delete the value
		unset n($i)
		# and remove the key from the order list
		set n(order) [lreplace $n(order) $idx $idx]
	    }
	}
    }
}

#
# merge all section appearing in the old config array 
# with the new config array
#
proc MergeDupConf { new old } {
    upvar $new n
    upvar $old o
    
    foreach { oldvar oldval } [array get o] {
	if {[info exists n($oldvar)] && $oldvar != "order"} {
	    set n($oldvar) $oldval
	}
    }
}

#
# Remove a whole section
#
proc OrderedRemoveSection { array sect } {
    upvar $array ar

    set idx 0
    foreach i $ar(order) {
	if [string match "$sect.*" $i] {
	    # remove the package from the database
	    set ar(order) [lreplace $ar(order) $idx $idx]
	    # free the memory
	    unset ar($i)
	    # we have removed a list element so decrement idx
	    incr idx -1
	}
	incr idx
    }
}


#
# Rename a section 
#
proc OrderedRenameSection { array sect new_name } {
    upvar $array ar

    foreach i [array names ar "${sect}.*"] {
	set ar($new_name.[GetKey $i]) $ar($i)
	unset ar($i)
    }
    
    set tmp_order ""
    foreach i $ar(order) { 
	regsub "^${sect}(\\..+)" $i "${new_name}\\1" j 
	lappend1 tmp_order $j
    }
    set ar(order) $tmp_order

}


#
# retrun 1 if the section exists
#
proc SectionExists { array section_name } {
    upvar $array ar
    foreach section [OrderedGetSectionList ar ] {
	if { $section == $section_name } {
	    return 1
	}
    }
    return 0
}

#
# Copy section in new section
#
proc DuplicateSection { array sect new_name } {
    upvar $array ar

    foreach i [array names ar "${sect}.*"] {
	set ar($new_name.[GetKey $i]) $ar($i)
	regsub "^${sect}(\\..+)" $i "${new_name}\\1" j 
	lappend1 ar(order) $j
    }
}

#
# Up a section
#
proc UpSection { array sect } {
    upvar $array ar

    set tmp_order [list]
    set tmp_section [list]
    set last_section ""
    foreach item $ar(order) {
	if { [GetSection $item] == $last_section } {
	    if { [GetSection $item] == $sect } {
		lappend1 tmp_order $item
	    } else {
		lappend1 tmp_section $item
	    }
	} else {
	    if { [GetSection $item] == $sect } {
		lappend1 tmp_order $item
	    } else {
		foreach i $tmp_section { lappend1 tmp_order $i }
		set tmp_section $item
	    }
	    set last_section [GetSection $item]
	}
    }
    foreach i $tmp_section { lappend1 tmp_order $i }
    set ar(order) $tmp_order
}

#
# Down a section
#
proc DownSection { array sect } {
    upvar $array ar

    set tmp_order [list]
    set tmp_section [list]
    set last_section ""
    foreach item $ar(order) {
	if { [GetSection $item] == $last_section } {
	    if { [GetSection $item] == $sect } {
		lappend1 tmp_section $item
	    } else {
		lappend1 tmp_order $item
	    }
	} else {
	    if { [GetSection $item] == $sect } {
		lappend1 tmp_section $item
	    } else {
		if { $last_section != $sect } {
		    foreach i $tmp_section { lappend1 tmp_order $i }
		}
		lappend tmp_order $item
	    }
	    set last_section [GetSection $item]

	}
    }
    foreach i $tmp_section { lappend1 tmp_order $i }
    set ar(order) $tmp_order
}
