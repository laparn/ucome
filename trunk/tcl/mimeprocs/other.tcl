# All other extensions
lappend filetype_list other
namespace eval other {

	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		# When an other  is met, in what filetype will it be by default
		# translated ?
		# If there is an action, I use it
		if { ![catch {set action [fas_get_value action] } ] } {
			if { $action != "view" } {
				# there is an action. Is it done or not
				if { [set ${action}::done ] == 0 } {
					fas_debug "other::new_type - action -> $action , action::done -> [set ${action}::done]"
					# the action was not processed
					set result $action
					return $result
				} ; # else I continue
			}
		}
		# In nothing
		#error 1
		return ""
	}

	# This procedure returns the list of important session variables for
	# this type of file
	proc important_session_keys { } {
		# not any one
		return [list]
	}

	# Return the list of environment variables that are important
	# If this function is not defined, it is a final type that can
	# not be converted
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
		binary::2edit fas_env $filename this
	}

	proc 2edit { current_env filename } {
		upvar $current_env fas_env
		binary::2edit fas_env $filename this
	}
		
	proc 2flatten { current_env filename } {
		return ""		
	}
		
	proc content_display { current_env content } {
		_cgi_http_head_implicit
		puts "$content"
	}
		
	proc display { current_env filename } {
		# A procedure for just sending the output on the
		# stdout.
		upvar $current_env env

		# it is a file
		binary::display other application/octet-stream $filename env
	}
}
