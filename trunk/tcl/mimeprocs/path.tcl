# menu is an action. You may ask it on any file
# and it will send you back the menu corresponding
# to the current file. It needs no input.
# the file that was send before.
lappend filetype_list path

namespace eval path {
	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	set done 0

	proc new_type { current_env filename } {
		set result fashtml
		# Now there may be other cases
		variable done
		set done 1
		fas_debug "path::new_type -> $result "
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
		lappend env_list [list "path.template" "Html file with special tags for displaying a path depending of the directory structure." webmaster]
		return $env_list
	}

	# List of block that this filetype may send back
	proc block_list { } {
		return [list path::path]
	}
		

	proc content2fashtml { current_env content } {
		upvar $current_env fas_env
		return  ""
	}
	
	# Convert into html the input and return the corresponding
	# string.
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env

		# What is the real filename to take the content from ?
		set real_filename [fas_name_and_dir::get_real_filename path $filename fas_env]

		# Basically launching page_to_menu but in taking
		# all informations from the current_env variable
		set template_name [fas_name_and_dir::get_template_name fas_env path.template]
		set root_menu_dir [add_root [fas_name_and_dir::get_menu_start_dir fas_env]]

		fas_debug "path::2fashtml - root_menu_dir -> $root_menu_dir"

		# And on the template
		fas_depend::set_dependency $template_name file

		# The output depends on some variables in the env files
		fas_depend::set_dependency $filename env
		set content [page_to_path $template_name $root_menu_dir $filename "fas:[rm_root $root_menu_dir]"]
		return $content
	}

	# page_to_path
	# Create a "path" toto > titit > xxxx with links
	# Use a template for the look. - SECTION (normal link) ENDSECTION (last link)
	# blocks are used in the template.
	# template_name : the full file name of the template including the directory,
	# root : the directory at which the menu starts.
	# end : the last file or directory of the "path"
	# rooturl : url of the root directory
	# Example : root - /tmp/ucometest/any  (menu.name = Home)
	#           end - /tmp/ucometest/any/using/fr/use.txt ( Home > Use > French > Utilisation )
	# with links to the respective directories except for the last page
	proc page_to_path { template_name root end rooturl } {
		fas_debug "path::page_to_path - $template_name - $root - $end - $rooturl"
		set title ""
		# First getting the template file
		# Is there a cache file
		atemt::read_file_template_or_cache "$template_name" "$template_name"
		fas_debug_parray atemt::_atemt "path::page_to_menu -> atemt::_atemt"
		# Now extracting the lol corresponding to the menu
		# expand_path remove any .. of a path
		set end [expand_path $end]
		fas_debug "path::page_to_menu - end - $end"
		# Create a lol with ( file or dir name - menu name ) as elementary list
		# for each element in the path.
		set current_path_lol [directory_path_lol $root $end ]
		generate_path_html $current_path_lol
		#fas_debug "path::generate_path_html ----------------------------"
		#fas_debug "path::page_to_menu -> $atemt::_atemt(PATH)"
		# I think that I do not need the next line
		atemt::atemt_set $template_name -bl [atemt::atemt_subst -block PATH $template_name]
		set final_html [atemt::atemt_subst -end $template_name]
		return $final_html
	}
				  

	# Creation of the path
	# I will create a list of elements corresponding to directories in
	# the root directory. Each element will be :
	# * directory,
	# * name to use when representing the directory,
	# So I will have the first list with the different base directories,
	# the second with the second level elements and so on and so forth.
	# An element will be either a file or a directory.

	# Args :
	# root : the root of the directory
	# end : the current directory under examination
	proc directory_path_lol { root end } {
		# AUTO_MENU_FLAG defines if I try to create or not
		# automatically the menu name
		# I must put a dependency on the directory
		fas_depend::set_dependency $root file
		# First I need to know the content of the current directory
		# Directory and file
		# There is only one dir : the one after root and before end
		set end_list [file split $end]
		# if the last element is index.xxxx - I remove it
		# as the directory will point to it directly
		if { [regexp {^index\.[^\.]+$} [lindex $end_list end] match ] } {
			# I remove the last element
			set end_list [lrange $end_list 0 end-1]
		}
		set root_list [file split $root]
		set length_root_list [llength $root_list]
		set length_end_list [llength $end_list]
		read_dir_env $root dir_env
		if { [info exists dir_env(menu.name)] } {
			set name $dir_env(menu.name)
		} else {
			set name "[translate "Home"]"
		}
		set current_list [list [rm_root $root]]
		set result_list [list [list [rm_root $root] $name]]
		for { set i $length_root_list } { $i < $length_end_list } { incr i } {
			lappend current_list [lindex $end_list $i]
			set current_path [eval file join / $current_list]
			#fas_depend::set_dependency $current_path env
			fas_depend::set_dependency [add_root $current_path] env
		 	catch { unset dir_env(menu.name) }
			read_dir_env [add_root [eval file join $current_list]] dir_env
			# fas_debug "path::directory_path_lol - read_dir_env root -> $root current_path -> $current_path dir_env"
			# fas_debug_parray dir_env "path::directory_path_lol - dir_env"
			if { [info exists dir_env(menu.name)] } {
				set name $dir_env(menu.name)
			} else {
				set name [file tail $current_path]
			}
			lappend result_list [list $current_path $name]
		}
		fas_debug "path::directory_path_lol - result_list ==> $result_list"
		return $result_list
	}

	# From now I should be able to generate the graphics
	proc generate_path_html { path_lol } {
		fas_debug "path::generate_path_html - $path_lol"
		# I suppose that I have an ordered list of elements
		# I just have to go through this ordered list and to add the elements
		# to the template.
		if { [llength $path_lol] > 1 } {
			fas_debug "path::generate_path_html - dealing with [lrange $path_lol 0 end-1]"
			foreach path_list [lrange $path_lol 0 end-1] {
				set path [lindex $path_list 0]
				set content [lindex $path_list 1]
				# I will have to test if this part is active or not		
				set atemt::_atemt(PATH_ENTRY) $atemt::_atemt(SECTION)
				set atemt::_atemt(PATH) [atemt::atemt_subst -insert -block PATH_ENTRY PATH]
			}
		}
		set path_list [lindex $path_lol end]
		fas_debug "path::generate_path_html - dealing with $path_list"
		set path [lindex $path_list 0]
		set content [lindex $path_list 1]
		# I will have to test if this part is active or not		
		set atemt::_atemt(PATH_ENTRY) $atemt::_atemt(ENDSECTION)
		set atemt::_atemt(PATH) [atemt::atemt_subst -insert -block PATH_ENTRY PATH]
		fas_debug "path::generate_path_html - PATH -> $atemt::_atemt(PATH)"

	}
}
