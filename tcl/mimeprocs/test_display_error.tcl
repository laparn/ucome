# no extensions for test_display_error
lappend filetype_list test_display_error

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval test_display_error {
	# When the copy is done, I set it to 1.
	set done 0
	global INIT_ACTION
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		set result fashtml
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
		set target_name [rm_root $filename]

		fas_depend::set_dependency 1 always
		fas_display_error [translate "Test of fas_display_error"] fas_env

		set message [translate "Test of fas_display_error"]

		# And now displaying the result
		set dir [rm_root [file dirname $filename]]
		# No reason to do substitution here
		# I try to display display the result directly in 
		# the message place of the directory display.
		global _cgi_uservar
		unset _cgi_uservar
		set _cgi_uservar(message) "$message"
		if [is_debug] {
			set _cgi_uservar(debug) "$DEBUG"
		}
		set _cgi_uservar(action) "edit_form"
		set dir [file dirname $filename]
		global conf
		display_file dir $dir fas_env conf
		fas_exit
	}

	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to test_display_error a content."]</b></center></body></html>"
	}
}
