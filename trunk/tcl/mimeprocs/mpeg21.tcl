set conf(extension.mpeg21) mpeg21
lappend filetype_list mpeg21

namespace eval mpeg21 {
	set done 0
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		fas_fastdebug {mpeg21::new_type $filename}
		upvar $current_env fas_env
		# When a mpeg21 is met, in what filetype will it be by default
		# translated ?
		return ""
	}

	# This procedure returns the list of important session variables for
	# this type of file
	proc important_session_keys { } {
		# not any one
		return [list]
	}
	
	proc env { args } {
		set env_list ""
		return $env_list
	}

	proc get_title { filename } {
		return "[binary::get_title $filename]"
	}

	# Now all procedures for the actions
	proc 2edit_form { current_env filename } {
		upvar $current_env fas_env
		::binary::2edit_form fas_env $filename mpeg21
	}

	proc 2edit { current_env filename } {
		upvar $current_env fas_env
		::binary::2edit fas_env $filename mpeg21
	}
		
	proc mimetype { } {
                return "application/xml"
        }
        
	proc display { current_env filename } {
		# A procedure for just sending the output on the
		# stdout.
		upvar $current_env fas_env
	
		# it is a file
		::binary::display mpeg21 application/xml $filename fas_env
	}
}
