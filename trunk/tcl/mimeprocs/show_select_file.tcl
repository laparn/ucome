# This is a pure trick. To simplify the way, I display
# selection file, I will come here, and it will just
# redirect toward the display of the current directory
# This is due to a recursion problem and also to
# simplify the url in the treedir.

lappend filetype_list show_select_file

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval show_select_file {
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
		return [list comp ]
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
		fas_debug "show_select_file::2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval 2fashtml env $args]]
		return "[array get tmp]"
	}

	proc content2comp { current_env args } {
		fas_debug "show_select_file::content2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval content2fashtml env $args ]]
		return "[array get tmp]"
	}
	
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env

		# Now what is the selected file
		global _cgi_uservar

		unset _cgi_uservar

		set _cgi_uservar(action) edit_form
		# I should arrive here with a directory in filename
		set _cgi_uservar(display) "filetype,shortname,extension,title,select"
		set _cgi_uservar(form) "1"
		set _cgi_uservar(noadd) "1"
		set _cgi_uservar(treedir.url_start) "?action=show_select_file&file="
		global conf 
		display_file dir $filename fas_env conf
		fas_exit
	}
	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to show a selected file on a content. It must be a directory."]</b></center></body></html>"
	}
}
