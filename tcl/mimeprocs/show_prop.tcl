# no extensions for show_prop
lappend filetype_list show_prop

# Action for displaying all env variables of a file
namespace eval show_prop {
	# At the end of the copy I set it at 1.
	# I will use it when changing of state
	set done 0

	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		set result comp
		variable done 
		set done 1
		return $result
	}

	proc new_type_list { } {
		return [list comp fashtml]
	}

	proc important_session_keys { } {
		return [list]
	}

	proc env { args } {
		set env_list ""
		return $env_list
	}

	
	proc 2comp { current_env filename args } {
		fas_debug "show_prop::2comp - $args"
		upvar $current_env fas_env

		set directory [file dirname $filename]
		read_full_env $directory inherited_env

		# Now the values specific to the file
		array set file_env ""
		read_dir_env $filename file_env
		set current_env_list [array names file_env]

		fas_depend::set_dependency $filename env

		# I create a trivial algorithm
		set export_filename [rm_root $filename]
		set content "<h1>Values for $export_filename</h1><br>\n"
		append content "<table><tr><td>Name</td><td>Value</td></tr>"
		foreach env_name [lsort [array names fas_env]] {
			# Just to know what is inherited and what is not
			if { [lsearch $current_env_list $env_name] >= 0 } {
				set bgcolor "#e0e0e0"
			} else {
				set bgcolor "#ffffff"
			}
			append content "<tr bgcolor=\"$bgcolor\"><td>"
			append content $env_name
			append content "</td><td>"
			append content "$fas_env($env_name)"
			append content "</td></tr>"
		}
		append content "</table>"

		array set tmp ""
		set tmp(content.content) "$content"
		return "[array get tmp]"
	}

}
