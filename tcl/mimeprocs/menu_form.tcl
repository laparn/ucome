lappend filetype_list menu_form

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval menu_form {
	# At the end of the copy I set it at 1.
	# I will use it when changing of state
	set done 0
	global INIT_ACTION
	eval $INIT_ACTION

	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	proc new_type { current_env filename } {
		# When a txt is met, in what filetype will it be by default
		# translated ?
		# This is the default answer
		set result comp
		# copy_form type must appear only once after that when
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
		return [list comp fashtml ]
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
		lappend env_list [list "menu_form.template" "Template used when editing the menu of a directory." webmaster]
		return $env_list
	}

	proc 2comp { current_env args } {
		fas_debug "menu_form::2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval 2fashtml env $args]]
		return "[array get tmp]"
	}

	proc content2comp { current_env args } {
		fas_debug "menu_form::content2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval content2fashtml env $args ]]
		return "[array get tmp]"
	}
	proc get_menu_lists { current_env first_list} {
		upvar $current_env fas_env
		global conf
		global _cgi_uservar
		set MENU_AUTO_FLAG 0
		if { [info exists _cgi_uservar(menu_auto_flag) ] } {
			set MENU_AUTO_FLAG $_cgi_uservar(menu_auto_flag)
		}
		# I come from a previous menu_form,
		# I must create the lol from it
		set inmenu_file_lol [list]
		set outmenu_file_lol [list ${first_list}]
		set counter 0
		while { [info exists _cgi_uservar(file_on${counter})] } {
			set current_file $_cgi_uservar(file_on${counter})
			set current_shortname [file tail $current_file]
			set extension [file extension $current_file]
			regsub "$extension\$" $current_shortname {} current_shortname
			set in_menu_flag 0
			if { [info exists _cgi_uservar(checkbox_on${counter})] } {
				set in_menu_flag $_cgi_uservar(checkbox_on${counter})
			}
			catch { unset file_env } 
			read_full_env $current_file file_env
			set current_filetype [guess_filetype $current_file conf file_env]
			set current_menuname ""
			if { [info exists _cgi_uservar(fasenv.menu.name.${counter})] } {
				set current_menuname $_cgi_uservar(fasenv.menu.name.${counter})
			}
			set current_menuorder "10000"
			if { [info exists _cgi_uservar(fasenv.menu.order.${counter})] } {
				set current_menuorder $_cgi_uservar(fasenv.menu.order.${counter})
			}

			set current_list [list $current_file $current_filetype $current_shortname $current_menuname $current_menuorder]
			if $in_menu_flag {
				lappend inmenu_file_lol $current_list
			} else {
				lappend outmenu_file_lol $current_list
			}
			incr counter
		}
		set counter 0
		while { [info exists _cgi_uservar(file${counter})] } {
			set current_file $_cgi_uservar(file${counter})
			set current_shortname [file tail $current_file]
			set extension [file extension $current_file]
			regsub "$extension\$" $current_shortname {} current_shortname
			set in_menu_flag 0
			if { [info exists _cgi_uservar(checkbox${counter})] } {
				set in_menu_flag $_cgi_uservar(checkbox${counter})
			}
			catch { unset file_env } 
			read_full_env $current_file file_env
			set current_filetype [guess_filetype $current_file conf file_env]
			# I should take menu.name and menu.order from the properties
			# for this file. I am lazy (tonight ?).

			read_dir_env $current_file menu_env
			set current_menuname "$current_shortname"
			set current_menuorder "10000"
			fas_debug_parray menu_env "menu_form::2fashtml - menu_env for $current_file"
			if { [info exists menu_env(menu.name)] } {
				set current_menuname $menu_env(menu.name)
			}
			if { [info exists menu_env(menu.order)] } {
				set current_menuorder $menu_env(menu.order)
			}
			set current_list [list $current_file $current_filetype $current_shortname $current_menuname $current_menuorder]
			if $in_menu_flag {
				lappend inmenu_file_lol $current_list
			} else {
				lappend outmenu_file_lol $current_list
			}
			incr counter
		}
		return [list $inmenu_file_lol $outmenu_file_lol $MENU_AUTO_FLAG]
	}
	# This procedure will translate create the html text for a copy
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI
		# First the dependencies :
		fas_depend::set_dependency $filename file
		fas_depend::set_dependency [file join $filename .mana] file
		set from view
		global _cgi_uservar
		if { [info exists _cgi_uservar(from)] } {
			set from $_cgi_uservar(from)
		}

		# I need to get the filetype
		global conf
		set this_filetype [guess_filetype $filename conf fas_env]

		# The different cases are the following :
		# * take the list of menus from the env properties of each file,
		# * take them from a previous screen
		# * record the result finally
		global _cgi_uservar
		set first_list [list file filetype shortname fasenv.menu.name fasenv.menu.order]
		if { [info exists _cgi_uservar(store_name)] } {
			# It is asked to be stored
			# So I take the current_values as previously
			# and I store them
			set result_lolol [get_menu_lists fas_env $first_list]
			set inmenu_file_lol [lindex $result_lolol 0]
			set outmenu_file_lol [lindex $result_lolol 1]
			set MENU_AUTO_FLAG [lindex $result_lolol 2]
			set error_string ""
			set errors 0
			# Storing the results for the files in the menu
			foreach file_list $inmenu_file_lol {
				set current_file [lindex $file_list 0]
				set current_menu_name [lindex $file_list 3]
				set current_menu_order [lindex $file_list 4]
				catch { unset current_env }
				# Once it works, I should catch the next call
				if { [catch { read_dir_env [add_root $current_file] current_env } read_error ] } {
					incr errors
					append error_string "<br>$read_error"
				}
				set current_env(menu.name) $current_menu_name
				set current_env(menu.order) $current_menu_order
				if { [catch { write_all_env [add_root $current_file] current_env } write_error ] } {
					incr errors
					append error_string "<br>$write_error"
				}
			}
			# Now I must display something, so I use the usual trick
			# I try to have a "from", to determine where I started from.
			# It will be either view or edit_form
			global _cgi_uservar
			unset _cgi_uservar
			if { $from == "edit_form" } {
				set _cgi_uservar(action) edit_form
			} else {
				set _cgi_uservar(action) view
			}
			if { $errors > 0 } {
				set message $error_string
			} else {
				set message "[translate "Succesful storing of menu"]"
			}
			set _cgi_uservar(message) "$message"
			display_file $this_filetype $filename fas_env conf
			fas_exit
		} elseif { [info exists _cgi_uservar(file_on0)] || [info exists _cgi_uservar(file0)] } {
			set result_lolol [get_menu_lists fas_env $first_list]
			set inmenu_file_lol [lindex $result_lolol 0]
			set outmenu_file_lol [lindex $result_lolol 1]
			set MENU_AUTO_FLAG [lindex $result_lolol 2]
		} else {
			# I will do the following thing :
			#  * create a list like the one used for dir::2edit_form
			#    with files being in the menu.
			#  * create the html corresponding for editing in using
			#    display fonction from dir
			#  * create a list of files not being in the menu
			#  * create the html corresponding for editing
			#  * then look, if I am in an "initial mode", or
			#    if I need to get the informations imported
			#    then change the list given above in functions
			#    of these importations.
			#  * at the end store this menu.

			# I may try to have 2 sections defined in the comp
			# and playing with that for integrating it all.
			# That may be nice. I mean :
			# section_inmenu 
			# section_notinmenu
			# sending that to the comp, and the comp integrate it all
			# as being 2 sections. Then I put the form within the template
			# used for displaying these conf. But I need a special comp
			# and a special template (not standard) and it is not nice.
			# First the automenu flag
			set MENU_AUTO_FLAG 0
			if { [info exists fas_env(menu.auto) ] } {
				if { $fas_env(menu.auto) } {
					# Then it is menu_auto
					set MENU_AUTO_FLAG 1
				}
			}
			# is the file a directory or a file. If it is a file, I take the directory
			if { [file isdirectory $filename] } {
				set use_filename $filename
			} else {
				set use_filename [file dirname $filename]
			}
			set file_lol [::dir::get_file_lol $use_filename fas_env -w [list filetype shortname fasenv.menu.name fasenv.menu.order] -f *]


			set first_list [lindex $file_lol 0]
			set inmenu_file_lol [list]
			set outmenu_file_lol [list $first_list]
			# I get the file_lol for this directory in the menu
			# I will take :
			#   file, shortname, filetype, fasenv.menu.name fasenv.menu.order
			# after all, why not just filtering the result of get_file_lol
			# and splitting the result in 2 ?

			set rest_of_lol [lrange $file_lol 1 end]
			foreach file_list $rest_of_lol {
				set menu.name [lindex $file_list 3]
				set menu.order [lindex $file_list 4]

				if { ( ${menu.name} == "" ) && ( ${menu.order} == "" ) } {
					# It is not in the menu
					lappend outmenu_file_lol $file_list
				} else {
					# It is in the menu, but where ?
					# If order is not defined, I put it at the very end
					if { ${menu.order} == "" } {
						set file_list [lreplace $file_list 4 4 "10000"]
					}
					lappend inmenu_file_lol $file_list
				}
			}
		}
		fas_debug "menu_form::2fashtml - outmenu_file_lol : $outmenu_file_lol \n<br> inmenu_file_lol : $inmenu_file_lol"
		# Now I order this mess
		set order_inmenu_file_lol $inmenu_file_lol
		catch { set order_inmenu_file_lol [lsort -integer -index 4 $inmenu_file_lol] }
		# And I replace the numbers by 1, 2, 3, ... instead of a mess
		set final_inmenu_file_lol [list $first_list]
		set counter 1
		foreach inmenu_file_list $order_inmenu_file_lol {
			set inmenu_file_list [lreplace $inmenu_file_list 4 4 $counter]
			lappend final_inmenu_file_lol $inmenu_file_list
			incr counter
		}

		# And now, I can ask for a display
		set inmenu_html [extract_body [::dir::display_file_lol $final_inmenu_file_lol fas_env -display [list select_on filetype shortname fasenv.menu.name fasenv.menu.order] -title [translate "In menu"] -noadd 1 -form 0]]
		set outmenu_html [extract_body [::dir::display_file_lol $outmenu_file_lol fas_env -display [list select filetype shortname] -title [translate "Out of menu"] -noadd 1 -form 0]]

		fas_debug "menu_form::2fashtml - inmenu_html : $inmenu_html<br> outmenu_html : $outmenu_html"

		# Now I must put these 2 html within a small form template, and that's it

		# Load the template
		set dfl_template_name [fas_name_and_dir::get_template_name fas_env "menu_form.template"]
		atemt::read_file_template_or_cache "MENU_FORM_TEMPLATE" "$dfl_template_name" 
		fas_depend::set_dependency $dfl_template_name file
		# Getting the default icons_url path
		set icons_url [fas_name_and_dir::get_icons_dir]
		set export_filename [rm_root $filename]

		# put in the 2 sections the html
		atemt::atemt_set INMENU $inmenu_html
		atemt::atemt_set OUTMENU $outmenu_html

		# finish it
		atemt::atemt_set FORM -bl [atemt::atemt_subst -block INMENU -block OUTMENU FORM]
		atemt::atemt_set MENU_FORM_TEMPLATE -bl [atemt::atemt_subst -block FORM MENU_FORM_TEMPLATE]
		return [atemt::atemt_subst -end MENU_FORM_TEMPLATE]
	}

	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to edit the menu of a content. It must be a filename."]</b></center></body></html>"
	}
}
