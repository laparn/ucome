# no extensions for prop_form
lappend filetype_list allow_action_form

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval allow_action_form {
	# At the end of the copy I set it at 1.
	# I will use it when changing of state
	set done 0

	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		set result comp
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
		return [list comp]
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
		lappend env_list [list "allow_action_form.template" "Template used when displaying the properties of a file  ." webmaster]
		return $env_list
	}

	proc 2comp { current_env args } {
		fas_debug "allow_action_form::2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval 2fashtml env $args]]
		return "[array get tmp]"
	}

	proc content2comp { current_env args } {
		fas_debug "prop_form::content2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval content2fashtml env $args ]]
		return "[array get tmp]"
	}

	proc get_action_list { } {
		# First I must get the list of actions
		# To do that I start from the file_type_list
		# and check if there is a done variable in the namespace
		# If so, it is an action
		set action_list ""
		global filetype_list
		foreach filetype $filetype_list {
			if { [info exists ${filetype}::done] } {
				lappend action_list $filetype
			}
		}
		set action_list [lsort $action_list]
		return $action_list
	}
		
	
	# This procedure will translate create the html text for the properties
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI

		fas_debug "allow_action_form::2fashtml -- entering for $filename"
	
		
		set export_filename [rm_root $filename]

		# All authorisation are in the allow.$action env
		# or allow.all_actions
		# And now I prepare the display
		# work on the template
		fas_depend::set_dependency $filename file
		fas_depend::set_dependency $filename env
		# Getting the template
		if { [catch { set template_name [fas_name_and_dir::get_template_name fas_env allow_action_form.template] } errStr] } {
			fas_display_error "allow_action_form::2fashtml - [translate "Please define env variables"] allow_action_form.template<br>${errStr}" fas_env
			atemt::atemt_set TOP -bl [atemt::atemt_subst -block MESSAGE TOP]
		}
		fas_depend::set_dependency $template_name file
		if { [catch { atemt::read_file_template_or_cache "ALLOW_TEMPLATE" "$template_name" } errStr ] } {
			fas_display_error "allow_action_form::2fashtml - [translate "Problem while opening template "] ${template_name}<br>${errStr}" fas_env -f $filename
		}
		# Not so simple - preparing the variable
		#eval lappend action_list "all_actions" [get_action_list]
		set action_list [get_action_list]
		lappend action_list "all_actions"
		lappend action_list "view"
		set action_list [lsort $action_list]
		atemt::set_html TITLE "[translate "Authorisations for"] [rm_root $filename]"
		atemt::atemt_set HEAD_TITLE -bl [atemt::atemt_set TITLE]
		atemt::atemt_set ALLOW_TEMPLATE -bl [atemt::atemt_subst -block TITLE ALLOW_TEMPLATE]
		atemt::atemt_set TOP -bl [atemt::atemt_subst -block HEAD_TITLE TOP]

		# if there is a message, I display it
		global _cgi_uservar
		if { [info exists _cgi_uservar(message)] } {
			atemt::set_html MESSAGE "$_cgi_uservar(message)<br>"
			atemt::atemt_set TOP -bl [atemt::atemt_subst -block MESSAGE TOP]
		}
		set icons_url [fas_name_and_dir::get_icons_dir]
		set counter 0
		foreach action $action_list {
			atemt::atemt_set NEW_ACTION_LIST -bl [atemt::atemt_set ACTION_LIST]
			set row_type [expr $counter % 4]
			atemt::atemt_set ROW_START -bl [atemt::atemt_set ROW_${row_type}]
			atemt::atemt_set NEW_ACTION_LIST -bl [atemt::atemt_subst -block ROW_START NEW_ACTION_LIST]
			atemt::atemt_set NEW_ACTION_LIST -bl [atemt::atemt_subst -block CHECK NEW_ACTION_LIST]
			set content [translate $action]
			atemt::atemt_set NEW_ACTION_LIST -bl [atemt::atemt_subst -block ACTION NEW_ACTION_LIST]
			atemt::atemt_set NEW_USER_LIST -bl [atemt::atemt_set USER_LIST]
			if { [info exists fas_env(allow.${action})] } {
				foreach user $fas_env(allow.$action) {
					set content $user
					atemt::atemt_set NEW_USER_LIST -bl [atemt::atemt_subst -insert -block USER NEW_USER_LIST]
				}
			} else {
				# nothing to do
				set content ""
				atemt::atemt_set NEW_USER_LIST -bl [atemt::atemt_subst -insert -block USER NEW_USER_LIST]
			}
			atemt::atemt_set END_ROW -bl [atemt::atemt_set END_ROW_${row_type}]
			atemt::atemt_set NEW_ACTION_LIST -bl [atemt::atemt_subst -block NEW_USER_LIST -block END_ROW NEW_ACTION_LIST]
			atemt::atemt_set ALLOW_TEMPLATE -bl [atemt::atemt_subst -insert -block NEW_ACTION_LIST ALLOW_TEMPLATE]
			incr counter
		}
		atemt::atemt_set ALLOW_TEMPLATE -bl [atemt::atemt_subst -block TOP \
						-block BOTTOM ALLOW_TEMPLATE]
		set final_html [atemt::atemt_subst -end ALLOW_TEMPLATE]
		return $final_html
	}
				
		
	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to get the properties of a content. It must be a filename."]</b></center></body></html>"
	}
}
