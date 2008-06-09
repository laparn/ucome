# no extensions for rrooll_param
lappend filetype_list rrooll_param

namespace eval rrooll_param {
	# At the end of the rrooll I set it at 1.
	# I will use it when changing of state
	set done 0
	global INIT_ACTION
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		fas_fastdebug {rrooll_param::new_type $filename}

		variable done
		set done 1
		return "fashtml"
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list fashtml]
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
		lappend env_list [list "rrooll_param.template" "Template used when preparing a rroolling file." admin]
		return $env_list
	}
	
	# This procedure will translate/create the html text for a rrooll
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI

		# Getting the template
		set template_name [fas_name_and_dir::get_template_name fas_env rrooll_param.template]
		fas_debug "rrooll_param::2fashtml - template file is $template_name"
		# Getting the dependencies for the template file
		fas_depend::set_dependency $template_name file

		# load the block named "RROOLL_PARAM_TEMPLATE" from the file given by $template_name
		atemt::read_file_template_or_cache "RROOLL_PARAM_TEMPLATE" "$template_name"
		fas_debug "rrooll_param::2fashtml - $template_name has been read with success"

		# define values for some blocks
		#atemt::set_html FILENAME "[rm_root $filename]"
		#atemt::set_html TITLE "[translate "Rroolling form for"] [rm_root $filename]"
		#set atemt::_atemt(RROOLL_PARAM_TEMPLATE) [atemt::atemt_subst -block FILENAME -block TITLE RROOLL_PARAM_TEMPLATE]

		# Preparing the variables
		#set icons_url [fas_get_value icons_url -default "fas:/icons"]
		#set icons_url [fas_name_and_dir::get_icons_dir]
		set export_filename [rm_root $filename]
		#set dir [rm_root [file dirname $filename]]
		#set target_dir [fas_get_value dir -default "$dir"]

		# Setting some other blocks in the template
		atemt::set_html START_DELAY [fas_get_value start_delay -noenv -nosession -default 1000]
		atemt::set_html END_DELAY [fas_get_value end_delay -noenv -nosession -default 1000]
		atemt::set_html LINE_JUMP_DELAY [fas_get_value line_jump_delay -noenv -nosession -default 10]
		#atemt::set_html RROOLL_URL "\"fas:/$export_filename\""
		set file_url "[fashtml::to_right_url "fas:$export_filename" {} ""]$export_filename&target=rrooll"
		atemt::set_html RROOLL_URL "\"$file_url\""
		# and substitute
		fas_debug_parray atemt::_atemt "rrooll_param::2fashtml - atemt::_atemt before substitution"
		set atemt::_atemt(RROOLL_PARAM_TEMPLATE) [atemt::atemt_subst -block START_DELAY -block END_DELAY -block LINE_JUMP_DELAY -block RROOLL_URL RROOLL_PARAM_TEMPLATE]
		fas_debug_parray atemt::_atemt "rrooll_param::2fashtml - atemt::_atemt after substitution"
		
		# Here there is filename and dir to substitute

		return [atemt::atemt_subst -end RROOLL_PARAM_TEMPLATE]
	}

	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to rrooll a content. It must be a filename."]</b></center></body></html>"
	}

	proc display { current_env filename } {
		# A procedure for just sending the output on the
		# stdout.
		upvar $current_env fas_env

		puts stdout "[2fashtml fas_env $filename]"
	
		return 
	}
}
