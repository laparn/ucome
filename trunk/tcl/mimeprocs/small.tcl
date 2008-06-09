# small is an action
lappend filetype_list small

namespace eval small {
	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	set done 0

	proc new_type { current_env filename } {
		set result png
		# Now there may be other cases
		variable done
		set done 1
		fas_debug "small::new_type -> $result "
		return $result
	}

	proc init { } {
		variable done
		set done 0
	}

	# List of possible types in which this file type may be converted
	proc new_type_list { } {
		return [list png]
	}

	# This procedure returns the list of important session variables for
	# this type of file
	proc important_session_keys { } {
		# not any one
		return [list]
	}
	# Return the list of environment variables that are important
	proc env { args } {
		set env_list ""
		return $env_list
	}

	# List of block that this filetype may send back
	proc block_list { } {
		return ""
	}
		

	# Display a small image. In fact nothing to do. Everything is
	# done in the 2small action.
	proc 2png { current_env filename } {
		upvar $current_env fas_env

		# What is the real filename to take the content from ?
		set real_filename [fas_name_and_dir::get_real_filename small $filename fas_env]

		# Basically launching page_to_menu but in taking
		# all informations from the current_env variable
		fas_depend::set_dependency $real_filename file

		set fid [open $real_filename]
		fconfigure $fid -translation { binary binary }
		fconfigure stdout -translation { binary binary }
		set content [read $fid]
		close $fid
		return $content
	}

}
