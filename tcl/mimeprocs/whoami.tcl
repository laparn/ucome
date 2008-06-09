# no extensions for copy
lappend filetype_list whoami

append STANDARD_PROCEDURES {
	proc 2whoami { current_env filename } {
		return ""
	}
}

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval whoami {
	# When the copy is done, I set it to 1.
	set done 0
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global INIT_ACTION
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		# When a txt is met, in what filetype will it be by default
		# translated ?
		#set conf(newtype.txt) tmpl
		# This is the default answer
		set result fashtml
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

	proc 2comp { current_env args } {
		fas_debug "whoami::2comp - $args"
		upvar $current_env fas_env
		array set tmp ""
		set tmp(content.content) [extract_body [eval 2fashtml fas_env $args]]
		return "[array get tmp]"
	}

	# This procedure will allow to login. Which means create a session
	# with a given filename.
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI

		# fas_depend::set_dependency 1 always

		set message  ""
		# First I must import the login name
		if { [catch { set message "[translate "Logged as : "]<a href=\"fas:[rm_root $filename]&action=logout\">[fas_session::setsession REMOTE_USER]</a>" } ] } {
			set message "<a href=\"fas:[rm_root $filename]&action=login_form\">[translate "Log in"]</a>"
		}
		return $message
	}

	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to whoami on a content. It must be a filename."]</b></center></body></html>"
	}
}
