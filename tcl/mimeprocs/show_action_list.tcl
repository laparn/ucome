# no extensions for prop_form
lappend filetype_list show_action_list

set _(-file-view-) "View"
set _(-file-logout-) "Logout"
set _(-file-view-target-ori-) "Ori."
set _(-file-view-target-pdf-) "Pdf"
set _(-file-view-target-nomenu-) "No menu"
set _(-file-edit_form-) "Edit"
set _(-file-prop_form-) "Prop."
set _(-file-allow_action_form-) "Rights"
set _(-dir-view-) "Dir."
set _(-dir-edit_form-) "Edit dir."
set _(-file-menu_form-) "Edit menu"
set _(-file-admin-) "Admin."
set _(-file-candidate_order-) "Candidat rool"
set _(-file-login_form-) "Log in/out"

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval show_action_list {
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
		lappend env_list [list "show_action_list.template" "Template used when displaying allowed actions for a file." admin]
		return $env_list
	}

	proc 2comp { current_env args } {
		fas_debug "show_action_list::2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval 2fashtml env $args]]
		return "[array get tmp]"
	}

	proc content2comp { current_env args } {
		fas_debug "show_action_list::content2comp - $args"
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
		return $action_list
	}

	# I end up with a list of list. In each list, there is a ready
	# to be used to create an url the list of key value to put after
	# the cgi call. At start of each list there is an option, either -file (it is a file)
	# or -dir (it is the dir of the current file).
	# Input is a list of list
	# Each input list is :
	# "an_action" param1 "value_param1" param2 "value_param2"
	# At the end a list of list, which list are allowed actions and
	# -dir|-file file $filename action "an_action" param1 "value_param1" param2 "value_param2"
	proc test_action_list { current_env filename action_lol option } {
		upvar $current_env fas_env
		set allowed_action_lol [list]
		foreach action_list $action_lol {
			set current_action [lindex $action_list 0]
			fas_debug "show_action_list::test_action_list - is -- $filename $current_action -- allowed ?"
			if { [fas_user::allowed_action $filename $current_action fas_env] } {
				fas_debug "yes"
				# This action is allowed I append it to the
				# final allowed actions
				set real_action_list [linsert $action_list 0 $option file [rm_root $filename] action]
				lappend allowed_action_lol $real_action_list
			} else {
				fas_debug "no"
			}
		}
		fas_debug "show_action_list::test_action_list allowed_action_lol => $allowed_action_lol"
		return $allowed_action_lol
	}

	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env

		fas_debug "show_action_list:2fashtml -- entering for $filename"
		
		set export_filename [rm_root $filename]

		# I suppose that I have as 2 input list of list with :
		# show_action_list.file_action
		# [list [list action_xxx other_param yyyy other_param zzz]
		#             [list action_eee other_param sdf other_param sfsfd]]
		# show_action_list.dir_action
		# [list [list action_sjfsf param1 sfdsf] 
		#           [list action_sdsfs param2 sdfsdf]]
		# The first list is for the current file, the second is
		# for the current directory.
		# I need the corresponding fas_env for the directory.
		# I load the environment for the dir (if it is not previously
		# loaded), and I ask if this action is allowed for this file.
		# Then I create the final list in the order of the input list.
		fas_depend::set_dependency $filename env
		set file_action_lol [fas_get_value show_action_list.file_action -default ""]
		set allowed_action_list [test_action_list fas_env $filename $file_action_lol -file ]

		# So now I must the environment for the directory
		# Then do it again Joe
		set directory [file dirname $filename]
		array set dir_env ""
		if { ![catch {rm_root $directory} ] } {
			#fas_depend::set_dependency $directory env
			read_full_env $directory dir_env
			set file_action_lol [fas_get_value show_action_list.dir_action -default ""]
			eval lappend allowed_action_list [test_action_list dir_env $directory $file_action_lol -dir ]
		}



		# So now I have the full list of allowed actions. I just need
		# to create it. I will for each key/value pair create a 
		# variable and create a string to use for the link ???? . I will
		# also look for a corresponding section.
				
		# Getting the template
		if { [catch { set template_name [fas_name_and_dir::get_template_name fas_env show_action_list.template] } errStr] } {
			set message "show_action_list::2fashtml - [translate "Please define env variables"] show_action_list.template<br>${errStr}"
			return "$message"
		}
		fas_depend::set_dependency $template_name file
		if { [catch { atemt::read_file_template_or_cache "SHOW_ACTION_LIST_TEMPLATE" "$template_name" } errStr ] } {
			return "show_action_list::2fashtml - [translate "Problem while opening template "] ${template_name}<br>${errStr}" 
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
		foreach action_list $allowed_action_list {
			set dir_or_file [lindex $action_list 0]
			set current_action [lindex $action_list 4]
			fas_debug "show_action_list::2fashtml - action_list => $action_list"
			fas_debug "show_action_list::2fashtml - current action is $current_action"		
			set url "${FAS_VIEW_URL}?"
			set end_of_basic_name ""
			foreach {key value} [lrange $action_list 1 end] {
				append url "${key}=${value}&"
				set $key $value
				if { $key != "file" && $key != "action" } {
					append end_of_basic_name "${key}-${value}-"
				}
			}
			append url "from=${from}"
			set from $from
			set basic_text "${dir_or_file}-${current_action}-${end_of_basic_name}"
			set text [translate $basic_text]

			# Hypothesis url and text are to be used with icons url within STANDARD_BLOCK and
			# all other existing block
			if { [info exists atemt::_atemt([string toupper $basic_text])] } {
				atemt::atemt_set CURRENT_BLOCK -bl [atemt::atemt_set [string toupper $basic_text]]
			} else {
				atemt::atemt_set CURRENT_BLOCK -bl [atemt::atemt_set STANDARD_BLOCK]
			}
			atemt::atemt_set SHOW_ACTION_LIST_TEMPLATE -bl [atemt::atemt_subst -insert -block CURRENT_BLOCK SHOW_ACTION_LIST_TEMPLATE]
			incr counter
		}

		set final_html [atemt::atemt_subst -end SHOW_ACTION_LIST_TEMPLATE]
		return $final_html
	}
				
		
	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to get the properties of a content. It must be a filename."]</b></center></body></html>"
	}
}
