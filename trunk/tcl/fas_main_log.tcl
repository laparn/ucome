# Creating of a main log with the really important informations
# for understanding where informations are taken, and where they go
set MAIN_LOG 1
set MAIN_LOG_STRING ""
set MAIN_LOG_SHOW 1
set MAIN_LOG_FILE 1
set MAIN_LOG_FILENAME ""

proc init_main_log { } {
	if $::MAIN_LOG {

		set ::MAIN_LOG_STRING ""

		# I put debug message as there are created in a file in /tmp
		# Maybe for windows version another place should be chosen
		if { [info exists ::MAIN_LOG_FILE] } {
			if $::MAIN_LOG_FILE {
				set debug_directory /tmp/ucome
				catch {file mkdir $debug_directory}
				global DEBUG_FILENAME
				if { $DEBUG_FILENAME != "" } {
					set main_log_filename "${DEBUG_FILENAME}.log"
				} else {
					set main_log_filename "[file join $debug_directory ucome_[pid]-[clock clicks].log]"
				}
				set ::MAIN_LOG_FILENAME $main_log_filename
				if { [file readable $main_log_filename] } {
					catch { file delete -force $main_log_filename}
				}
				# Allows to write in a file /tmp
				set ::MAIN_LOG_FID [open $main_log_filename w]
			}
		}
	}
}


proc end_main_log { } {
	# This is for tclhttpd at the end of the display of a file
	global MAIN_LOG
	if $MAIN_LOG {
		global MAIN_LOG_FID
		global MAIN_LOG_FILE
		if { [info exists MAIN_LOG_FILE] } {
			if $MAIN_LOG_FILE {
				close $MAIN_LOG_FID
				if { [file exists $::MAIN_LOG_FILENAME] } {
					if { [file size $::MAIN_LOG_FILENAME] == 0 } {
						file delete $::MAIN_LOG_FILENAME
					}
				}
			}
		}
	}
}

proc main_log { message {color ""}} {
	global MAIN_LOG
	if $MAIN_LOG {
		global MAIN_LOG_STRING
		set current_message ""

		set indent ""
		for { set i 1 } { $i < [info level] } { incr i } {
			append indent "  "
		}

		if { ![catch {set info_level [lindex [info level -1] 0]} ] } {
			if { $color != "" } {
				set current_message "${indent}${info_level} - <font color=\"$color\">${message}</font>\n"
			} else {
				set current_message "${indent}${info_level} - ${message}\n"
			}
		} else {
			if { $color != "" } {
				set current_message "${indent} - <font color=\"$color\">${message}</font>\n"
			} else {
				set current_message "${indent} - ${message}\n"
			}
		}
		# ALLOWS TO WRITE IN A FILE IN /tmp 
		if { [llength [info globals MAIN_LOG_FID]] } {
			global MAIN_LOG_FID
			puts -nonewline $MAIN_LOG_FID "${current_message}"
		}
		append MAIN_LOG_STRING $current_message
	}
}
	
