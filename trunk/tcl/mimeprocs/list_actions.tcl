# no extensions for an action
lappend filetype_list list_actions

# Just a procedure to show the current environment
namespace eval list_actions {
	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	# When the copy is done, I set it to 1.
	set done 0
	proc new_type { current_env filename } {
		# env to ? html obviously
		# This is the default answer
		set result fashtml
		# env type must appear only once after that when
		# "normal" filetype tests for it, it must not appear.
		# new_type is the only function executed when looking
		# for a file. So I must put there the setting of this
		# flag.
		variable done 
		set done 1
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list fashtml ]
	}

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

	# This procedure will translate create the html text for a copy
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI
		fas_debug "env:: entering 2fashtml"
		set target_name [rm_root $filename]

		fas_depend::set_dependency 1 always

		# First I must get the list of actions
		# To do that I start from the file_type_list
		# and check if there is a done variable in the namespace
		# If so, it is an action
		set action_list ""
		global filetype_list
		foreach filetype $filetype_list {
			if { [info exists ${filetype}::done] } {
				lappend action_list $filetype
			}
		}

		set action_list [lsort $action_list]
		
		# Now I display the action list
		set message  "<ul>"
		global env

		# I should use a template but I do it in a quick and dirty way
		foreach action $action_list {
			append message "\n	<li>$action</li>"
		}
		append message "\n</ul>"
		# And now displaying the result
		set dir [rm_root [file dirname $filename]]
		# No reason to do substitution here
		# I try to display display the result directly in 
		# the message place of the directory display.
		global _cgi_uservar
		unset _cgi_uservar
		set _cgi_uservar(message) "$message"
		global DEBUG
		if $DEBUG {
			set _cgi_uservar(debug) "$DEBUG"
		}
		set _cgi_uservar(action) "edit_form"
		set dir [file dirname $filename]
		global conf
		display_file dir $dir fas_env conf
		fas_exit
	}

}
