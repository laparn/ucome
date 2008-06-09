# no extensions for edit_form
lappend filetype_list "archive_full"

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval archive_full {
	# At the end of the edit I set it at 1.
	# I will use it when changing of state
	set done 0

	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		upvar $current_env fas_env
	    set result [binary::new_type fas_env $filename archive_full]
		variable done 
		set done 1
		fas_debug "archive_full::new_type -> $result - done -> $done"
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list archive_full ]
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

	proc 2comp { current_env args } {
		fas_debug "edit_form::2tmpl - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval 2fashtml env $args ]]
		return "[array get tmp]"
	}
	
	proc content2comp { current_env args } {
		fas_debug "edit_form::content2tmpl - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval content2fashtml env $args ]]
		return "[array get tmp]"
	}
	
}
