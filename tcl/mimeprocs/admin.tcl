# admin is an action
# Just jump at /
lappend filetype_list admin

namespace eval admin {
	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	set done 0

	proc new_type { current_env filename } {
		set result tmpl
		# Now there may be other cases
		variable done
		set done 1
		fas_debug "admin_path::new_type -> $result "
		return $result
	}

	proc init { } {
		variable done
		set done 0
	}

	# List of possible types in which this file type may be converted
	proc new_type_list { } {
		return [list tmpl]
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

	# List of block that this filetype may send back
	proc block_list { } {
		return [list]
	}
		
	proc 2tmpl { current_env filename } {
		#Just jump at /
		upvar $current_env fas_env
		global _cgi_uservar
		unset _cgi_uservar
		global conf
		display_file dir [add_root "/"] fas_env conf
		fas_exit
	}
}
