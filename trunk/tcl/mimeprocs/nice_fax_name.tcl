lappend filetype_list nice_fax_name

namespace eval nice_fax_name {
	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION
	set done 0

	proc new_type { current_env filename } {
		#set result error
		#error 1
		return ""
	}

	proc new_type_list { } {
		return [list  ]
	}


	# This procedure returns the list of important session variables for
	# this type of file
	proc important_session_keys { } {
		return [list]
	}

	# Return the list of environment variables that are important
	proc env { args } {
		set env_list ""
		return $env_list
	}

	proc mimetype { } {
		return "text/html"
	}

	proc content_display { current_env content } {
		return "[not_binary::content_display nice_fax_name $content]" 
	}

	proc display { current_env filename } {
		upvar $current_env fas_env
		return "[not_binary::display fas_env $filename nice_fax_name]"
	}

	proc content { current_env filename } {
		upvar $current_env fas_env
		return "[not_binary::content fas_env $filename nice_fax_name]"
	}
}
