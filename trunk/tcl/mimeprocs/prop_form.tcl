# no extensions for prop_form
lappend filetype_list prop_form

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval prop_form {
	# At the end of the copy I set it at 1.
	# I will use it when changing of state
	set done 0

	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		# When a prop is met, in what filetype will it be by default
		# translated ?
		# This is the default answer
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
		return [list treedir tmpl fashtml ]
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
		lappend env_list [list "prop_form.template" "Template used when displaying the properties of a file  ." webmaster]
		return $env_list
	}

	proc 2treedir { current_env args } {
		fas_debug "prop_form::2treedir - $args"
		upvar $current_env env
		return "[eval 2fashtml env $args ]"
	}
	
	proc content2treedir { current_env args } {
		fas_debug "copy_form::content2treedir - $args"
		upvar $current_env env
		return "[eval content2fashtml env $args ]"
	}
	
	proc 2comp { current_env args } {
		fas_debug "prop_form::2comp - $args"
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
	
	proc 2tmpl { current_env args } {
		fas_debug "copy_form::2tmpl - $args"
		upvar $current_env env
		return "[eval 2fashtml env $args ]"
	}
	
	proc content2tmpl { current_env args } {
		fas_debug "copy_form::content2tmpl - $args"
		upvar $current_env env
		return "[eval content2fashtml env $args ]"
	}
	
	# This procedure will translate create the html text for the properties
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI

		fas_debug "prop_form::2fashtml -- entering for $filename"
	
		
		set export_filename [rm_root $filename]
		set dir [rm_root [file dirname $filename]]

		# First getting the inherited values :
		set directory [file dirname $filename]

		read_full_env $directory inherited_env

		# Now the values specific to the file
		array set file_env ""
		catch { read_dir_env $filename file_env }
		# read_dir_env $filename file_env 
		fas_debug_parray file_env "prop_form::2fashtml -- file_env array"

		# Which Property level (user, webmaster or admin) do
		# I wish to see
		set level [ImportVariable level -default user]

		# OK now I need to know the possible new_type of this file
		# and the associated properties.
		global conf
		set filetype [guess_filetype $filename conf fas_env]
		set type_list [get_possible_file_type $filetype "[list $filetype]"]
		lappend type_list any

		# I also need the same thing for actions.
		# First I get all the actions
		eval lappend type_list [allow_action_form::get_action_list]

		# Now I build the property list for each possible_type
		set all_env_list ""
		foreach type $type_list {
			if { ![catch {set type_lol [${type}::env]} ] } {
				set final_list ""
				foreach current_list $type_lol {
					set var_name [lindex $current_list 0]
					set DESCRIPTION [translate [lindex $current_list 1]]
					set LEVEL [lindex $current_list 2]
					#set list_fr [lindex $current_list 2]
					if { [info exists inherited_env($var_name)] } {
						set INHERITED_FLAG 1
						set INHERITED_VALUE $inherited_env($var_name)
					} else {
						set INHERITED_FLAG 0
						set INHERITED_VALUE ""
					}
					if { [info exists file_env($var_name)] } {
						set FILE_FLAG 1
						set FILE_VALUE $file_env($var_name)
					} else {
						set FILE_FLAG 0
						set FILE_VALUE ""
					}
					#set DESCRIPTION [lindex $list_en 1]
					if { $LEVEL == $level } {	
						lappend final_list [list $var_name $INHERITED_FLAG $INHERITED_VALUE $FILE_FLAG $FILE_VALUE $DESCRIPTION]
					}
				}
			}
			# If there are properties to be set I show the file_type
			# else I avoid to display anything.
			if { [llength $final_list] > 0 } {
				lappend all_env_list [list $type $final_list]
			}
		}
		fas_debug "prop_form::2fashtml -- all_env_list => $all_env_list"


		# And now I prepare the display
		# work on the template
		fas_depend::set_dependency $filename file
		fas_depend::set_dependency $filename env
		# Getting the template
		if { [catch { set template_name [fas_name_and_dir::get_template_name fas_env prop_form_${level}.template] } errStr] } {
			fas_display_error "prop_form::2fashtml - [translate "Please define env variables"] prop_form.template<br>${errStr}" fas_env
		}
		fas_depend::set_dependency $template_name file
		if { [catch { atemt::read_file_template_or_cache "PROP_TEMPLATE" "$template_name" } errStr ] } {
			fas_display_error "xxx:2edit_form - [translate "Problem while opening template "] ${template_name}<br>${errStr}" fas_env -f $filename
		}
		# Not so simple - preparing the variable
		global DEBUG
		atemt::set_html TITLE "[translate "Env variables for"] [rm_root $filename]"
		atemt::set_html FILENAME [rm_root $filename]
		set atemt::_atemt(FORM) [atemt::atemt_subst -block FILENAME FORM]
		set icons_url [fas_name_and_dir::get_icons_dir]
		#set icons_url [fas_get_value icons_url -default "fas:/icons"]
		set dir [rm_root [file dirname $filename]]
		set COUNTER 0
		foreach current_all_list $all_env_list {
			set TYPE [lindex $current_all_list 0]
			set env_list [lindex $current_all_list 1]
			set atemt::_atemt(CURRENT_LINE) $atemt::_atemt(TYPE_LINE)
			set atemt::_atemt(FORM) [atemt::atemt_subst  -insert -block CURRENT_LINE FORM]
			fas_debug "prop_form::2fashtml - inserting line for $TYPE"
			foreach current_list $env_list {
				set PROP_NAME [lindex $current_list 0]
				set INHERITED_FLAG [lindex $current_list 1]
				set INHERITED_VALUE [lindex $current_list 2]
				set LOCAL_FLAG [lindex $current_list 3]
				set LOCAL_VALUE [lindex $current_list 4]
				set PROP_DESCRIPTION [lindex $current_list 5]

				if { $INHERITED_FLAG } {
					set I_FLAG_STRING "checked"
				} else {
					set I_FLAG_STRING ""
				}
				if { $LOCAL_FLAG } {
					set L_FLAG_STRING "checked"
				} else {
					set L_FLAG_STRING ""
				}
				set atemt::_atemt(CURRENT_LINE) $atemt::_atemt(PROP_LINE)
				set atemt::_atemt(FORM) [atemt::atemt_subst  -insert -block CURRENT_LINE FORM]
				fas_debug "prop_form::2fashtml - inserting line for prop : $PROP_NAME"
				incr COUNTER
			}
		}
		set atemt::_atemt(PROP_TEMPLATE) [atemt::atemt_subst -block TITLE -block FORM PROP_TEMPLATE]
		set final_html [atemt::atemt_subst -end PROP_TEMPLATE]
		return $final_html
	}
				
	# I try to get the list of all possible filetypes for this file.
	# filetype : the current filetype,
	# filelist : the list of possible filetypes
	proc get_possible_file_type { file_type type_list} {
		fas_debug "prop_form::get_possible_file_type -- file_type -> $file_type , type_list -> $type_list"
		# First index of filetype
		set current_index [lsearch -exact $type_list $file_type]
		if { $current_index < 0 } {
			error "prop_form::get_possible_file_type - $file_type [translate "should be in type_list"] ($type_list)" "prop_form::get_possible_file_type - $file_type [translate "should be in type_list"] ($type_list)" 
		} else {
			fas_debug "prop_form::get_possible_file_type info commands -- [catch { ${file_type}::new_type_list } ] "
			# fas_debug "prop_form::get_possible_file_type -- ${file_type}::new_type_list ->[${file_type}::new_type_list] "
			if { ![catch { ${file_type}::new_type_list } new_type_list ] } {
				#set new_type_list [$file_type::new_type_list]
				fas_debug "prop_form::get_possible_file_type -- new_type_list -> $new_type_list"
				eval lappend type_list $new_type_list
				set type_list [lsort -unique $type_list]
				fas_debug "prop_form::get_possible_file_type -- current type_list -> $type_list"
				set next_index [expr $current_index + 1]
				if { $next_index < [llength $type_list] } {
					set next_type [lindex $type_list $next_index]
					fas_debug "prop_form::get_possible_file_type -- next_type -> $next_type"
					set type_list [get_possible_file_type $next_type $type_list]
				} ; # else just send back $type_list, I am at the end, I go back	
			}
		}
		fas_debug "prop_form::get_possible_file_type result is type_list -> $type_list"
		return $type_list
	} 
		
	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to get the properties of a content. It must be a filename."]</b></center></body></html>"
	}
}
