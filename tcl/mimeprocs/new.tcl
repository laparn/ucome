lappend filetype_list new

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval new {
	# When the new is done, I set it to 1.
	set done 0
	global  INIT_ACTION
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		# This is the default answer
		set result final
		variable done 
		set done 1
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list final ]
	}

	# This procedure returns the list of important session variables for
	# this type of file
	# If this function is not defined, no one are important
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

	proc 2final { current_env args } {
		fas_debug "copy::content2treedir - $args"
		upvar $current_env env
		return ""
	}
}
