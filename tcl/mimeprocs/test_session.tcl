lappend filetype_list test_session

namespace eval test_session {
	set done 0
	global DEBUG_PROCEDURES INIT_ACTION STANDARD_ACTION_PROCEDURES
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION
	eval $STANDARD_ACTION_PROCEDURES

	# This procedure returns the list of important session variables for
	# this type of file
	# If this function is not defined, no one are important
	proc important_session_keys { } {
		# not any one
		return [list session_test]
	}


	# This procedure will translate create the html for testing sessions
	proc 2final { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI
		set target_name [rm_root $filename]

		fas_depend::set_dependency 1 always

		set message  ""
		# First I get the session variable 
		if { [catch {set session_test [fas_session::setsession session_test]} error] } {
			set message "Error while reading session_test : $error"
			set session_test 0
		} else {
			set message "Found session_test : $session_test"
			incr session_test
		}
		fas_session::setsession session_test $session_test
		# And now displaying the result
		set dir [rm_root [file dirname $filename]]
		# No reason to do substitution here
		# I try to display display the result directly in 
		# the message place of the directory display.
		global _cgi_uservar
		unset _cgi_uservar
		set _cgi_uservar(message) "$message"
		set _cgi_uservar(action) "view"
		display_file [guess_filetype $filename ::conf ::fas_env] $filename fas_env conf
		#fas_exit
	}
}
