# no extensions for edit
lappend filetype_list edit

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval edit {
	# When the copy is done, I set it to 1.
	set done 0
	global INIT_ACTION
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		# When a txt is met, in what filetype will it be by default
		# translated ?
		#set conf(newtype.txt) tmpl
		# This is the default answer
		set result comp
		# copy type must appear only once after that when
		# "normal" filetype tests for it, it must not appear.
		# new_type is the only function executed when looking
		# for a file. So I must put there the setting of this
		# flag.

		# I need to be able to add an option for saying not
		# to go through tmpl
		set new_type_option [fas_get_value new_type_option -default standard]
		if { ( $result == "comp" ) && ( $new_type_option == "notmpl" ) } {
			set result fashtml
		}
		variable done 
		set done 1
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list comp fashtml ]
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
		fas_debug "edit::2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval 2fashtml env $args ]]
		global _cgi_uservar
		if { [info exists _cgi_uservar(from)] } {
			if { $_cgi_uservar(from) == "view" } {
				set tmp(####) "comp/txt.view.form"
			}
		}
		return "[array get tmp]"
	}
	
	# Just take the input and send it out
	# The only case where it is useful is for the form
	# filetype. That's strictly all
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		set real_filename [fas_name_and_dir::get_real_filename edit $filename fas_env]
		set fid [open $real_filename]
		set content [read $fid]
		close $fid

		return $content
	}

	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to edit a content. It must be a file."]</b></center></body></html>"
	}
}
