set ::DOMP_PROCEDURES {
	set local_conf(comp) "${local_filetype}.form"

	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		fas_fastdebug {fas_domp.tcl::new_type $filename}
		upvar $current_env fas_env
		# When a todo is met, in what filetype will it be by default
		# translated ?
		set result comp
		# Now there may be other cases

		if { ![catch {set action [fas_get_value action] } ] } {
			if { $action != "view" } {
				#if { $action == "edit_form" } {
				#	set result comp
				#} else { }
				# there is an action. Is it done or not
				if { [set ${action}::done ] == 0 } {
					fas_debug "comp::new_type - action -> $action , action::done -> [set ${action}::done]"
					# the action was not processed
					set result $action
					return $result
				} ; # else I continue
			}
		}
		if { ![catch {set target [fas_get_value target -noe]}] } {
			# we are in the standard case nothing to do
			switch -exact -- $target {
				txt4index {
					set result comp
				}
				ori {
					set result txt
					#error 1
					return ""
				}
				rrooll -
				rool {
					fas_debug_parray fas_env "fas_domp.tcl::new_type fas_env before down_stage_env with rool"
					down_stage_env fas_env "rrooll.cgi_uservar."
					fas_debug_parray fas_env "fas_domp.tcl::new_type fas_env after down_stage_env with rool"
					return "rrooll"
				}
				rrooll1 -
				rool1 {
					fas_debug_parray fas_env "fas_domp.tcl::new_type fas_env before down_stage_env with rrooll1"
					down_stage_env fas_env "rrooll1.cgi_uservar."
					fas_debug_parray fas_env "fas_domp.tcl::new_type fas_env after down_stage_env with rrooll1"
					return "rrooll"
				}
				rrooll2 -
				rool2 {
					fas_debug_parray fas_env "fas_domp.tcl::new_type fas_env before down_stage_env with rrooll2"
					down_stage_env fas_env "rrooll2.cgi_uservar."
					fas_debug_parray fas_env "fas_domp.tcl::new_type fas_env after down_stage_env with rrooll2"
					return "rrooll"
				}
				rrooll3 -
				rool3 {
					fas_debug_parray fas_env "fas_domp.tcl::new_type fas_env before down_stage_env with rrooll3"
					down_stage_env fas_env "rrooll3.cgi_uservar."
					fas_debug_parray fas_env "fas_domp.tcl::new_type fas_env after down_stage_env with rrooll3"
					return "rrooll"
				}
			}
		}
		fas_debug "comp::new_type - result is $result"

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
		lappend env_list [list "dompdir" "Directory where domp files are stored." admin]
		return $env_list
	}

	# if this function exists, then it is possible to
	# create a new txt with the editor.
	proc may_create { } {
		return 1
	}

	proc new { current_env current_conf dirname filename filetype ON_EXTENSION_FLAG } {
		variable local_filetype
		fas_debug "${local_filetype}::new - _env current_conf"
		upvar $current_env fas_env
		upvar $current_conf fas_conf

		# I will just create a particular name here ?
		global _cgi_uservar
		variable local_conf
		set _cgi_uservar(comp.####) "[file join [fas_name_and_dir::get_comp_dir fas_env domp] $local_conf(comp)]"
		set now [clock seconds]
		set month_list [list january february march april may june july august september november december]
		set _cgi_uservar(comp.date.content) "[clock format $now -format "%d"] [translate [lindex $month_list [expr [string trimleft [clock format $now -format "%m"] 0] - 1]]] [clock format $now -format "%Y"]"

		# I create a name for the file :
		# yearmonthday-hhmmss-user.todo
		set filename "[clock format $now -format "%Y%m%d-%H%M%S"]-[fas_user::who_am_i].${local_filetype}"

		comp::new fas_env fas_conf $dirname $filename ${local_filetype} $ON_EXTENSION_FLAG
	}

	proc mimetype { } {
		return "text/plain"
	}

	proc 2rrooll { current_env filename args } {
		fas_fastdebug {domp::2rrooll $filename}
		upvar $current_env fas_env

		variable local_filetype

		set fas_env(rrooll.command) "fashtml::content2htmf fas_env \[::comp::2fashtml fas_env ${filename} ${local_filetype}\] ${args}"
		# Test to avoid twice the same processing with the rool.tcl 
		return ""

		#return "[fashtml::content2htmf fas_env [::comp::2fashtml fas_env ${filename}] ${local_filetype}]"
	}

	# This procedure will translate a txt into a comp
	proc 2comp { current_env filename args } {
		variable local_filetype
		fas_debug "${local_filetype}::2comp - $args (from fas_domp.tcl)"
		upvar $current_env fas_env

		# I use the standard comp::2fashtml procedure,
		# and take the result to display it
		set tmp(content.content) [extract_body [::comp::2fashtml fas_env $filename ${local_filetype}]]
		# I need to load the file, and then to add 
		# todo.comp as #### if it does not exist.
		# Then send that back.
		#set real_filename [fas_name_and_dir::get_real_filename todo $filename fas_env]
		#fas_depend::set_dependency $real_filename file
		#fas_depend::set_dependency $filename env

		#if { [catch {read_env $filename todo_array} error ] } {
		#	fas_display_error "todo::2comp - [translate "Could not load a todo file :"] [rm_root $real_filename]<br>$error" -file $filename
		#}
		# Now adding a #### if it does not exist
		#variable local_conf
		#if { ![info exists todo_array(####)] } {
		#	set todo_array(####) [file join [fas_name_and_dir::get_comp_dir fas_env] $local_conf(todo.comp)]
		#}

		# OK I can send it back
		return [array get tmp]
	}

	proc get_title { filename } {
		variable local_filetype
		fas_debug "${local_filetype}::get_title entering"
		# The title is the title entry of the file
		set title ""
		if { [catch {read_env $filename my_array} error ] } {
			fas_display_error "${local_filetype}::2comp - [translate "Could not load a ${local_filetype} file :"] [rm_root $real_filename]<br>$error" -file $filename
		}

		if { [info exists my_array(title.content)] } {
			set title $my_array(title.content)
		}
		if { [info exists my_array(titre.content)] } {
			set title $my_array(titre.content)
		}
		fas_debug "${local_filetype}::get_title found ->$title<-"
		return $title
	}
	
	# Here there is a bug, as the dependencies given by comp::2edit_form
	# concerns a comp file and not todo => the dependencies are wrong !!!
	proc 2edit_form { current_env filename } {
		variable local_filetype
		upvar $current_env fas_env

		# I must be the edit form of the corresponding comp
		# but with a todo form controller
		# How can I do that ?
		return [comp::2edit_form fas_env $filename ${local_filetype}]
	}
	
	proc 2edit { current_env filename } {
		upvar $current_env fas_env
		variable local_filetype

		return [comp::2edit fas_env $filename ${local_filetype}]
	}
		
	proc content_display { current_env content } {
		upvar $current_env env
		return "[not_binary::content_display fashtml $content]"
	}
		
	proc display { current_env filename } {
		# A procedure for just displaying the file in html directly
		upvar $current_env fas_env
		return "[not_binary::display fas_env $filename txt]"
	}
	proc content { current_env filename } {
		# A procedure for just displaying the file in html directly
		upvar $current_env fas_env
		return "[not_binary::content fas_env $filename tmpl]"
	
	}

	#proc 2txt4index { current_env filename } {
	#	upvar $current_env fas_env
	#	set real_filename [fas_name_and_dir::get_real_filename txt $filename env]
	#	# Basically, the output depends on the input file
	#	fas_depend::set_dependency $real_filename file
	#	return "[not_binary::content fas_env $filename txt]"
	#}
	proc 2txt4index { current_env filename args } {
		variable local_filetype
		fas_debug "${local_filetype}::2txt4index - $args"
		upvar $current_env fas_env

		set tmp(content.content) [::comp::2txt4index fas_env $filename ${local_filetype}]]
		return [array get tmp]
	}
}
