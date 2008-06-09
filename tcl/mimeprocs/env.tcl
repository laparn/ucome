# no extensions for copy
lappend filetype_list env

# Just a procedure to show the current environment
namespace eval env {
	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	# When the copy is done, I set it to 1.
	set done 0
	proc new_type { current_env filename } {
		# env to ? html obviously
		# This is the default answer
		set result fashtml
		# env type must appear only once after that when
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

	# This procedure will translate create the html text for a copy
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI
		fas_debug "env:: entering 2fashtml"
		set target_name [rm_root $filename]

		fas_depend::set_dependency 1 always

		set message  "Displaying env<br><table>"
		global env

		global conf
		# I should use a template but I do it in a quick and dirty way
		if { [info exists conf(tclrivet)] } {
			array set request_env [list]
			load_env request_env
			foreach {var val} [array get env] {
				append message "\n	<tr>\n		<td>$var</td><td>$val</td></tr>\n	</tr>"
			}
		} else {
			foreach {var val} [array get env] {
				append message "\n	<tr>\n		<td>$var</td><td>$val</td></tr>\n	</tr>"
			}
		}
		append message "\n</table>"
		# And now displaying the result
		#set dir [rm_root [file dirname $filename]]
		# No reason to do substitution here
		# I try to display display the result directly in 
		# the message place of the directory display.
		#global _cgi_uservar
		#unset _cgi_uservar
		#set _cgi_uservar(message) "$message"
		#set _cgi_uservar(action) "edit_form"
		#set dir [file dirname $filename]
		#global conf
		#display_file dir $dir fas_env conf
		#fas_exit
		return $message
	}

}
