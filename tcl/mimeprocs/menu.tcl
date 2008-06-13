# menu is an action. You may ask it on any file
# and it will send you back the menu corresponding
# to the current file. It needs no input.
# the file that was send before.
lappend filetype_list menu

namespace eval menu {
	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	set done 0

	proc new_type { current_env filename } {
		# When a tmpl is met, in what filetype will it be by default
		# translated ?
		#set conf(newtype.txt) htmf
		# This is the default answer
		set result fashtml
		# Now there may be other cases
		variable done
		set done 1
		fas_debug "menu::new_type -> $result "
		return $result
	}

	proc init { } {
		variable done
		set done 0
	}

	# List of possible types in which this file type may be converted
	proc new_type_list { } {
		return [list fashtml]
	}

	# This procedure returns the list of important session variables for
	# this type of file
	proc important_session_keys { } {
		# not any one
		return [list]
	}
	# Return the list of environment variables that are important
	proc env { args } {
		set env_list ""
		lappend env_list [list "menu.template" "Html file with special tags for creating a hierarchical menu depending of the directory structure." webmaster]
		lappend env_list [list "menu.menuroot" "Relative directory to root_directory giving the directory start for building a menu" webmaster]
		lappend env_list [list "menu.name" "Name used to display a file in a menu" user]
		lappend env_list [list "menu.order" "Rank in the menu of the file" user]
		lappend env_list [list "menu.auto" "Automatic menu generation from dir. or file name" user]
		return $env_list
	}

	# List of block that this filetype may send back
	proc block_list { } {
		return [list menu::menu]
	}
		
	proc 2fashtml { current_env filename } {
		fas_fastdebug {menu::2fashtml - entering}
		main_log "menu::2fashtml - entering"
		upvar $current_env fas_env
		return  [generic2fashtml fas_env -f $filename ]
	}
	
	proc content2fashtml { current_env content } {
		upvar $current_env fas_env
		return  [generic2fashtml fas_env -c $content ]
	}
	
	# Convert into html the input and return the corresponding
	# string.
	# -nocache : do not try to take or to write a cachefile
	# -c content : content to display
	# -f filename : file from which to take the content
	proc generic2fashtml { current_env args } {
		upvar $current_env fas_env
		set NOCACHE 0
		set CONTENT_TYPE ""
		set content_string ""
		set state parse_args
		foreach arg $args {
			switch -exact -- $state {
				parse_args {
					switch -glob -- $arg {
						-f* {
							#filename
							set state filename
						}
						-c* {
							#content
							set state content
						}
						-n* {
							#nocache
							set NOCACHE 1
						}
					}
				}
				filename {
					set filename $arg
					set CONTENT_TYPE "file"
					set state parse_args
				}
				content {
					set content $arg
					#set filename "$ROOT"
					#set real_filename $filename
					# filename is initialised here under
					set CONTENT_TYPE "string"
					set state parse_args
				}

			}
		}

		# What is the real filename to take the content from ?
		if { $CONTENT_TYPE == "file" } {
			set real_filename [fas_name_and_dir::get_real_filename menu $filename fas_env]
		}

		# Basically launching page_to_menu but in taking
		# all informations from the current_env variable
		set template_name [fas_name_and_dir::get_template_name fas_env menu.template]
		# Warning, I should test tmpl.menuroot existence
		# fas_debug_parray fas_env "tmpl::content2fashtml - content of env ->"
		#set root_menu_dir [add_root [fas_name_and_dir::get_root_dir]]
		#if { ![info exists fas_env(menu.menuroot) ] } {
		#	set fas_env(menu.menuroot) any
		#}
		#set root_menu_dir [file join $root_menu_dir [string trim $fas_env(menu.menuroot) /]]
		set root_menu_dir [add_root [fas_name_and_dir::get_menu_start_dir fas_env]]

		fas_debug "menu::content2fashtml - root_menu_dir -> $root_menu_dir"
		main_log "menu::content2fashtml - root_menu_dir -> $root_menu_dir"

		if { $CONTENT_TYPE == "file" } {
			# Basically, the output depends on the input file
			fas_depend::set_dependency $real_filename file
			# And on the template
			fas_depend::set_dependency $template_name file

			# The output depends on some variables in the env files
			fas_depend::set_dependency $filename env
			set content [page_to_menu $template_name $root_menu_dir $filename "fas:[rm_root $root_menu_dir]"]
		} else {
			# I have a direct content
			set filename $root_menu_dir
			set real_filename $filename
			set content [page_to_menu $template_name $root_menu_dir $filename "fas:[rm_root $root_menu_dir]"]
		}
		return $content
	}

	# create_menu
	# So from a template, I will start from the menu section
	# then I will take the section subsection and subsubsection elements
	# as well as the activesection activesubsection and activesubssubsection
	# Then I will try to create a real menu with these elements.

	#
	# template_name : the full file name of the template including the directory,
	# root : the root of this local site,
	# end : place where the information for creating the menu will be taken from
	# rooturl : url of the root directory
	proc page_to_menu { template_name root end rooturl } {
		fas_debug "menu::page_to_menu - $template_name - $root - $end - $rooturl"
		global FAS_VIEW_CGI
		# For ecim look and style
		set icons_url [fas_name_and_dir::get_icons_dir]
		set CONTENT_TYPE ""
		set title ""
		set state parse_args
		# First getting the template file
		# Is there a cache file
		#fas_debug_parray ::atemt::_atemt "menu::page_to_menu -> atemt::_atemt"
		atemt::read_file_template_or_cache "$template_name" "$template_name"
		#fas_debug_parray ::atemt::_atemt "menu::page_to_menu -> atemt::_atemt"
		# Now extracting the lol corresponding to the menu
		# expand_path remove any .. of a path
		set end [expand_path $end]
		fas_debug "menu::page_to_menu - end - $end"
		set current_menu_lol [order_menu_lol [directory_menu_lol $root $end ]]
		#fas_debug "page_to_menu - $current_menu_lol"
		#fas_debug_parray atemt::_atemt "fas_menu.tcl - page_to_menu"
		generate_menu_html $current_menu_lol 0 $root $rooturl $template_name
		fas_debug "menu::page_to_menu ----------------------------"
		fas_debug "menu::page_to_menu -> $::atemt::_atemt($template_name)"
		# I think that I do not need the next line
		# set atemt::_atemt($template_name) [atemt::atemt_subst -vn -block MENU -block BOTTOM  -block CONTENT -block TITLE $template_name]
		#fas_debug_parray atemt::_atemt "fas_menu.tcl - page_to_menu --- before end subst"
		atemt::atemt_set $template_name -bl [atemt::atemt_subst -block MENU $template_name]
		#set final_html [atemt::atemt_subst -end $template_name]
		set final_html [atemt::atemt_subst_end $template_name]
		#fas_debug_parray atemt::_atemt "fas_menu.tcl - page_to_menu"
		#fas_debug "page_to_menu ####################################### END ############ => $final_html \n"
		return $final_html
	}
				  
	# First I need to order the incoming list
	proc order_menu_lol { menu_lol } {
		# TO do that I need to go through the menu list
		# and search for the leaf. Then I come back from on step and I order the list
		# First ordering the current menu :
		set current_menu_lol [lsort -index 2 -integer $menu_lol]
		# fas_debug "order_menu_lol - current_menu_lol - $current_menu_lol" 
		set index 0	
		foreach menu_list $current_menu_lol {
			if { [lindex $menu_list end] != "" } {
				set menu_list [lreplace $menu_list end end [order_menu_lol [lindex $menu_list end]]]
				set current_menu_lol [lreplace $current_menu_lol $index $index $menu_list]
			}
			incr index
		}
		return $current_menu_lol
	}

	# Creation of the menu
	# I will create a list of elements corresponding to directories in
	# the root directory. Each element will be :
	# * directory,
	# * name to use when representing the directory,
	# * 1 or 0 to know if it is or not the current branch of the directory
	# So I will have the first list with the different base directories,
	# the second with the second level elements and so on and so forth.
	# An element will be either a file or a directory.

	# Args :
	# root : the root of the directory
	# end : the current directory under examination
	# -auto : use the tail name of the file as the name
	#       : if tmpl.name does not exist
	proc directory_menu_lol { root end args } {
		# AUTO_MENU_FLAG defines if I try to create or not
		# automatically the menu name
		set AUTO_MENU_FLAG 0
		set CALLING_AUTO_MENU_FLAG 0
		if { [llength $args] > 0 } {
			set AUTO_MENU_FLAG 1
			# If the procedure is call in menu.auto mode
			# then I need to use and propagate it.
			# However, if I find a directory which is in menu.auto
			# I must not pollute the next directories at the same level
			# with it. That's why I introduce CALLING_AUTO_MENU_FLAG
			set CALLING_AUTO_MENU_FLAG 1
		}
		# I must put a dependency on the directory
		fas_depend::set_dependency $root file
		# And on the .mana directory
		fas_depend::set_dependency [file join $root .mana] file

		# First I need to know the content of the current directory
		# Directory and file
		set dir_list [glob -nocomplain -types {d f} -- [file join $root *]]
		fas_debug "menu::directory_menu_lol - root -> $root, end -> $end"
		fas_debug "menu::directory_menu_lol - $dir_list"
		set result_list ""
		foreach dir $dir_list {
			# The pb is the following. If a directory
			# does not appear in the menu, and after you give
			# it a tmpl.name and tmpl.order, then it must
			# appear. Then it is dependency : if it changes
			# it may impact the visual
			fas_depend::set_dependency $dir env
			read_all_env $root $dir dir_env
			if { [info exists dir_env(menu.auto)] } {
				set AUTO_MENU_FLAG 1
			}
			fas_debug "menu::----------- $dir ------------"
			if { [info exists dir_env(menu.name)] || $AUTO_MENU_FLAG } {
				# parray dir_env
				if { [info exists dir_env(menu.name)] } {
					set name $dir_env(menu.name)
				} else {
					set name [file tail $dir]
				}
				# it is a file to use for the menu
				set order 1000000
				if [info exists dir_env(menu.order)] {
					set order $dir_env(menu.order)
				}
				# Does this directory or file matches exactly the start of current_end
				set IS_ROOT_AT_START 0
				set REST_OF_MENU ""
				if { [string first $dir $end] == 0 } {
					fas_debug "menu::directory_menu_lol - Found $dir at start of $end"
					if { [string match $dir $end] } {
						set IS_ROOT_AT_START 2
					} else {
						set IS_ROOT_AT_START 1 
					}
					if { [file type $dir] == "directory" } {
						if { $AUTO_MENU_FLAG } {
							set REST_OF_MENU [directory_menu_lol $dir $end -auto ]
						} else {
							set REST_OF_MENU [directory_menu_lol $dir $end ]
						}
					}
				} else {
					fas_debug "menu::directory_menu_lol - Could not find $dir at start of $end"
				}
				lappend result_list [list $dir $name $order $IS_ROOT_AT_START $REST_OF_MENU]
			}
			if [info exists dir_env] {
				unset dir_env
			}
			set AUTO_MENU_FLAG $CALLING_AUTO_MENU_FLAG
		}
		fas_debug "menu::directory_menu_lol - result_list ==> $result_list"
		return $result_list
	}

	# From the name of the file, I extract the url
	# For that I need to know the rooturl and root itself
	proc url_from_name { dirname root rooturl } {
		# First I suppress from dirname the start
		if { [string first $root $dirname] == 0 } {
			# I suppress from the start of dirname
			set current_string [string trimleft [string range $dirname [string length $root] end] "/"]
		} else {
			set current_string $dirname
		}
		return "$rooturl/$current_string"
	}

	# From now I should be able to generate the graphics
	proc generate_menu_html { menu_lol section_level root rooturl template_name} {
		global FAS_VIEW_CGI
		fas_debug "menu::generate_menu_html - $menu_lol - $section_level - $root - $rooturl - $template_name"
		# I suppose that I have an ordered list of elements
		# I just have to go through this ordered list and to add the elements
		# to the template.

		# This is the "Home / Root / Accueil allowing to go back to the root 
		if { [ atemt::exists "BEGIN_SECTION" ] && ( $section_level == "0" ) } {
			set url $rooturl
			# I need to find the string to display for $root
			read_full_env $root root_env
			if { [info exists root_env(menu.name)]} {
				# parray dir_env
				set content $root_env(menu.name)
			} else {
				set content [file tail $root]
			}
			atemt::atemt_set MENU_ENTRY -bl [atemt::atemt_set BEGIN_SECTION]
			atemt::atemt_set MENU -bl [atemt::atemt_subst_insert MENU_ENTRY MENU]
		}
		# Now the remaining
		foreach menu_list $menu_lol {
			# is this part active or not ?
			#if { $section_level == 0 } {		
			#	set section_type SECTION
			#} elseif { $section_level == 1 } {
			#	set section_type SUBSECTION
			#} else {
			#	set section_type SUBSUBSECTION
			#}
			set section_type "SECTION${section_level}"
			if { [lindex $menu_list 3] == 1 } {
				fas_debug "menu::generate_menu_html - found ACTIVE $section_type"
				set section_type "ACTIVE$section_type"
			} elseif { [lindex $menu_list 3] == 2 } {
				fas_debug "menu::generate_menu_html - found EXACT $section_type"
				set section_type "EXACT$section_type"
			} else {
				fas_debug "menu::generate_menu_html - found  $section_type"
			}

			# if the section type exist, no problem. Else I generate a generic section
			# for this kind of section. I use the same procedure as in treedir
			if { ![info exists ::atemt::_atemt($section_type)] } {
				switch -exact [lindex $menu_list 3] {
					2 {
						set generic_section_type "GENERIC_EXACTSECTION"
						set generic_space_type "GENERIC_EXACTSPACE"
					}
					1 {
						set generic_section_type "GENERIC_ACTIVESECTION"
						set generic_space_type "GENERIC_ACTIVESPACE"
					}
					default {
						set generic_section_type "GENERIC_SECTION"
						set generic_space_type "GENERIC_SPACE"
					}
				}
				#fas_debug_parray ::atemt::_atemt "In menu, is GENERIC_SECTION defined here ?"
				atemt::atemt_set MENU_ENTRY -bl [atemt::atemt_set $generic_section_type]
				# Now I add all the necessary spaces in CURRENTDIR
				for { set counter 0 } { $counter < $section_level } { incr counter } {
					atemt::atemt_set MENU_ENTRY -bl [atemt::atemt_subst -vn -insert -block $generic_space_type MENU_ENTRY]
				}
			} else {
				# I will have to test if this part is active or not		
				atemt::atemt_set MENU_ENTRY -bl [atemt::atemt_set $section_type]
			}
			set url [url_from_name [lindex $menu_list 0] $root $rooturl]  
			set content [lindex $menu_list 1]
			# I add this variable, in order to be able to have an option list
			# for the menu (ecim template)
			set current_filename [rm_root [lindex $menu_list 0]]
			
			atemt::atemt_set MENU -bl [atemt::atemt_subst_insert MENU_ENTRY MENU]
			if { [lindex $menu_list end] != "" } {
				set sub_menu_lol [lindex $menu_list end]
				generate_menu_html $sub_menu_lol [expr $section_level + 1] $root $rooturl $template_name
			}
		}
		if { [ atemt::exists "END_SECTION" ] } {
			atemt::atemt_set MENU_ENTRY -bl [atemt::atemt_set END_SECTION]
			atemt::atemt_set MENU -bl [atemt::atemt_subst_insert MENU_ENTRY MENU]
		}
	}
	
	#fas_debug_parray ::atemt::_atemt "generate_menu_html - leaving -----------------------"
}
