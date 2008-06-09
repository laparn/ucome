# Here there is a trick, I create a string with the standard procedure
# for debugging. In putting it in each namespace, I can have a debug
# and switch it on and off for each part of the program. DEBUG_ALL will
# activate all debugging (this is heavy).
global ::DEBUG_PROCEDURES
set ::DEBUG_PROCEDURES {
	set LOCAL_DEBUG 0
	set LOCAL_DEBUG_COLOR ""
	proc fas_debug { message } {
		global DEBUG_ALL
		global DEBUG
		variable LOCAL_DEBUG

		if { $DEBUG && ( $DEBUG_ALL || $LOCAL_DEBUG ) } {
			set indent ""
			for { set i 1 } { $i < [info level] } { incr i } {
				append indent "  "
			}
			variable LOCAL_DEBUG_COLOR
			fas_debug_puts "${indent}${message}" $LOCAL_DEBUG_COLOR
		}
	}
	proc fas_fastdebug { message } {
		global DEBUG
		global DEBUG_ALL
		variable LOCAL_DEBUG

		if { $DEBUG && ( $LOCAL_DEBUG || $DEBUG_ALL )} {
			set indent ""
			for { set i 1 } { $i <  [info level] } { incr i } {
				append indent "  "
			}
			variable LOCAL_DEBUG_COLOR
			uplevel 1 fas_debug_puts "\"${indent}${message}\"" $LOCAL_DEBUG_COLOR
		}
	}


	proc fas_debug_parray { current_array args } {
		global DEBUG
		global DEBUG_ALL
		variable LOCAL_DEBUG

		if { $DEBUG && ( $LOCAL_DEBUG || $DEBUG_ALL ) } {
			upvar $current_array display_array
			eval fas_debug_parray_puts display_array $args
		}
	}
}

proc fas_debug_puts { message {color ""}} {
	global DEBUG_STRING
	if { $color != "" } {
		append DEBUG_STRING "<font color=\"$color\">${message}</font>\n"
	} else {
		append DEBUG_STRING "${message}\n"
	}	
	#puts -nonewline $message
	# Useful for Rivet, and useful for tclhttpd if started in a console
	# puts $message
	# ALLOWS TO WRITE IN A FILE IN /tmp 
	if { [llength [info globals DEBUG_FID]] } {
		global DEBUG_FID
		puts $DEBUG_FID "${message}"
	}
}

proc init_debug { } {
	global DEBUG
	if $DEBUG {
		catch { cgi_debug -on }

		global DEBUG_FID
		global DEBUG_FILE
		global DEBUG_STRING
		global DEBUG_FILENAME

		set DEBUG_STRING ""

		# I put debug message as there are created in a file in /tmp
		# Maybe for windows version another place should be chosen
		if { [info exists DEBUG_FILE] } {
			if $DEBUG_FILE {
				# Does a directory exists ?
				set debug_directory /tmp/ucome
				catch {file mkdir $debug_directory}
				set debug_filename "[file join $debug_directory ucome_[pid]-[clock clicks].dbg]"
				if { [file readable $debug_filename] } {
					catch { file delete -force $debug_filename}
				}
				# Allows to write in a file /tmp
				set DEBUG_FID [open $debug_filename w]
				set DEBUG_FILENAME $debug_filename
			}
		}
	} else {
		catch { cgi_debug -off }
	}
	# Start of the log
	init_main_log 
}

proc end_debug { } {
	# This is for tclhttpd at the end of the display of a file
	global DEBUG
	if $DEBUG {
		global DEBUG_FID
		global DEBUG_FILE
		if { [info exists DEBUG_FILE] } {
			if $DEBUG_FILE {
				check_open_files
			}
		}
		if { [info exists DEBUG_FID] } {
			close $DEBUG_FID
		}
	}
	end_main_log
}

proc fas_debug { message } {
	global DEBUG
	global DEBUG_MAIN
	global DEBUG_ALL

	if { $DEBUG && ( $DEBUG_MAIN || $DEBUG_ALL )} {
		set indent ""
		for { set i 1 } { $i < [info level] } { incr i } {
			append indent "  "
		}
		fas_debug_puts "${indent}$message"
	}
}
# Debug is slowing normal code due to execution of instructions
# I try to have them executed only if debug is activated
proc fas_fastdebug { message } {
	global DEBUG
	global DEBUG_MAIN
	global DEBUG_ALL

	if { $DEBUG && ( $DEBUG_MAIN || $DEBUG_ALL )} {
		set indent ""
		for { set i 1 } { $i <  [info level] } { incr i } {
			append indent "  "
		}
		uplevel 1 fas_debug_puts "\"${indent}${message}\""
	}
}

proc fas_debug_parray_puts { current_array args } {
	upvar $current_array display_array
	if { [llength $args] > 0 } {
		set message [lindex $args 0]
		#fas_debug_puts "<font color=\"#ff0000\">-----parray $current_array --------$message</font>"
		fas_debug "-----parray $current_array --------$message"
	} else {
		#fas_debug_puts "<font color=\"#ff0000\">-----parray--------</font>"
		fas_debug "-----parray--------"
	}
	foreach {key value} [array get display_array] {
		#fas_debug_puts "<font color=\"#ff0000\">${key}</font> - <font color=\"#0000ff\">${value}</font>"
		fas_debug "${key} - ${value}"
	}
			
	#fas_debug_puts "<font color=\"#ff0000\">-----parray end $current_array --------</font>"
	fas_debug "-----parray end $current_array --------"
}

proc fas_debug_parray { current_array args } {
	global DEBUG_MAIN
	global DEBUG_ALL

	if { $DEBUG_MAIN || $DEBUG_ALL } {
		upvar $current_array display_array
		eval fas_debug_parray_puts display_array $args
	}
}

proc is_debug {  } {
	global DEBUG

	return $DEBUG
}

proc debug_cgi_uservar { } {
	if { $::DEBUG } {
		fas_debug_puts "----------------- displaying _cgi_uservar --------------------"
		foreach element [array names ::_cgi_uservar] {
			fas_debug_puts "$element -> $::_cgi_uservar($element)\n"
		}
		fas_debug_puts "----------------- end _cgi_uservar --------------------"
	}
}
#
# Trying to find the bug in Rivet
# what files are opened or not at the end ?
if [info exists DEBUG_OPEN] {
	proc ::open args {
		global OPENFILES
		set fid [eval oriOpen $args] 
		set OPENFILES($fid) $args
		return $fid
	}

	proc ::close { fid }  {
		global OPENFILES
		oriClose $fid
		unset OPENFILES($fid)
	}

	proc check_open_files { } {
		global OPENFILES
		fas_debug_parray OPENFILES "Files opened"
	}
}
