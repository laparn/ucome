# no extensions for copy
lappend filetype_list change_look

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval change_look {
	# When the copy is done, I set it to 1.
	set done 0
	global INIT_ACTION
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		# When a txt is met, in what filetype will it be by default
		# translated ?
		#set conf(newtype.txt) tmpl
		# This is the default answer
		set result final
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

	# The function for adding look properties to a file
	# Last parameter add : 1 - add the properties to the current env
	#                    : 0 - remove the properties of the current env
	proc manage_env_look { current_env filename look_dirname {add 1}} {
		upvar $current_env fas_env

		set full_look_env [file join [add_root $look_dirname] look.form]
		fas_debug "manage_env_look::2fashtml - full_look_env => $full_look_env"
		if { [file exists $full_look_env] } {
			if { [catch {read_env $full_look_env look_env}] } {
				set message "[translate "Problem while reading env file :"] [rm_root $full_look_env]"
			} else {
				# I read the current env for the current file,
				# but only its one, and add and remove
				# what is necessary
				read_dir_env $filename local_env

				foreach env_name [array names look_env "add.*"] {
					# remove add of the name
					regsub {add.} $env_name {} final_env_name
					if $add {
						set local_env($final_env_name) $look_env($env_name)
					} else {
						catch {unset local_env($final_env_name)}
					}
				}
				foreach env_name [array names look_env "sub.*"] {
					regsub {sub.} $env_name {} final_env_name
					if $add {
						catch {unset local_env($final_env_name)}
					}
				}
				# And now I write it back
				if { [catch { write_all_env $filename local_env } error ] } {
					set message "[translate "Problem while changing look"]<br>$error"
				} else {
					set message "[translate "Successful application of look"]"
				}
			}
		} else {
			set message "[translate "No default properties defined for this look"]"
		}
		return $message
	}

	proc 2final { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI
		set target_name [rm_root $filename]

		fas_depend::set_dependency 1 always

		set message  ""
		# First I must import the look name
		if { [catch { set look_name [fas_get_value look] }] } {
			set message "[translate "No look was proposed."]"
		} else {
			# First I must remove the variables of the old look
			# What is the old look ?
			if { [info exists fas_env(templatedir)] } {
				set old_look_dir $fas_env(templatedir)
			} else {
				set old_look_dir "/template/standard"
			}
			# Removing the variables from there
			manage_env_look fas_env $filename $old_look_dir 0
			
			# Processing the look
			# Does the look exists ?
			set message [manage_env_look fas_env $filename $look_name]
		}
		# No reason to do substitution here
		# I try to display display the result directly in 
		# the message place of the directory display.
		# Is there a from subaction ?
		if { [info exists _cgi_uservar(from)] } {
			set action $cgi_uservar(from)
		} else {
			set action "view"
		}
		global _cgi_uservar
		unset _cgi_uservar
		set _cgi_uservar(message) "$message"
		set _cgi_uservar(action) "$action"
		# I read again the env file
		read_full_env $filename fas_env
		global conf
		set filetype [guess_filetype $filename conf fas_env]
		display_file $filetype $filename fas_env conf
		fas_exit
	}

	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to change the look of a content. It must be a filename."]</b></center></body></html>"
	}
}
