# no extensions for prop_form
lappend filetype_list prop

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval prop {
	# At the end of the copy I set it at 1.
	# I will use it when changing of state
	set done 0
	global INIT_ACTION
	eval $INIT_ACTION


	proc new_type { current_env filename } {
		# When a prop is met, in what filetype will it be by default
		# translated ?
		# This is the default answer
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
		fas_debug "prop::2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval 2fashtml env $args]]
		return "[array get tmp]"
	}

	proc content2comp { current_env args } {
		fas_debug "prop::content2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval content2fashtml env $args ]]
		return "[array get tmp]"
	}
	
	# This procedure will translate create the html text for the properties
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI

		fas_debug "prop::2fashtml -- entering for $filename"

		# First the dependencies :
		fas_depend::set_dependency 1 always

		set message ""
		
		# First getting the inherited values :
		set directory [file dirname $filename]

		read_full_env $directory inherited_env

		# Now the values specific to the file
		array set file_env ""
		catch { read_dir_env $filename file_env }
		
		fas_debug_parray file_env "prop::2fashtml -- file_env array"

		# Now I import the values that were proposed
		set counter 0
		set prop_list ""
		global _cgi_uservar
		array set import_value ""

		while { [info exists _cgi_uservar(${counter}_prop)] } {
			lappend prop_list $_cgi_uservar(${counter}_prop)
			if { [info exists _cgi_uservar(${counter}_cbx)] } {
				if { [info exists _cgi_uservar(${counter}_val)] } {
					set tmp_key $_cgi_uservar(${counter}_prop)
					set import_value($tmp_key) "$_cgi_uservar(${counter}_val)"
				}
			}
			incr counter
		}
		fas_debug_parray import_value "form::2fashtml -- import_value array"
		
		# Now I must create the final array to write in taking the values
		# coming from the file that were NOT imported and the values 
		# imported (also those that are no more in the file).
		array set final_env ""

		foreach {key value} [array get file_env] {
			if { [lsearch $prop_list $key] < 0 } {
				# the key was not imported, I keep the value
				set final_env($key) $value
			}
		}

		# Now I put all imported values	
		foreach {key value} [array get import_value] {
			set final_env($key) $value
		}
		
		fas_debug_parray final_env "form::2fashtml -- import_value array"

		# And finally, I just have to write the file at the right place
		if { [catch { write_all_env $filename final_env } ] } {
			set message "[translate "Problem while writing property file of "] $filename"
		} else {
			set message "[translate "Successful writing of property file of "] $filename"
		}
		
		# And now displaying the result
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
		
	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to set the properties of a content. It must be a file."]</b></center></body></html>"
	}
}
