# no extensions for prop_form
lappend filetype_list show_target_list

set _(ori) "Ori."
set _(pdf) "Pdf"
set _(nomenu) "No menu"
set _() "View"

# Display a list of allowed target for this file
namespace eval show_target_list {
	# At the end of the copy I set it at 1.
	# I will use it when changing of state
	set done 0

	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION


	proc new_type { current_env filename } {
		set result fashtml
		# property_form type must appear only once after that when
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
		lappend env_list [list "show_target_list.template" "Template used when displaying allowed targets for a file." admin]
		lappend env_list [list "show_target_list.target_list" "A list of target to show for each file." admin]
		return $env_list
	}

	proc 2comp { current_env args } {
		fas_debug "show_target_list::2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval 2fashtml env $args]]
		return "[array get tmp]"
	}

	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		fas_debug "show_target_list:2fashtml -- entering for $filename"
		
		set export_filename [rm_root $filename]
		fas_depend::set_dependency $filename env
		set target_list [fas_get_value show_target_list.target_list -default ""]

		# So now I have the full list of targets. I just need
		# to create it. I will for each key/value pair create a 
		# variable and create a string to use for the link ???? . I will
		# also look for a corresponding section.
				
		# Getting the template
		if { [catch { set template_name [fas_name_and_dir::get_template_name fas_env show_target_list.template] } errStr] } {
			set message "show_target_list::2fashtml - [translate "Please define env variables"] show_target_list.template<br>${errStr}"
			return "$message"
		}
		fas_depend::set_dependency $template_name file
		if { [catch { atemt::read_file_template_or_cache "SHOW_TARGET_LIST_TEMPLATE" "$template_name" } errStr ] } {
			return "show_target_list::2fashtml - [translate "Problem while opening template "] ${template_name}<br>${errStr}" 
		}
		set icons_url [fas_name_and_dir::get_icons_dir]
		# I also try to have a from variable defined
		set from "view"
		global _cgi_uservar
		if { [info exists _cgi_uservar(from)] } {
			set from $_cgi_uservar(from)
		}
		set counter 0
		global FAS_VIEW_URL
		global FAS_VIEW_CGI
		foreach target $target_list {
			set url "fas:"
			append url "${export_filename}"
			if { $target != "" } {
				append url "&target=${target}"
			}
			set basic_name "$target"
			append url "from=${from}"
			set from $from
			set basic_text "$target"
			set text [translate $basic_text]

			# Hypothesis url and text are to be used with icons url within STANDARD_BLOCK and
			# all other existing block
			if { [info exists atemt::_atemt([string toupper $basic_text])] } {
				atemt::atemt_set CURRENT_BLOCK -bl [atemt::atemt_set [string toupper $basic_text]]
			} else {
				atemt::atemt_set CURRENT_BLOCK -bl [atemt::atemt_set STANDARD_BLOCK]
			}
			atemt::atemt_set SHOW_TARGET_LIST_TEMPLATE -bl [atemt::atemt_subst -insert -block CURRENT_BLOCK SHOW_TARGET_LIST_TEMPLATE]
			incr counter
		}

		set final_html [atemt::atemt_subst -end SHOW_TARGET_LIST_TEMPLATE]
		return $final_html
	}
				
		
	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to get the properties of a content. It must be a filename."]</b></center></body></html>"
	}
}
