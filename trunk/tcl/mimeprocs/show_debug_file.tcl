# show_debug_file is an action
# you give it a debug_file_name and it shows it.
# It is also used for displaying main_log files. Just add a mainlog=1 at the call

namespace eval show_debug_file {
	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	set done 0

	proc new_type { current_env filename } {
		set result htmf
		# Now there may be other cases
		variable done
		set done 1
		fas_debug "show_debug_file::new_type -> $result "
		return $result
	}

	proc init { } {
		variable done
		set done 0
	}

	# List of possible types in which this file type may be converted
	proc new_type_list { } {
		return [list fashtml]
	}

	# This procedure returns the list of important session variables for
	# this type of file
	proc important_session_keys { } {
		# not any one
		return [list]
	}
	# Return the list of environment variables that are important
	proc env { args } {
		set env_list ""
		return $env_list
	}

	# Convert into html the input and return the corresponding
	# string.
	proc 2htmf { current_env filename } {
		fas_fastdebug {show_debug_file::2htmf - entering}
		upvar $current_env fas_env

		# get the debug filename
		set debug_identifier [fas_get_value debug_identifier -noe -nos -defaut ""]

		if { $debug_identifier == "" } {
			return {<html><body><h1>You did not provide any identifier !</h1></body></html>}
		}

		# I have a debug filename, then I load it and give it back
		# Security as always 
		regsub -all {[^01-9\-]} $debug_identifier {} debug_identifier
		if { [info exists ::_cgi_uservar(mainlog)] } {
			set debug_filename "/tmp/ucome/ucome_${debug_identifier}.dbg.log"
		} else {
			set debug_filename "/tmp/ucome/ucome_${debug_identifier}.dbg"
		}
		if { [catch {set debug_fid [open "$debug_filename"] } ] } {
			return "<html><body><h1>Could not load $debug_filename !</h1></body></html>"
		} else {
			set debug_content [read $debug_fid]
			close $debug_fid
		}
		fas_fastdebug {show_debug_file::2htmf - leaving and sending back content}
		return "<html><body><pre>${debug_content}<pre></body></html>"
	}
}
