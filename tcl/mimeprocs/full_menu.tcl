# full_menu is an action. You may ask it on any file
# and it will send you back the full menu and submenus, ...
# for all directory/files and subdirectory of
# the current file/directory. It needs no input.
# It may be used for getting a map of a site.


# It would be a good idea to factorise the code with menu.
# It is just a copy with some minor modifications
lappend filetype_list full_menu

namespace eval full_menu {
	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	set done 0

	proc new_type { current_env filename } {
		# When a tmpl is met, in what filetype will it be by default
		# translated ?
		#set conf(newtype.txt) htmf
		# This is the default answer
		set result comp
		# Now there may be other cases
		variable done
		set done 1
		if { [fas_get_value new_type_option -default standard] == "notmpl" } {
			set result fashtml
		}
		fas_debug "full_menu::new_type -> $result "
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
		lappend env_list [list "full_menu.template" "Html file with special tags for creating a hierarchical menu depending of the directory structure." webmaster]
		lappend env_list [list "full_menu.menuroot" "Relative directory to root_directory giving the directory start for building a menu" webmaster]
		return $env_list
	}

	# List of block that this filetype may send back
	proc block_list { } {
		return [list full_menu::full_menu]
	}
		

	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
	
		set content_string ""
		set state parse_args

		# What is the real filename to take the content from ?
		set real_filename [fas_name_and_dir::get_real_filename full_menu $filename fas_env]

		# Basically launching page_to_menu but in taking
		# all informations from the current_env variable
		set template_name [fas_name_and_dir::get_template_name fas_env full_menu.template]
		set root_menu_dir [fas_name_and_dir::get_full_menu_start_dir fas_env]
		# depth to which I should go from the root directory
		set default_depth 4

		fas_debug "full_menu::2fashtml - root_menu_dir -> $root_menu_dir"

		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file
		# And on the template
		fas_depend::set_dependency $template_name file

		# The output depends on some variables in the env files
		fas_depend::set_dependency $filename env
		#set content [page_to_menu $template_name $root_menu_dir $filename $default_depth "fas:[rm_root $root_menu_dir]"]
		global FAS_VIEW_CGI
		set content [page_to_menu $template_name $root_menu_dir $filename $default_depth "${FAS_VIEW_CGI}?file=[rm_root $root_menu_dir]"]
		return $content
	}

	proc 2comp { current_env filename } {
		upvar $current_env fas_env

		set tmp(content.content) [extract_body [2fashtml fas_env $filename] ]
		return [array get tmp]
	}

	


	# create a menu
	# So from a template, I will start from the menu section
	# then I will take the section subsection and subsubsection elements
	# as well as the activesection activesubsection and activesubssubsection
	# Then I will try to create a real menu with these elements.

	#
	# template_name : the full file name of the template including the directory,
	# root : the root of this local site,
	# end : place where the information for creating the menu will be taken from
	# rooturl : url of the root directory
	proc page_to_menu { template_name root end depth rooturl } {
		fas_debug "full_menu::page_to_menu - $template_name - $root - $depth - $rooturl"
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
		fas_debug "full_menu::page_to_menu - end - $end"
		set current_menu_lol [order_menu_lol [directory_menu_lol $root $end ]]
		#fas_debug "full_menu::page_to_menu - $current_menu_lol"
		#fas_debug_parray atemt::_atemt "fas_menu.tcl - page_to_menu"
		generate_menu_html $current_menu_lol 0 1 $root $rooturl $template_name
		fas_debug "full_menu::page_to_menu ----------------------------"
		fas_debug "full_menu::page_to_menu MENU -> $::atemt::_atemt(MENU)"
		fas_debug "full_menu::page_to_menu ----------------------------"
		fas_debug "full_menu::page_to_menu -> $::atemt::_atemt($template_name)"
		# I think that I do not need the next line
		# set atemt::_atemt($template_name) [atemt::atemt_subst -vn -block MENU -block BOTTOM  -block CONTENT -block TITLE $template_name]
		#fas_debug_parray atemt::_atemt "fas_menu.tcl - page_to_menu --- before end subst"
		global FAS_VIEW_CGI
		atemt::atemt_set $template_name -bl [atemt::atemt_subst -block MENU $template_name]
		fas_debug "full_menu::page_to_menu ----------------------------"
		fas_debug "full_menu::page_to_menu -> $::atemt::_atemt($template_name)"
		set final_html [atemt::atemt_subst -end $template_name]
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
		fas_debug "full_menu::directory_menu_lol - root -> $root, end -> $end"
		fas_debug "full_menu::directory_menu_lol - $dir_list"
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
			fas_debug "full_menu::----------- $dir ------------"
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
					fas_debug "full_menu::directory_menu_lol - Found $dir at start of $end"
					if { [string match $dir $end] } {
						set IS_ROOT_AT_START 2
					} else {
						set IS_ROOT_AT_START 1 
					}
				}
				if { [file type $dir] == "directory" } {
					if { $AUTO_MENU_FLAG } {
						set REST_OF_MENU [directory_menu_lol $dir $end -auto ]
					} else {
						set REST_OF_MENU [directory_menu_lol $dir $end ]
					}
				}
				lappend result_list [list $dir $name $order $IS_ROOT_AT_START $REST_OF_MENU]
			}
			if [info exists dir_env] {
				unset dir_env
			}
			set AUTO_MENU_FLAG $CALLING_AUTO_MENU_FLAG
		}
		fas_debug "full_menu::directory_menu_lol - result_list ==> $result_list"
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
	proc generate_menu_html { menu_lol section_level last_section_flag root rooturl template_name} {
		fas_debug "full_menu::generate_menu_html - $menu_lol - $section_level - $root - $rooturl - $template_name"
		# I suppose that I have an ordered list of elements
		# I just have to go through this ordered list and to add the elements
		# to the template.

		# I am entering in a menu level, I must first insert
		# at the beginning a section start
		if { [info exists ::atemt::_atemt(LEVEL_START$section_level)] } {
			atemt::atemt_set MENU_ENTRY -bl [atemt::atemt_set "LEVEL_START${section_level}"]
			atemt::atemt_set MENU  -bl [atemt::atemt_subst -insert -block MENU_ENTRY MENU]
		} elseif { [info exists ::atemt::_atemt(LEVEL_START)] } {
			atemt::atemt_set MENU_ENTRY -bl [atemt::atemt_set "LEVEL_START"]
			atemt::atemt_set MENU  -bl [atemt::atemt_subst -insert -block MENU_ENTRY MENU]
		}

		set number 1
		set menu_lol_length [llength $menu_lol]
		set new_last_section_flag 0
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
			set generic_section_type "GENERIC_SECTION"
			set generic_space_type "GENERIC_SPACE"
			#if { [lindex $menu_list 3] == 1 } {
			#	fas_debug "full_menu::generate_menu_html - found ACTIVE $section_type"
			#	set section_type "ACTIVE$section_type"
			#} elseif { [lindex $menu_list 3] == 2 } {
			#	fas_debug "full_menu::generate_menu_html - found EXACT $section_type"
			#	set section_type "EXACT$section_type"
			#} else {
			#	fas_debug "full_menu::generate_menu_html - found  $section_type"
			#}
			if { [lindex $menu_list end] != "" } {
				set section_type "SOURCE_${section_type}"
				set generic_section_type "SOURCE_${generic_section_type}"
				set generic_space_type "SOURCE_${generic_space_type}"
			}
			if { $number == $menu_lol_length } {
				set section_type "LAST_${section_type}"
				set generic_section_type "LAST_${generic_section_type}"
				set generic_space_type "LAST_${generic_space_type}"
				set new_last_section_flag 1
			}

			# if the section type exist, no problem. Else I generate a generic section
			# for this kind of section. I use the same procedure as in treedir
			if { ![info exists ::atemt::_atemt($section_type)] } {
				#switch -exact [lindex $menu_list 3] {
				#	2 {
				#		set generic_section_type "GENERIC_EXACTSECTION"
				#		set generic_space_type "GENERIC_EXACTSPACE"
				#	}
				#	1 {
				#		set generic_section_type "GENERIC_ACTIVESECTION"
				#		set generic_space_type "GENERIC_ACTIVESPACE"
				#	}
				#	default {
				#		set generic_section_type "GENERIC_SECTION"
				#		set generic_space_type "GENERIC_SPACE"
				#	}
				#}
				#fas_debug_parray ::atemt::_atemt "In menu, is GENERIC_SECTION defined here ?"
				#set generic_section_type "GENERIC_SECTION"
				#set generic_space_type "GENERIC_SPACE"
				#if { [lindex $menu_list end] != "" } {
				#	fas_debug "full_menu::generate_menu_html - found SOURCE_GENERIC_SECTION"
				#	set generic_section_type "SOURCE_GENERIC_SECTION"
				#	set generic_space_type "SOURCE_GENERIC_SPACE"
				#}
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
			atemt::atemt_set MENU  -bl [atemt::atemt_subst -insert -block MENU_ENTRY MENU]
			if { [lindex $menu_list end] != "" } {
				set sub_menu_lol [lindex $menu_list end]
				generate_menu_html $sub_menu_lol [expr $section_level + 1] $new_last_section_flag $root $rooturl $template_name
			}
			incr number
		}

		# I am leaving a menu level, I must insert
		# at the end a section end
		set level_prefix ""
		if $last_section_flag {
			set level_prefix "LAST_"
		}

		if { [info exists ::atemt::_atemt(${level_prefix}LEVEL_END$section_level)] } {
			atemt::atemt_set MENU_ENTRY -bl [atemt::atemt_set "${level_prefix}LEVEL_END${section_level}"]
			atemt::atemt_set MENU  -bl [atemt::atemt_subst -insert -block MENU_ENTRY MENU]
		} elseif { [info exists ::atemt::_atemt(${level_prefix}LEVEL_END)] } {
			atemt::atemt_set MENU_ENTRY -bl [atemt::atemt_set "${level_prefix}LEVEL_END"]
			atemt::atemt_set MENU  -bl [atemt::atemt_subst -insert -block MENU_ENTRY MENU]
		}

	}
	#fas_debug_parray ::atemt::_atemt "generate_menu_html - leaving -----------------------"
}
