set conf(extension.gif) gif
lappend filetype_list gif

namespace eval gif {
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		# When a gif is met, in what filetype will it be by default
		# translated ?
		# If there is an action, I use it
		#if { ![catch {set action [fas_get_value action] } ] } {
		#	if { $action != "view" } {
		#		# there is an action. Is it done or not
		#		if { [set ${action}::done ] == 0 } {
		#			fas_debug "other::new_type - action -> $action , action::done -> [set ${action}::done]"
		#			# the action was not processed
		#			set result $action
		#			return $result
		#		} ; # else I continue
		#	}
		#}
		# In nothing just a gif
		#error 1
		#return ""

		## modif Xav
		## everything up there is useless since it is the same as in binary
		fas_fastdebug {gif::new_type $filename}
		upvar $current_env fas_env
		return [binary::new_type fas_env $filename gif]
	}

	# This procedure returns the list of important session variables for
	# this type of file
	proc important_session_keys { } {
		# not any one
		return [list]
	}

	proc get_title { filename } {
		return "[binary::get_title $filename]"
	}

	# Now all procedures for the actions
	proc env { args } {
		set env_list ""
		return $env_list
	}

	proc ucome_doc { } {
		set content {gif files are directly displayed.}
		return $content
	}

	proc 2edit_form { current_env filename } {
		upvar $current_env fas_env
		binary::2edit fas_env $filename gif
	}

	proc 2edit { current_env filename } {
		upvar $current_env fas_env
		binary::2edit fas_env $filename gif
	}


	proc 2rrooll { current_env filename } {
		fas_fastdebug {gif::2rrooll $filename}
		## specific processings prior to rrooll
		## may be done here.

		upvar $current_env fas_env
		return "[rrooll::2fashtml fas_env $filename gif]"
	}

	proc 2small { current_env filename } {
		# I need to convert to a small png
		# then to send it back
		upvar $current_env fas_env
		set content [binary::2small fas_env $filename gif]
		return $content
	}


	proc content_display { current_env content } {
		## modif Xav : that proc is gone into binary
		binary::content_display $current_env $content
	}

	proc display { current_env filename } {
		# A procedure for just sending the output on the
		# stdout.
		upvar $current_env env

		# it is a file
		binary::display gif image/gif $filename env
	}

	proc content { current_env filename } {
        upvar $current_env fas_env
		return [binary::content $current_env $filename gif]
	}


	proc mimetype { } {
		return "image/gif"
	}
}
