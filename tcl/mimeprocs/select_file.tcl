# TO BE DONE - TAKE INTO ACCOUNT IMPORTED VARIABLES
# IN comp::2edit_form

# In this case, I will come here after having selected a file.
# So, I must :
#  * know what file was selected,
#  * then get back all content of _cgi_uservar that was stored
#    in the session variable,
#  * then ask for the display of the edit_form or something else of the file.

# no extensions for select_file
lappend filetype_list select_file

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval select_file {
	# When the copy is done, I set it to 1.
	set done 0
	global INIT_ACTION
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		# This is the default answer
		set result comp
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
		return [list comp]
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
		fas_debug "select_file::2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval 2fashtml env $args]]
		return "[array get tmp]"
	}

	proc content2comp { current_env args } {
		fas_debug "select_file::content2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval content2fashtml env $args ]]
		return "[array get tmp]"
	}

	
	# After having displayed the list of files and dir,
	# I come here. It is here that I determine the name
	# of the selected file and that I send the result
	# to the first calling action for filling up a 
	# text entry
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env

		# Now what is the selected file
		global _cgi_uservar
		set cb_list [array  names _cgi_uservar checkbox*]
		fas_depend::set_dependency 1 always
		fas_debug_parray _cgi_uservar "select_file::2fashtml - _cgi_uservar"
		set FOUND_FILE 0
		set result_filename ""
		# List of checkbox_variable
		foreach cb $cb_list {
			if { $_cgi_uservar($cb) } {
				regsub {^checkbox} $cb {file} input_name
				if { [info exists _cgi_uservar($input_name)] } {
					# I found it
					set result_filename $_cgi_uservar($input_name)
					set FOUND_FILE 1
				}
			}
		}
		if $FOUND_FILE {
			fas_debug "select_file::2fashtml - Found file - $result_filename"
			set message "select_file::2fashtml - Found file - $result_filename"
		} else {
			fas_debug "select_file::2fashtml - No file found"
			set message "select_file::2fashtml - No file found"
		}
		# Now getting the session variables
		# First from where am I coming ?
		set select_section [fas_session::setsession selectsection]
		set target_file [fas_session::setsession filename]
		#set comefrom [fas_session::setsession comefrom]
		
		# Now resetting _cgi_uservar
		# The calling action is all herein
		unset _cgi_uservar
		array set _cgi_uservar [fas_session::setsession _cgi_uservar]
		# Setting the section filename
		# It is here that I send back the result
		set _cgi_uservar(${select_section}) "$result_filename"
		
		fas_debug_parray _cgi_uservar "select_file::2fashtml - _cgi_uservar restored from session"
		
		# No reason to do substitution here
		# I try to display the result directly in 
		# the message place of the directory display.
		global conf
		read_full_env [add_root $target_file] new_env
		set filetype [guess_filetype [add_root $target_file] conf new_env]
		global conf
		display_file $filetype [add_root $target_file] new_env conf
		fas_exit
	}

	# This procedure will translate a string in txt2ml format into fashtml 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to copy a content. It must be a filename."]</b></center></body></html>"
	}
}
