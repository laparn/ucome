# no extensions for copy
lappend filetype_list login

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval login {
	# When the copy is done, I set it to 1.
	set done 0
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global INIT_ACTION
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		# When a txt is met, in what filetype will it be by default
		# translated ?
		#set conf(newtype.txt) tmpl
		# This is the default answer
		set result fashtml
		# copy type must appear only once after that when
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

	# This procedure will allow to login. Which means create a session
	# with a given filename.
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI

		fas_depend::set_dependency 1 always

		set message  ""
		# First I must import the login name

		set name [fas_get_value name -default ""]
		set password [fas_get_value password -default ""]

		# Now I need to check if the password is ok or not
		if { [fas_user::check_password fas_env $name $password] } {
			# OK the password is fine
			# everything is ok
			# I put the login name in
			fas_session::setsession REMOTE_USER $name
			fas_user::set_user_name $name
			set message "[translate "Login as "] $name"
		} else {
			# No the password is bad
			set message "[translate "Not logged in"]"
		}

		# And now displaying the result
		#set dir [file dirname [rm_root $filename]]
		# No reason to do substitution here
		# I try to display display the result directly in 
		# the message place of the directory display.
		global _cgi_uservar
		unset _cgi_uservar
		set _cgi_uservar(message) "$message"
		set _cgi_uservar(action) "view"
		#if { [file isdirectory $filename] } {
		#	set dir $filename
		#} else {
		#	set dir [file dirname $filename]
		#}
		global conf
		#display_file dir $dir fas_env conf
		read_full_env $filename fas_env
		set filetype [guess_filetype $filename conf fas_env]
		fas_fastdebug {login::2fashtml - filetype is $filetype}
		display_file $filetype $filename fas_env conf
		catch { fas_session::write_session }
		fas_exit
	}

	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to copy a content. It must be a filename."]</b></center></body></html>"
	}
}
