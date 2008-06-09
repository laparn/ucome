set conf(extension.png) png
lappend filetype_list png

namespace eval png {
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		upvar $current_env fas_env
		# When a png is met, in what filetype will it be by default
		# translated ?
		return [binary::new_type fas_env $filename png]
	}

	# This procedure returns the list of important session variables for
	# this type of file
	proc important_session_keys { } {
		# not any one
		return [list]
	}
	
	proc env { args } {
		set env_list ""
		return $env_list
	}

	proc get_title { filename } {
		return "[binary::get_title $filename]"
	}

	# Now all procedures for the actions
	proc 2edit_form { current_env filename } {
		upvar $current_env fas_env
		binary::2edit fas_env $filename png
	}

	proc 2edit { current_env filename } {
		upvar $current_env fas_env
		binary::2edit fas_env $filename png
	}

	proc 2rrooll { current_env filename } {
		fas_fastdebug {png::2rrooll $filename}
		upvar $current_env fas_env
		return "[rrooll::2fashtml fas_env $filename png]"
	}

	proc 2small { current_env filename } {
		# I need to convert to a small png
		# then to send it back
		upvar $current_env fas_env
		set content [binary::2small fas_env $filename png]
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
		binary::display png image/png $filename env
	}

	proc content { current_env filename } {
        upvar $current_env fas_env
		return [binary::content $current_env $filename png]
	}

	proc mimetype { } {
		return "image/png"
	}
}
