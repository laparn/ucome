# Used for automatic actions and type generation
# Without argument send back a list of file types and actions
# With an argument allow to access to the type documentation.
# The doc contains the following informations :
#  * content type or action
#  * specific environment variables
#  * mimetypes of direct output
#  * possible to create this file or not
#  * a comment output by the doc function of the corresponding namespace
#  * if there are local_conf variables display of them
#  * if get_title exists or not

lappend filetype_list ucome_doc

namespace eval ucome_doc {
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
		return [list comp]
	}

	proc important_session_keys { } {
		return [list]
	}

	proc env { args } {
		return [list]
	}

	proc 2comp { current_env args } {
		fas_debug "ucome_doc::2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval 2fashtml env $args]]
		return "[array get tmp]"
	}

	proc get_filetype_lists { } {
		global filetype_list

		set content_list [list]
		set action_list [list]
		foreach filetype $filetype_list {
			if { ![info exists ::${filetype}::done] } {
				# It is a content
				lappend content_list $filetype
			} else {
				# It is an action
				lappend action_list $filetype
			}
		}
		set content_list [lsort $content_list]
		set action_list [lsort $action_list]

		return [list $content_list $action_list]
	}
		
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		fas_debug "ucome_doc::fas_html - entering"
		
		# if no filetype args, then I send back the list
		global _cgi_uservar

		# Getting the list of actions and content type
		set all_lists [get_filetype_lists]
		set content_list [lindex $all_lists 0]
		set action_list [lindex $all_lists 1]

		if { ![info exists _cgi_uservar(filetype)] } {
			fas_debug "ucome_doc::fas_html - list of all content and action"
			# First displaying the content_type in alphabetical order
			fas_debug "ucome_doc::fas_html - content_list => $content_list, action_list => $action_list"
			# Now getting a template
			set template_name [fas_name_and_dir::get_template_name fas_env ucome_doc_list.template]
			fas_depend::set_dependency $template_name file
			atemt::read_file_template_or_cache "UCOME_DOC_LIST" "$template_name"

			# So a list for the content_type and a list for the actions
			# odd or even type
			set icons_url [fas_name_and_dir::get_icons_dir]
			set export_filename [rm_root $filename]
			set even 1
			foreach content_type $content_list {
				if $even {
					atemt::atemt_set CURRENT_CONTENT_TYPE -bl [atemt::atemt_set EVEN_CONTENT_TYPE]
					set even 0
				} else {
					atemt::atemt_set CURRENT_CONTENT_TYPE -bl [atemt::atemt_set ODD_CONTENT_TYPE]
					set even 1
				}
				atemt::atemt_set CONTENT_LIST -bl [atemt::atemt_subst -insert -block CURRENT_CONTENT_TYPE CONTENT_LIST]
				
			}
			set even 1
			foreach action $action_list {
				if $even {
					atemt::atemt_set CURRENT_ACTION_TYPE -bl [atemt::atemt_set EVEN_ACTION_TYPE]
					set even 0
				} else {
					atemt::atemt_set CURRENT_ACTION_TYPE -bl [atemt::atemt_set ODD_ACTION_TYPE]
					set even 1
				}
				atemt::atemt_set ACTION_LIST -bl [atemt::atemt_subst -insert -block CURRENT_ACTION_TYPE ACTION_LIST]
			}
			atemt::atemt_set UCOME_DOC_LIST -bl [atemt::atemt_subst -block CONTENT_LIST -block ACTION_LIST UCOME_DOC_LIST]
			return [atemt::atemt_subst -end UCOME_DOC_LIST]
		} else {
			# I get the action of file type
			set current_filetype $_cgi_uservar(filetype)
			# Does it exist ?
			if { [llength [info commands ::${current_filetype}::new_type]] } {
				#  * content type or action
				#  * specific environment variables
				#  * mimetypes of direct output
				#  * possible to create this file or not
				#  * a comment output by the doc function of the corresponding namespace
				#  * if there are local_conf variables display of them
				#  * if get_title exists or not
				# Getting the list of extensions
				global conf
				set all_extensions_list [array names conf "extension.*"]
				set extension_list ""
				foreach extension_string $all_extensions_list {
					if { $conf(${extension_string}) == $current_filetype } {
						set good_extension [string range "${extension_string}" 10 end]
						lappend extension_list $good_extension
					}
				}
				fas_debug "ucome_doc::fashtml - all_extensions_list => $all_extensions_list"
				fas_debug "ucome_doc::fashtml - extension_list => $extension_list"
				set mimetype ""
				if { [llength [info commands ::${current_filetype}::mimetype]] } {
					set mimetype [::${current_filetype}::mimetype]
				}

				set new_flag 0
				if { [llength [info commands ::${current_filetype}::new]] } {
					set new_flag 1
				}

				set action_flag 0
				if { [info exists ::${current_filetype}::done] } {
					set action_flag 1
				}

				set doc ""
				if { [llength [info commands ::${current_filetype}::ucome_doc]] } {
					set doc [extract_body [::txt::content2fashtml fas_env [::${current_filetype}::ucome_doc] -t "Documentation" -nti]]
				}

				set local_conf_list ""
				if { [llength [info commands ::${current_filetype}::local_conf_list]] } {
					set local_conf_list [::${current_filetype}::local_conf_list]
				}

				set env_lol ""
				if { [llength [info commands ::${current_filetype}::env]] } {
					set env_lol [::${current_filetype}::env]
				}

				# Looking for the next and previous element
				# Is it a content ?
				set content_index [lsearch $content_list $current_filetype]
				set action_index [lsearch $action_list $current_filetype]

				set next ""
				set previous ""
				if { $content_index != -1 } {
					# It is a content
					if { $content_index == 0 } {
						set next [lindex $content_list 1]
						set previous [lindex $content_list end]
					} elseif { $content_index == [expr [llength $content_list] -1] } {
						set next [lindex $content_list 0]
						set previous [lindex $content_list [expr $content_index - 1]]
					} else {
						set next [lindex $content_list [expr $content_index + 1]]
						set previous [lindex $content_list [expr $content_index - 1]]
					}
				} else {
					# It is an action
					if { $action_index == 0 } {
						set next [lindex $action_list 1]
						set previous [lindex $action_list end]
					} elseif { $action_index == [expr [llength $action_list] -1] } {
						set next [lindex $action_list 0]
						set previous [lindex $action_list [expr $action_index - 1]]
					} else {
						set next [lindex $action_list [expr $action_index + 1]]
						set previous [lindex $action_list [expr $action_index - 1]]
					}
				}

				set template_name [fas_name_and_dir::get_template_name fas_env ucome_doc.template]
				fas_depend::set_dependency $template_name file
				atemt::read_file_template_or_cache "UCOME_DOC" "$template_name"

				# So a list for the content_type and a list for the actions
				# odd or even type
				set icons_url [fas_name_and_dir::get_icons_dir]
				set export_filename [rm_root $filename]

				atemt::atemt_set FILETYPE $current_filetype
				atemt::atemt_set DOC $doc
				atemt::atemt_set EXTENSION_LIST $extension_list
				atemt::atemt_set MIMETYPE $mimetype
				if !$new_flag {
					atemt::atemt_set NEW -bl [atemt::atemt_set NOT_NEW]
				}

				if !$action_flag {
					atemt::atemt_set ACTION -bl [atemt::atemt_set NOT_ACTION]
				}

				foreach {key value} $local_conf_list {
					atemt::atemt_set LOCAL_CONF_BLOCK -bl [atemt::atemt_subst -insert -block LOCAL_CONF LOCAL_CONF_BLOCK]
				}

				foreach env_list $env_lol {
					set env_name [lindex $env_list 0]
					set env_desc [translate [lindex $env_list 1]]
					set env_level [translate [lindex $env_list 2]]
					atemt::atemt_set ENV_BLOCK -bl [atemt::atemt_subst -insert -block ENV ENV_BLOCK]
				}

				atemt::atemt_set UCOME_DOC -bl [atemt::atemt_subst -vn -block DOC UCOME_DOC]
				atemt::atemt_set UCOME_DOC -bl [atemt::atemt_subst -block FILETYPE -block MIMETYPE -block EXTENSION_LIST -block NEW -block ACTION -block LOCAL_CONF_BLOCK -block ENV_BLOCK -block TOP -block BOTTOM UCOME_DOC]
				return [atemt::atemt_subst -end UCOME_DOC]
			} else {
				return "${current_filetype} [translate " is not a filetype or an action available in ucome"]"
			}
		}
	}
}
				
