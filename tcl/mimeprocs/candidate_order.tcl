# no extensions for copy
lappend filetype_list candidate_order

namespace eval candidate_order {
	# When the copy is done, I set it to 1.
	set done 0
	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		set result final
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

	# This procedure returns the list of important session variables for
	# this type of file
	# If this function is not defined, no one are important
	proc important_session_keys { } {
		# not any one
		return [list order.candidate_list]
	}

	# Return the list of environment variables that are important
	# If this function is not defined, it is a final type that can
	# not be converted
	proc env { args } {
		set env_list ""
		return $env_list
	}

	# This procedure will translate create the html text for a copy
	proc 2final { current_env filename } {
		upvar $current_env fas_env

		fas_depend::set_dependency 1 always
		if { [catch {set current_candidate_list [::fas_session::setsession order.candidate_list]} ] } {
			set current_candidate_list [list $filename]
		} else {
			# No reason to add it twice
			if { [lsearch -exact $current_candidate_list [rm_root $filename]] < 0 } {
				lappend current_candidate_list [rm_root $filename]
			}
		}
		::fas_session::setsession order.candidate_list $current_candidate_list
		fas_debug "candidate_order::2final - session variable order.candidate_list is $current_candidate_list"

		set message  "[translate "Added to list of candidate files for an order file"] [rm_root $filename]"
		# And now displaying the result
		# I try to display display the result directly in 
		# the message place of the directory display.
		global _cgi_uservar
		unset _cgi_uservar
		set _cgi_uservar(message) "$message"
		set _cgi_uservar(action) "view"
		global conf
		# I do not show the file, but the directory
		set filetype [guess_filetype [file dirname $filename] conf fas_env]
		display_file $filetype [file dirname $filename] fas_env conf
		fas_exit
	}
}
