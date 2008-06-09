lappend filetype_list search_form

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval search_form {
	# When the copy is done, I set it to 1.
	set done 0
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global INIT_ACTION
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		set result fashtml
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
		fas_debug "search_form::2comp - $args"
		upvar $current_env fas_env
		array set tmp ""
		set tmp(content.content) [extract_body [eval 2fashtml fas_env $args]]
		return "[array get tmp]"
	}

	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI
		set template_name [fas_name_and_dir::get_template_name fas_env search_form.template]
		fas_depend::set_dependency $template_name file
		atemt::read_file_template_or_cache "SEARCH_FORM" "$template_name"

		set icons_url [fas_name_and_dir::get_icons_dir]
		set export_filename [rm_root $filename]

		atemt::atemt_set SEARCH_FORM -bl [atemt::atemt_subst -all SEARCH_FORM]
		return [atemt::atemt_subst -end SEARCH_FORM]
	}
}
