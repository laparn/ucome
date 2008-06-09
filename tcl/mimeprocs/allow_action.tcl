# no extensions for prop_form
lappend filetype_list allow_action

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval allow_action {
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
		lappend env_list [list "allow_action.template" "Template used when displaying the form for choosing users allowed to perform given actions." webmaster]
		return $env_list
	}

	proc 2comp { current_env args } {
		fas_debug "allow_action::2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval 2fashtml env $args]]
		return "[array get tmp]"
	}

	proc content2comp { current_env args } {
		fas_debug "allow_action::content2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval content2fashtml env $args ]]
		return "[array get tmp]"
	}

	# Import the actions for which we will display the authorisations
	proc import_action_list {  } {
		global _cgi_uservar
		set counter 0
		set action_list [list]
		while { [info exists _cgi_uservar(action${counter})] } {
			set current_action $_cgi_uservar(action${counter})
			if { [info exists _cgi_uservar(checkbox${counter})] } {
				if { $_cgi_uservar(checkbox${counter}) } {
					lappend action_list $current_action
				}
			}
			incr counter
		}
		return $action_list
	}

		
				
	# This procedure will create the html text for the list of users
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		global FAS_PROG_ROOT

		fas_debug "allow_action::2fashtml -- entering for $filename"

		# For debugging purpose, I put a dependency on the source file
		fas_depend::set_dependency ${FAS_PROG_ROOT}/mimeprocs/allow_action.tcl
	
		# Minimal variables to have defined before any template
		global FAS_VIEW_CGI
		set export_filename [rm_root $filename]
		set icons_url [fas_name_and_dir::get_icons_dir]

		# All authorisation are in the allow.$action env
		# or allow.all_actions
		# And now I prepare the display
		# work on the template
		fas_depend::set_dependency $filename file
		fas_depend::set_dependency $filename env
		# Getting the template
		if { [catch { set template_name [fas_name_and_dir::get_template_name fas_env allow_action.template] } errStr] } {
			fas_display_error "allow_action::2fashtml - [translate "Please define env variables"] allow_action.template<br>${errStr}" fas_env
		}
		fas_depend::set_dependency $template_name file
		if { [catch { atemt::read_file_template_or_cache "ALLOW_TEMPLATE" "$template_name" } errStr ] } {
			fas_display_error "allow_action::2fashtml - [translate "Problem while opening template "] ${template_name}<br>${errStr}" fas_env -f $filename
		}
		# Not so simple - preparing the variable
		# First the list of actions we are dealing with
		set action_list [import_action_list]
		set current_user_list [list]

		set counter 0
		foreach action $action_list {
			set content $action

			atemt::atemt_set TOP -bl [atemt::atemt_subst -insert -block ACTION TOP]
			atemt::atemt_set TOP -bl [atemt::atemt_subst -insert -block EXPORT_ACTION TOP]
			incr counter
		}

		atemt::atemt_set ALLOW_TEMPLATE -bl [atemt::atemt_subst -block TOP ALLOW_TEMPLATE]
		
		set allowed_user_list [eval fas_user::get_allowed_user_for_action fas_env $action_list]
		fas_debug "allow_action::2fashtml : allowed_user_list for $action_list => $allowed_user_list"
		set counter 0
		fas_debug "allow_comp::2fashtml get_user_list => [fas_user::get_user_list fas_env]"
		set user_list [list *]
		lappend user_list [fas_user::get_user_list fas_env]
		foreach user $user_list {
			atemt::atemt_set NEW_USER_ROW -bl [atemt::atemt_set USER_ROW]
			set row_type [expr $counter % 6]
			atemt::atemt_set ROW_START -bl [atemt::atemt_set ROW_${row_type}]
			atemt::atemt_set NEW_CHECK -bl [atemt::atemt_set CHECK]
			atemt::atemt_set NEW_USER_ROW -bl [atemt::atemt_subst -block ROW_START NEW_USER_ROW]
			set content $user
			if { [lsearch $allowed_user_list $user] > -1 } {
				atemt::atemt_set NEW_CHECK -bl [atemt::atemt_subst -block CHECK_ON NEW_CHECK]
			} else {
				atemt::atemt_set NEW_CHECK -bl [atemt::atemt_subst -block CHECK_OFF NEW_CHECK]
			}
			atemt::atemt_set NEW_USER_ROW -bl [atemt::atemt_subst -block NEW_CHECK NEW_USER_ROW]
			atemt::atemt_set END_ROW -bl [atemt::atemt_set END_ROW_${row_type}]
			atemt::atemt_set NEW_USER_ROW -bl [atemt::atemt_subst -block USER -block END_ROW NEW_USER_ROW]
			atemt::atemt_set ALLOW_TEMPLATE -bl [atemt::atemt_subst -insert -block NEW_USER_ROW ALLOW_TEMPLATE]
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
