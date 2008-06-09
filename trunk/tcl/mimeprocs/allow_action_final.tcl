# no extensions 
lappend filetype_list allow_action_final

namespace eval allow_action_final {
	# At the end of the copy I set it at 1.
	# I will use it when changing of state
	set done 0

	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		set result comp
		# property_form type must appear only once after that when
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
		fas_debug "allow_action_final::2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval 2fashtml env $args]]
		return "[array get tmp]"
	}

	proc content2comp { current_env args } {
		fas_debug "allow_action_final::content2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval content2fashtml env $args ]]
		return "[array get tmp]"
	}

	# This procedure will create the html text for the list of users
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		global FAS_PROG_ROOT

		fas_debug "allow_action_final::2fashtml -- entering for $filename"

		# For debugging purpose, I put a dependency on the source file
		#fas_depend::set_dependency ${FAS_PROG_ROOT}/mimeprocs/allow_action_final.tcl

		# First the list of users we are dealing with
		set user_list [any::import_checkbox_list user]

		# Now the list of actions for which we create the authorisations
		set counter 0
		set action_list [list]
		global _cgi_uservar
		while { [info exists _cgi_uservar(action${counter})] } {
			lappend action_list $_cgi_uservar(action${counter})
			incr counter
		}
	
		fas_debug "allow_action_final::2fashtml - found user_list - $user_list - found action_list - $action_list"

		# So now, I must force these values for this file
		# I load the property file, then I force the values
		# then I save it.
		array set file_env ""
		catch { read_dir_env $filename file_env}
		fas_debug_parray file_env "allow_action_final::2fashtml -- file_env array"

		# forcing the values
		foreach action $action_list {
			set file_env(allow.${action}) $user_list
			if { [llength $user_list] == 0 } {
				unset file_env(allow.${action})
			}
		}

		# Saving the file
		fas_debug_parray file_env "allow_action_final::2fashtml -- file_env array"
		if { [catch { write_all_env $filename file_env } ] } {
			set message "[translate "Problem while writing property file of "] [rm_root $filename]"
		} else {
			set message "[translate "Successful writing of property file of "] [rm_root $filename]"
		}
		# I am going to call allow_action_form but with a message.
		unset _cgi_uservar
		set _cgi_uservar(message) "$message"
		set _cgi_uservar(action) "allow_action_form"
		global conf
		set filetype [guess_filetype $filename conf fas_env]
		display_file $filetype $filename fas_env conf
		fas_exit
	}
				
		
	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to get the properties of a content. It must be a filename."]</b></center></body></html>"
	}
}
