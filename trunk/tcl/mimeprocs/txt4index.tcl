lappend filetype_list "txt4index"

namespace eval txt4index {
	# At the end of indexing I set done to 1.
	# I will use it when changing of state

	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES


	set not_graphic_list [list txt tmpl fashtml htmf comp todo csv news]

	proc new_type { current_env filename } {
		# At the end of indexing, we will display edit_form
		# on the root_directory 
		#error 1
		return ""
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list]
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
		lappend env_list [list "txt4index.ignore" "Flag to 1 if a file or a directory should be ignored for indexing" "Drapeau à 1 si un fichier ou un répertoire ne doit pas être indexé pour la recherche" user]
		lappend env_list [list "txt4index.dir" "Directory where txt4index files should be kept" "Répertoire où les fichiers txt4index seront stockés" admin]
		return $env_list
	}

	proc display { current_env filename } {
		# A procedure for just displaying the file in html directly
		upvar $current_env fas_env
		fas_debug "txt4index::display $filename"
		set real_filename [fas_name_and_dir::get_real_filename txt4index $filename fas_env]
		return "[not_binary::display fas_env $real_filename txt]"
	}

	proc content { current_env filename } {
		# A procedure for just displaying the file in html directly
		upvar $current_env fas_env
		fas_debug "txt4index::content $filename"
		set real_filename [fas_name_and_dir::get_real_filename txt4index $filename fas_env]
		fas_debug "txt4index::content $real_filename"
		return "[not_binary::content fas_env $real_filename txt]"
	}
}
