# no extensions for copy
lappend filetype_list logout

namespace eval logout {
	set done 0
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global INIT_ACTION
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		# This is the default answer
		set result fashtml
		# logout type must appear only once after that when
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

	# This procedure will allow to logout. Which means create a session
	# with a given filename.
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI

		fas_depend::set_dependency 1 always

		set loggedinas ""
		# First I must import the login name
		if { [fas_session::exists REMOTE_USER] } {
			set loggedinas [fas_session::setsession REMOTE_USER]
		}
		fas_session::unsetsession REMOTE_USER
		set message "[translate "Logged out from "]$loggedinas"

		# And now displaying the result
		set dir [rm_root [file dirname $filename]]
		fas_user::set_user_name ""
		# No reason to do substitution here
		# I try to display display the result directly in 
		# the message place of the directory display.
		global _cgi_uservar
		global conf
		unset _cgi_uservar
		set _cgi_uservar(message) "$message"
		set _cgi_uservar(action) "view"
		#set dir [file dirname $filename]
		read_full_env $filename fas_env
		set filetype [guess_filetype $filename conf fas_env]
		fas_fastdebug {logout::2fashtml - filetype is $filetype}
		#display_file dir $dir fas_env conf
		display_file $filetype $filename fas_env conf
		catch { fas_session::write_session }
		fas_exit
	}

	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to logged out from a content. It must be a filename."]</b></center></body></html>"
	}
}
