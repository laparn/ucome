# no extensions for copy
lappend filetype_list copy

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval copy {
	# When the copy is done, I set it to 1.
	set done 0
	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		# This is the default answer
		set result final
		variable done 
		set done 1
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list final ]
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
	proc 2final { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI
		set target_name [rm_root $filename]

		fas_depend::set_dependency 1 always

		set message  ""
		# First I must import the target name
		if { [catch { set target_name [fas_get_value new_name] }] } {
			set message "[translate "No target filename or directory was proposed."]"
		} else {
				
			# Processing the copy
			set real_target [add_root $target_name]
			
			if { ![file writable $real_target] && [file exists $real_target] && ![file writable [file directory $real_target]] } {
				set message "[translate "is not writable, please choose another target"]"
			} else {
				if { [catch {file copy $filename $real_target} error] } {
					set message "[translate "Problem while copying "] <A HREF=\"${FAS_VIEW_CGI}?file=[rm_root "$filename"]\">${filename}</A> [translate "into"] ${target_name}<br>${error}<br>"
				} else {
					# Obviously, I must also copy the property file
					if { [file readable [env_filename $filename]] } {
						if { [catch {file copy [env_filename $filename] [env_filename $real_target] } error] } {
							set message "[translate "Problem while copying "] [translate " environment variables of"] <A HREF=\"${FAS_VIEW_CGI}?file=[rm_root "$filename"]\">[rm_root ${filename}]</A> [translate "into"] [translate " environment variables of"] ${target_name}<br>${error}<br>"
						} else {
							set message "[translate "Succesful copy of"]  <A HREF=\"${FAS_VIEW_CGI}?file=[rm_root $filename]\">[rm_root ${filename}]</A> [translate "into"] <A HREF=\"${FAS_VIEW_CGI}?file=${target_name}\">${target_name}</A>."
						}
					} else {
						set message "[translate "Succesful copy of"]  <A HREF=\"${FAS_VIEW_CGI}?file=[rm_root $filename]\">[rm_root ${filename}]</A> [translate "into"] <A HREF=\"${FAS_VIEW_CGI}?file=${target_name}\">${target_name}</A>."
					}
				}
			}
		}
		# And now displaying the result
		set dir [rm_root [file dirname $filename]]
		# No reason to do substitution here
		# I try to display display the result directly in 
		# the message place of the directory display.
		global _cgi_uservar
		unset _cgi_uservar
		set _cgi_uservar(message) "$message"
		set _cgi_uservar(action) "edit_form"
		set dir [file dirname $filename]
		global conf
		display_file dir $dir fas_env conf
		fas_exit
	}
}
